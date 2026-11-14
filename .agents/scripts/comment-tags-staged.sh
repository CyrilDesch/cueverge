#!/usr/bin/env bash
# @what: lints comments. One line each, tagged @what: @why: @invariant: @todo: @ref: @generated:, 300 chars per block. Resolves references.
# @why: only ADDED lines are checked. COMMENT_TAGS_REFS=1 checks references in every tagged comment, to catch drift.
# @ref: @/.agents/rules/comment-tags.md
set -uo pipefail

root=$(git rev-parse --show-toplevel)
refs=${COMMENT_TAGS_REFS:-0}
# @invariant: strict by default after the repository-wide reference and tooling checks reached zero problems.
max=${COMMENT_TAGS_MAX_ERRORS:-0}
# @invariant: same file set as the comment-tags hook in prek.toml.
# @ref: @/prek.toml
if [[ $refs == 1 && $# -eq 0 ]]; then
  cd "$root" || exit 1
  files=()
  while IFS= read -r f; do files+=("$f"); done < <(git ls-files |
    grep -E '\.(scala|sc|mill|java|kt|ts|tsx|js|mjs|go|rs|cue|sh|bash|zsh|py|toml|ya?ml|sql)$|(^|/)(Dockerfile|Makefile)' |
    grep -vE '^examples/[^/]+/(cases|journal)/')
  set -- "${files[@]}"
  # @why: a bad reference on main must not fail every PR. With a diff range, only the changed files fail. The rest warn.
  if [[ -n ${PRE_COMMIT_FROM_REF:-} && -n ${PRE_COMMIT_TO_REF:-} ]] &&
    scope=$(git diff --name-only --no-renames "$PRE_COMMIT_FROM_REF...$PRE_COMMIT_TO_REF"); then
    scoped=1
  fi
fi
[[ $# -eq 0 ]] && exit 0
# @why: auto-fix receives the linter's exact findings and only revisits changed comment blocks.
if [[ $refs != 1 && ${COMMENT_TAGS_AUTOFIX:-1} == 1 && ${COMMENT_TAGS_AUTOFIX_RUNNING:-0} != 1 ]]; then
  COMMENT_TAGS_AUTOFIX_RUNNING=1 python3 "$root/.agents/scripts/comment-tags-autofix.py" "$@"
fi
tasks=$(command -v mise >/dev/null && (cd "$root" && mise tasks --no-header 2>/dev/null | awk '{ print $1 }') | sort -u | tr '\n' ' ')
# @why: only tracked top-level entries. An ignored folder on disk (Mill `out/`, `.bsp/`) made the result depend on the local build.
roots=$(cd "$root" && git ls-files | cut -d/ -f1 | sort -u | tr '\n' ' ')

# @why: prek sets PRE_COMMIT_*_REF in CI, else the git index (git commit), else HEAD (jj @- vs @).
# @why: COMMENT_TAGS_ALL=1 diffs from the empty tree, so every comment in the files is checked.
from=${PRE_COMMIT_FROM_REF:-}
to=${PRE_COMMIT_TO_REF:-}
if [[ ${COMMENT_TAGS_ALL:-} == 1 || $refs == 1 ]]; then
  range=(4b825dc642cb6eb9a060e54bf8d69288fbee4904)
elif [[ -n $from && -n $to ]]; then
  range=("$from...$to")
elif ! git diff --cached --quiet -- "$@"; then
  range=(--cached)
else
  range=(HEAD)
fi

git diff -U0 --no-color --no-ext-diff "${range[@]}" -- "$@" |
  SCOPE="${scope:-}" awk -v ROOT="$root" -v ROOTS="$roots" -v TASKS="$tasks" -v REFS="$refs" -v MAX="$max" -v Q="'" -v SCOPED="${scoped:-0}" '
  BEGIN {
    BLOCK = 300; WIDTH = 150
    tagre = "^@(what|why|invariant|todo|ref|generated):( |$)"
    tags = "@what: @why: @invariant: @todo: @ref: or @generated:"
    errors = 0; warned = 0
    # @why: the file list comes from the environment, as BSD awk rejects a newline in a -v value.
    n = split(ENVIRON["SCOPE"], sc, "\n"); for (i = 1; i <= n; i++) inscope[sc[i]] = 1
    n = split(ROOTS, r, " "); for (i = 1; i <= n; i++) if (r[i] != ".git") isroot[r[i]] = 1
    isroot[".polaris"] = 1
    ntasks = split(TASKS, tl, " "); for (i = 1; i <= ntasks; i++) task[tl[i]] = 1
    REF = "@/[^ \t`\"(),;]*"; SEP = "[ \t`" Q "\"(),;]+"
    # @why: a bare file name (`foo.pl`) has no slash, so it is found by its base name among tracked files.
    ls = "cd " Q ROOT Q " && git ls-files"
    while ((ls | getline f) > 0) { b = f; sub(/.*\//, "", b); nbase[b]++; if (!(b in base)) base[b] = f }
    close(ls)
    # @why: only tracked ignore files may make a missing reference pass. Local excludes would otherwise make hook results machine-dependent.
    ig = "cd " Q ROOT Q " && git ls-files -- .gitignore \":(glob)**/.gitignore\""
    while ((ig | getline f) > 0) tracked_ignore[f] = 1
    close(ig)
    # @what: every name a Scala file defines, so a `[[Symbol]]` reference resolves.
    defs = "cd " Q ROOT Q " && git grep -hoE " Q "(class|object|trait|enum|type|def|val|var|given) +[A-Za-z_][A-Za-z0-9_]*" Q " -- " Q "*.scala" Q " " Q "*.sc" Q " " Q "*.mill" Q
    while ((defs | getline f) > 0) { sub(/.*[ ]/, "", f); sym[f] = 1 }
    close(defs)
    # @why: an enum case is a definition too, and one `case A, B` line holds several.
    defs = "cd " Q ROOT Q " && git grep -hoE " Q "case +[A-Z][A-Za-z0-9_]*( *, *[A-Z][A-Za-z0-9_]*)*" Q " -- " Q "*.scala" Q " " Q "*.sc" Q " " Q "*.mill" Q
    while ((defs | getline f) > 0) { sub(/^case +/, "", f); n = split(f, cs, / *, */); for (i = 1; i <= n; i++) sym[cs[i]] = 1 }
    close(defs)
  }
  # @what: a problem in a file outside the diff scope is a warning, as a GitHub annotation in Actions.
  function report(line, msg) {
    if (SCOPED && !(file in inscope)) {
      warned++; gsub(/%/, "%25", msg)
      if (ENVIRON["GITHUB_ACTIONS"] == "true") printf "::warning file=%s,line=%d::%s\n", file, line, msg
      else printf "warning: %s:%d: %s\n", file, line, msg
      return
    }
    printf "%s:%d: %s\n", file, line, msg; errors++
  }
  # @what: a style problem (tag, width, block, label). The references-only mode skips it.
  # @why: a generated file is fixed in its generator, so only its header is linted. References are still checked.
  function lint(line, msg) { if (REFS != 1 && !(genhdr && line > genhdr)) report(line, msg) }

  # @what: sets genhdr to the last line of the leading comment block when that block holds a @generated: line, else 0.
  function gen_header(path,   f, l, n, t, found) {
    genhdr = 0; found = 0; n = 0
    if (lc == "") return
    f = ROOT "/" path
    while ((getline l < f) > 0) {
      n++; t = l; sub(/^[ \t]+/, "", t)
      if (t == "") continue
      if (substr(t, 1, length(lc)) != lc) break
      if (index(t, lc " @generated:") == 1) found = 1
      genhdr = n
    }
    close(f)
    if (!found) genhdr = 0
  }

  # @invariant: lc is the line-comment prefix for the file type. bc = 1 when it has /* */ blocks. nb = 1 when they are banned.
  function set_style(path,   base) {
    base = path; sub(/.*\//, "", base)
    lc = ""; bc = 0; nb = base ~ /\.(scala|sc|mill)$/; isscala = nb
    if (base ~ /\.(scala|sc|mill|java|kt|ts|tsx|js|mjs|go|rs)$/) { lc = "//"; bc = 1 }
    else if (base ~ /\.cue$/) lc = "//"
    else if (base ~ /\.(sh|bash|zsh|py|toml|ya?ml)$/ || base ~ /^(Dockerfile|Makefile)/) lc = "#"
    else if (base ~ /\.sql$/) { lc = "--"; bc = 1 }
  }

  # @what: a block is every comment line between two code lines. Blank lines do not split it.
  function end_block() {
    if (nlines > 0 && chars > BLOCK)
      lint(start, sprintf("block has %d chars, limit is %d. Cut it, or move detail to a doc and add @ref:.", chars, BLOCK))
    nlines = 0; chars = 0
  }
  function reset() { end_block(); inblk = 0 }

  # @why: tool directives and separators are not prose, so they are never checked.
  function ignored(body) {
    return body ~ /^(format:|scalafix:|scalafmt:|noinspection|nowarn|scalastyle|\$COVERAGE|shellcheck|eslint-|prettier-ignore|biome-ignore|deno-lint-ignore|deno-fmt-ignore|@ts-|nolint|noqa|type:|pragma|yaml-language-server|language=|-{3}|={3}|─{3}|#+$|\*+$)/
  }

  # @why: a word followed by ": " reads as a second label. Code in backticks, x:// and a:b are fine.
  function has_label(s) {
    gsub(/`[^`]*`/, "", s); gsub(/[A-Za-z][A-Za-z0-9+.-]*:\/\/[^ ]*/, "", s)
    return s ~ /(^|[ (])[A-Za-z][A-Za-z0-9_.-]*:( |$)/
  }

  # @why: a count of files, metrics, tests, entries, fields or lines is stale the day after. Co-generation exports it.
  function has_count(s) {
    gsub(/`[^`]*`/, "", s)
    return s ~ /(^|[^0-9A-Za-z_.#-])[0-9][0-9,_]* ([^ ]+ )?([^ ]+ )?(files?|metrics?|tests?|entries|fields?|lines?|instruments?|series)([^A-Za-z]|$)/
  }

  # @why: .polaris/ is a gitignored FUSE mount. Without the mount (CI) a path in it cannot be checked, so it passes.
  # @ref: @/.polaris/
  function exists(p,   check, output, source, pattern) {
    if (p ~ /\047/) return 0
    if (p ~ /^\.polaris(\/|$)/ && system("test -d " Q ROOT "/.polaris" Q) != 0) return 1
    # @why: tracked .gitignore makes ignored refs resolve alike locally and in CI; untracked and local excludes must not affect results.
    # @ref: @/.gitignore
    if (!(p in seen)) {
      seen[p] = system("test -e " Q ROOT "/" p Q) == 0
      if (!seen[p]) {
        check = "cd " Q ROOT Q " && git check-ignore -v --no-index -- " Q p Q
        if ((check | getline output) > 0) {
          source = output; sub(/:.*/, "", source)
          pattern = output; sub(/^[^:]*:[0-9]+:/, "", pattern); sub(/\t.*/, "", pattern)
          if (source in tracked_ignore && pattern !~ /^!/) seen[p] = 1
        }
        close(check)
      }
    }
    return seen[p]
  }

  # @invariant: `$> mise run <task>` names one task that exists. A path command (x/y.sh) exists.
  function check_cmd(cmd,   w, nw, p) {
    gsub(/`/, "", cmd); sub(/ # .*/, "", cmd)
    nw = split(cmd, w, " ")
    if (nw == 0) { report(ln, "$> needs a command after it."); return }
    if (w[1] ~ /\047/) { report(ln, "command " w[1] " does not exist."); return }
    if (w[1] == "mise" && w[2] == "run") {
      if (w[3] !~ /^[A-Za-z0-9_.-]+(:[A-Za-z0-9_.-]+)*$/)
        report(ln, "$> mise run needs one exact task name, not \"" w[3] "\". Name the task, or @ref: its doc.")
      else if (ntasks > 0 && !(w[3] in task))
        report(ln, "mise task " w[3] " does not exist. Check `mise tasks`.")
    } else if (w[1] == "mise") {
      report(ln, "$> mise needs the run verb: $> mise run <task>.")
    } else if (w[1] ~ /\//) {
      p = w[1]; sub(/^\.\//, "", p)
      if (p ~ /\047/ || !exists(p)) report(ln, "command " w[1] " does not exist.")
    }
  }

  # @what: sets KIND (path, name or empty) and NP for one word that may name a tracked file or folder.
  # @why: a slash marks a path (a/x, ./a, a/, /x). Without one, only a tracked file name counts.
  function classify(w,   p, first) {
    KIND = ""; NP = ""
    if (w ~ /[*?<>{}$]/ || w ~ /\[/) return
    p = w; sub(/[.,:;]+$/, "", p)
    marked = p ~ /\//
    sub(/^\.\//, "", p); sub(/^\//, "", p); sub(/\/+$/, "", p)
    if (p == "") return
    first = p; sub(/\/.*/, "", first)
    if (marked && first in isroot) { KIND = "path"; NP = p }
    else if (p !~ /\// && p ~ /\.[A-Za-z0-9]+$/ && p in nbase) { KIND = "name"; NP = p }
  }

  # @what: the same text with every character inside backticks turned into `_`, so positions still line up.
  function mask_code(s,   out, span) {
    out = ""
    while (match(s, /`[^`]*`/)) {
      span = substr(s, RSTART, RLENGTH); gsub(/[^`]/, "_", span)
      out = out substr(s, 1, RSTART - 1) span; s = substr(s, RSTART + RLENGTH)
    }
    return out s
  }

  # @what: 1 when `[[a.b.C.m]]` resolves. The first upper-case segment must be defined, else the last segment.
  # @why: only the owner is checked, as its rename is the drift that matters. A member is not.
  # @why: a library name (`io.circe.Json`) starts with a package outside `kernel`, so it passes.
  function sym_ok(name,   seg, n, i) {
    n = split(name, seg, /[.#]/)
    if (n > 1 && seg[1] ~ /^[a-z]/ && seg[1] != "kernel") return 1
    for (i = 1; i <= n; i++) if (seg[i] ~ /^[A-Z]/) return seg[i] in sym
    return seg[n] in sym
  }

  function norm_ref(r) {
    sub(/[.,:;]+$/, "", r); sub(/:[0-9]+(-[0-9]+)?$/, "", r); sub(/#.*$/, "", r); sub(/\/+$/, "", r)
    return r
  }

  # @what: 2 for a blank line, 1 for a comment line, 0 for code. Blank lines do not split a block.
  function raw_kind(l,   t) {
    t = l; sub(/^[ \t]+/, "", t)
    if (t == "") return 2
    if (substr(t, 1, length(lc)) == lc) return 1
    if (bc && (substr(t, 1, 1) == "*" || substr(t, 1, 2) == "/*")) return 1
    return 0
  }

  # @why: the @ref: that backs a mention may sit on a line the diff does not touch, so the whole block is read from the file.
  function block_sees(line,   f, n, l, i, a, b, refs, rest, body, masked, ended) {
    f = ROOT "/" file
    if (!(file in loaded)) {
      n = 0; while ((getline l < f) > 0) src[file, ++n] = l
      close(f); loaded[file] = n
    }
    n = loaded[file]
    for (a = line; a > 1 && raw_kind(src[file, a - 1]); a--) ;
    for (b = line; b < n && raw_kind(src[file, b + 1]); b++) ;
    refs = " "
    BLOCKCMD = 0
    for (i = a; i <= b; i++) {
      body = src[file, i]; sub(/^[ \t]+/, "", body)
      ended = 0
      if (substr(body, 1, length(lc)) == lc) {
        body = substr(body, length(lc) + 1); sub(/^ /, "", body)
      } else if (bc && substr(body, 1, 2) == "/*") {
        body = substr(body, substr(body, 1, 3) == "/**" ? 4 : 3); sub(/^ /, "", body); ended = index(body, "*/")
      } else if (bc && substr(body, 1, 1) == "*") {
        body = substr(body, 2); sub(/^ /, "", body); ended = index(body, "*/")
      } else continue
      # @why: as in block_text, block text ends at */, so `@/path*/` names the path alone.
      if (ended) body = substr(body, 1, ended - 1)
      masked = mask_code(body)
      if (masked !~ /^@ref:( |$)/) continue
      if (index(masked, "$> ")) BLOCKCMD = 1
      rest = masked
      while (match(rest, REF)) { refs = refs norm_ref(substr(rest, RSTART + 2, RLENGTH - 2)) " "; rest = substr(rest, RSTART + RLENGTH) }
    }
    return refs
  }

  function backed(refs,   r, nr, i, b) {
    if (KIND == "path") return index(refs, " " NP " ") > 0
    nr = split(refs, r, " ")
    for (i = 1; i <= nr; i++) { b = r[i]; sub(/.*\//, "", b); if (b == NP) return 1 }
    return 0
  }

  # @what: checks the references in one comment text. Returns the text without them, for has_label.
  # @invariant: an `@/path` sits on an @ref: line and exists. Prose names a file or folder, and its block backs it with an @ref:.
  # @why: files, folders and `$>` commands live on @ref: lines only. URLs are fine in any tag.
  function check_refs(tag, s,   cmd, t, p, rest, nt, i, found, nb, refs) {
    found = 0
    if (match(mask_code(s), /\$> /)) {
      cmd = substr(s, RSTART + 3); s = substr(s, 1, RSTART - 1); found = 1
      if (tag == "@ref:") check_cmd(cmd)
      else report(ln, "$> commands belong on an @ref: line. Name the action in the prose.")
    }
    nb = s; gsub(/`[^`]*`/, "", nb)
    if (nb ~ /(^|[^A-Za-z0-9_])mise run /) {
      found = 1
      if (tag == "@ref:") report(ln, "a runnable command starts with \"$> \", for example $> mise run <task>.")
      else report(ln, "a command belongs on an @ref: line, as @ref: $> mise run <task>.")
    }
    if (gsub(/[A-Za-z][A-Za-z0-9+.-]*:\/\/[^ `]*/, "", s)) found = 1
    nb = s; gsub(/`[^`]*`/, "", nb)
    # @invariant: in Scala, a `[[Symbol]]` outside backticks names a definition that exists. Any tag may hold one.
    if (isscala) {
      rest = nb
      while (match(rest, /\[\[[A-Za-z0-9_.#]+\]\]/)) {
        p = substr(rest, RSTART + 2, RLENGTH - 4); rest = substr(rest, RSTART + RLENGTH); found = 1
        if (!sym_ok(p)) report(ln, "[[" p "]] names no Scala definition in the repo. Fix the name, or give a library type its full name.")
      }
      gsub(/\[\[[A-Za-z0-9_.#]+\]\]/, "", s); gsub(/\[\[[A-Za-z0-9_.#]+\]\]/, "", nb)
    }
    rest = nb
    while (match(rest, REF)) {
      p = substr(rest, RSTART + 2, RLENGTH - 2); rest = substr(rest, RSTART + RLENGTH); found = 1
      if (tag != "@ref:") { sub(/[.,:;]+$/, "", p); report(ln, "@/" p " belongs on an @ref: line. Name the file in the prose."); continue }
      p = norm_ref(p)
      if (p == "" || !exists(p)) report(ln, "@/" p " does not exist. Paths start at the content root.")
    }
    gsub(REF, "", s)
    nt = split(s, t, SEP)
    for (i = 1; i <= nt; i++) {
      classify(t[i])
      if (KIND == "") continue
      if (tag == "@ref:") {
        found = 1
        if (KIND == "path") report(ln, "repo path " NP " needs the content-root prefix: @/" NP)
        else if (nbase[NP] == 1) report(ln, "file " NP " needs its content-root path: @/" base[NP])
        else report(ln, "file " NP " names " nbase[NP] " tracked files. Write the full @/ path.")
      } else if ((KIND == "path" || nbase[NP] == 1) && !((file, ln, NP) in told)) {
        told[file, ln, NP] = 1
        if (refs == "") refs = block_sees(ln)
        if (!backed(refs)) report(ln, "mentions " NP ". Add @ref: @/" (KIND == "path" ? NP : base[NP]) " to this block.")
      }
    }
    if (tag == "@ref:" && !found) report(ln, "@ref: needs a URL, an @/repo/path, a [[Symbol]] or a $> command.")
    # @invariant: a @generated: block names its generator and the command that regenerates the file.
    if (tag == "@generated:") {
      refs = block_sees(ln)
      if (refs !~ /[^ ]/ || !BLOCKCMD) report(ln, "@generated: needs @ref: @/<generator> and @ref: $> <command> in its block.")
    }
    return s
  }

  # @invariant: every comment line is one whole comment and starts with a tag.
  function text_line(body, width,   word, tag) {
    if (body == "" || ignored(body)) return
    if (nlines == 0) start = ln
    nlines++
    if (match(body, tagre)) {
      tag = substr(body, 1, RLENGTH); sub(/ $/, "", tag)
      body = substr(body, RLENGTH + 1)
      if (width > WIDTH) lint(ln, sprintf("line has %d columns, limit is %d. One comment = one line.", width, WIDTH))
      if (has_label(check_refs(tag, body))) lint(ln, "a word followed by \": \" reads as a second label. Use a full stop, or backticks for code.")
      if (has_count(body)) lint(ln, "a comment never states a count (files, metrics, tests, entries, fields, lines). Co-generation exports it.")
    } else if (body ~ /^@[A-Za-z]+/) {
      word = substr(body, 1, index(body " ", " ") - 1)
      if (word ~ /^@(what|why|invariant|todo|ref|generated)$/) lint(ln, word " needs a colon: " word ":")
      else lint(ln, "tag " word " is not allowed. Use " tags ".")
      return
    } else {
      lint(ln, "every comment line starts with a tag (" tags "). One comment = one line.")
    }
    chars += length(body)
  }

  # @why: strip */, the leading * and spaces, so block text reads like line text.
  function block_text(s, width,   ended) {
    ended = index(s, "*/")
    if (ended) s = substr(s, 1, ended - 1)
    sub(/^[ \t]*\*?[ \t]?/, "", s); sub(/[ \t]+$/, "", s)
    text_line(s, width)
    if (ended) inblk = 0
  }

  /^\+\+\+ / { reset(); file = substr($0, 7); set_style(file); gen_header(file); next }
  /^@@/ {
    reset()
    match($0, /\+[0-9]+/); ln = substr($0, RSTART + 1, RLENGTH - 1) + 0
    next
  }
  /^\+/ {
    raw = substr($0, 2); w = length(raw)
    text = raw; sub(/^[ \t]+/, "", text)
    if (lc == "") { ln++; next }
    if (inblk) { block_text(text, w); ln++; next }
    if (bc && substr(text, 1, 2) == "/*" && substr(text, 1, 4) != "/**/") {
      inblk = 1
      if (nb) lint(ln, "block comment. Write one // line per comment, the repo publishes no Scaladoc. scalafix NoBlockComment rewrites it.")
      block_text(substr(text, substr(text, 1, 3) == "/**" ? 4 : 3), w)
      ln++; next
    }
    n = length(lc)
    if (substr(text, 1, n) == lc && (length(text) == n || substr(text, n + 1, 1) == " ")) {
      body = substr(text, n + 1); sub(/^ /, "", body); sub(/[ \t]+$/, "", body)
      text_line(body, w)
    } else if (text != "") {
      end_block()
    }
    ln++; next
  }
  { next }
  END {
    end_block()
    if (warned > 0)
      print "comment-tags: warning: " warned " problem(s) in files this change does not touch. Fix them in a separate change."
    if (errors > MAX + 0) {
      print "comment-tags: " errors " problem(s). Convention: .agents/rules/comment-tags.md"
      exit 1
    }
    if (errors > 0)
      print "comment-tags: warning: " errors " problem(s), at most " MAX " pass. Convention: .agents/rules/comment-tags.md"
  }
'
