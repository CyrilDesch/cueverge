#!/usr/bin/env python3
# @what: fixes only wrap-safe tagged comment width failures and exact missing @ref: additions reported by comment-tags-staged.sh.
# @why: source and line candidates come from the staged-comment linter, so a full prek run never rewrites unrelated comment blocks.
# @ref: @/.agents/scripts/comment-tags-staged.sh
import os
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

WIDTH = 150
BLOCK = 300
STYLES = [
    (re.compile(r'\.(scala|sc|mill|java|kt|ts|tsx|js|mjs|go|rs|cue)$'), '//'),
    (re.compile(r'(\.(sh|bash|zsh|py|toml|ya?ml)$)|(^|/)(Dockerfile|Makefile)'), '#'),
    (re.compile(r'\.sql$'), '--'),
]
MENTION = re.compile(r'^(.*):(\d+): mentions .+\. Add (@ref: @/[^ ]+) to this block\.$')
WIDTH_ERROR = re.compile(r'^(.*):(\d+): line has \d+ columns, limit is 150\.')
TAG = re.compile(r'^@(what|why|invariant|todo|ref|generated):(?: |$)')


def root() -> Path:
    return Path(subprocess.check_output(['git', 'rev-parse', '--show-toplevel'], text=True).strip())


def prefix(path):
    return next((value for pattern, value in STYLES if pattern.search(path)), None)


def lint(root_path, files):
    command = [str(root_path / '.agents/scripts/comment-tags-staged.sh'), *files]
    completed = subprocess.run(command, cwd=root_path, text=True, capture_output=True)
    return completed.stdout.splitlines()


def changed_lines(root_path, files):
    if os.environ.get('COMMENT_TAGS_AUTOFIX_ALL') == '1':
        return {name: None for name in files}
    before, after = os.environ.get('PRE_COMMIT_FROM_REF'), os.environ.get('PRE_COMMIT_TO_REF')
    if before and after:
        args = [f'{before}...{after}']
    elif subprocess.run(['git', 'diff', '--cached', '--quiet', '--', *files], cwd=root_path).returncode:
        args = ['--cached']
    else:
        args = ['HEAD']
    diff = subprocess.check_output(['git', 'diff', '-U0', '--no-color', '--no-ext-diff', *args, '--', *files], cwd=root_path, text=True)
    found, current, line = defaultdict(set), None, 0
    for raw in diff.splitlines():
        if raw.startswith('+++ b/'):
            current = raw[6:]
        elif raw.startswith('@@'):
            match = re.search(r'\+(\d+)', raw)
            line = int(match.group(1)) if match else 0
        elif raw.startswith('+') and not raw.startswith('+++'):
            if current:
                found[current].add(line)
            line += 1
        elif not raw.startswith('-'):
            line += 1
    return found


def is_comment(line, marker):
    stripped = line.lstrip(' \t')
    return stripped == marker or stripped.startswith(marker + ' ')


def block_at(lines, index, marker):
    start = index
    while start > 0 and (not lines[start - 1].strip() or is_comment(lines[start - 1], marker)):
        start -= 1
    end = index
    while end + 1 < len(lines) and (not lines[end + 1].strip() or is_comment(lines[end + 1], marker)):
        end += 1
    return start, end


def body(line, marker):
    text = line.lstrip(' \t')
    text = text[len(marker):]
    return text[1:] if text.startswith(' ') else text


def has_second_label(text):
    masked = re.sub(r'`[^`]*`', '', text)
    masked = re.sub(r'[A-Za-z][A-Za-z0-9+.-]*://[^ ]*', '', masked)
    return bool(re.search(r'(^|[ (])[A-Za-z][A-Za-z0-9_.-]*:( |$)', masked))


def block_chars(lines, start, end, marker):
    return sum(len(body(line, marker)) for line in lines[start:end + 1] if is_comment(line, marker))


def wrap(line, marker):
    indent = line[:len(line) - len(line.lstrip(' \t'))]
    comment = body(line, marker)
    match = TAG.match(comment)
    if not match:
        return None
    tag = match.group(0).rstrip()
    prose = comment[len(match.group(0)):]
    if '$> ' in prose:
        return None
    first = f'{indent}{marker} {tag} '
    available = WIDTH - len(first)
    words = prose.split()
    if available < 1 or any(len(word) > available for word in words):
        return None
    wrapped, line_words, count = [], [], 0
    for word in words:
        next_count = count + (1 if line_words else 0) + len(word)
        if line_words and next_count > available:
            wrapped.append(first + ' '.join(line_words))
            line_words, count = [word], len(word)
        else:
            line_words.append(word)
            count = next_count
    if line_words:
        wrapped.append(first + ' '.join(line_words))
    return wrapped if len(wrapped) > 1 else None


def main(files):
    root_path = root()
    files = [Path(os.path.relpath(Path(name).resolve(), root_path)).as_posix() for name in files]
    usable = [name for name in files if prefix(name)]
    if not usable:
        return 0
    snapshots = {name: (root_path / name).read_text() for name in usable}
    additions, widths = defaultdict(list), defaultdict(list)
    for output in lint(root_path, usable):
        mention = MENTION.match(output)
        if mention:
            additions[mention.group(1)].append((int(mention.group(2)) - 1, mention.group(3)))
        width = WIDTH_ERROR.match(output)
        if width:
            widths[width.group(1)].append(int(width.group(2)) - 1)
    changed = changed_lines(root_path, usable)
    for name in set(additions) | set(widths):
        permitted = changed.get(name)
        if permitted is None and name not in changed:
            continue
        path, marker = root_path / name, prefix(name)
        if path.read_text() != snapshots[name]:
            continue
        lines = snapshots[name].splitlines(keepends=True)
        header_end = next((i for i, line in enumerate(lines) if line.strip() and not line.lstrip(' \t').startswith(marker)), len(lines))
        if any(line.lstrip(' \t').startswith(f'{marker} @generated:') for line in lines[:header_end]):
            continue
        candidates = set(widths[name]) | {line for line, _ in additions[name]}
        blocks = {block_at(lines, line, marker) for line in candidates if 0 <= line < len(lines) and is_comment(lines[line], marker)}
        for start, end in sorted(blocks, reverse=True):
            comment_lines = [line for line in range(start, end + 1) if is_comment(lines[line], marker)]
            if not comment_lines or (permitted is not None and not any(line + 1 in permitted for line in comment_lines)):
                continue
            if block_chars(lines, start, end, marker) > BLOCK or any(has_second_label(body(lines[line], marker)) for line in comment_lines):
                continue
            references = [ref for line, ref in additions[name] if start <= line <= end]
            extra = sum(len(ref) for ref in dict.fromkeys(references))
            if block_chars(lines, start, end, marker) + extra > BLOCK:
                continue
            insertion = end + 1
            for reference in dict.fromkeys(references):
                source = lines[comment_lines[-1]]
                indent = source[:len(source) - len(source.lstrip(' \t'))]
                lines.insert(insertion, f'{indent}{marker} {reference}\n')
                insertion += 1
            for line in sorted([line for line in widths[name] if start <= line <= end], reverse=True):
                replacement = wrap(lines[line], marker)
                if replacement:
                    lines[line:line + 1] = [value + '\n' for value in replacement]
        path.write_text(''.join(lines))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
