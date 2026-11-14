---
paths:
  - "**/*.scala"
  - "**/*.java"
  - "**/*.ts"
  - "**/*.cue"
  - "**/*.sh"
  - "**/*.toml"
  - "**/*.yml"
  - "**/*.yaml"
  - "**/*.sql"
---

# Comment Tags — One Tag, One Meaning, Short

## When

You write or change a comment in code or config. This covers:

| Syntax | Files |
|---|---|
| `//` | Scala (`.scala`, `.sc`). No `/* */`, no `/** */` |
| `//`, `/* */`, `/** */` | Java, Kotlin, TS/JS, Go, Rust |
| `//` | CUE |
| `#` | Shell, Python, TOML, YAML, Dockerfile, Makefile |
| `--`, `/* */` | SQL |

Out of scope: trailing comments (`val x = 1 // ms`), tool directives (`//> using`,
`// format: off`, `# shellcheck disable=...`, `// @ts-ignore`), separator lines, Markdown.

## The rule

Each comment is ONE line and starts with one tag, followed by a colon.

| Tag | Meaning |
|---|---|
| `@what:` | What this code or unit does or is for. Never a restatement of the next line |
| `@why:` | A reason the code cannot show: a constraint, an incident, a trade-off, a workaround |
| `@invariant:` | A rule that must stay true, or something breaks |
| `@todo:` | Work not done yet, including a workaround to remove |
| `@ref:` | A reference: a `[[Symbol]]`, an `@/path` (file or folder), a `$> command` or a URL. A short note can follow it |
| `@generated:` | What a generated file is. Its block names the generator and the command that regenerates the file. See "Generated files" |

- **One comment = one line**, at most 150 columns. No continuation lines.
- **A tag can repeat.** Two reasons are two `@why:` lines.
- **Block:** every comment line between two code lines. Blank lines do not split a block.
- **300 characters per block**, tag words not counted. Detail beyond that goes to a doc, and the
  block keeps an `@ref:`.
- **No second label in the text.** A word followed by `: ` (for example `Not FINAL: ...`) is an
  error. Use a full stop. Code in backticks, `x://` URIs and `a:b` tokens are fine.
- **No counts.** A comment never states how many files, metrics, tests, fields, lines or entries
  exist ("holds 39 metrics", "45 tests"). The number is stale the day after, and it costs a measure to
  check. Co-generation exports it: point at the export with `@ref:`. A size or a unit is fine
  (`64 blocks`, `a 32-byte hash`). The hook flags a number before one of these nouns.
- **No other `@` tag.** No `@param`, `@return`, `@note`: the repo does not publish Scaladoc.
- **References resolve.** See the next section.

```scala
// @why: the engine writes StepStarted when it records a node, not when it starts it.
// @invariant: the time of a node is measured on the clock of the kernel, from the end of the previous node.
// @ref: @/tool/kernel/README.md
```

A workaround is a `@why:` plus a `@todo:`:

```cue
// @why: CUE evaluates both sides of `&&`, so the index is guarded.
// @todo: back to a plain `&&` once CUE short-circuits it.
```

## Generated files

A file that a tool writes starts with a `@generated:` block. It replaces `@what:` in that header.

```cue
// @generated: the text blocks of a captured web page. Do not edit.
// @ref: @/tool/kernel/WebCapture.scala
// @ref: $> cueverge capture check
package web
```

- The block holds one `@ref: @/path` to the generator and one `@ref: $> ` command that regenerates the file.
  The hook reports a `@generated:` block that misses either one.
- The generator writes this header. Fix a header in the generator, never in the generated file.
- When the leading comment block of a file holds `@generated:`, the hook lints only that header. Comments
  below it are not linted, because a fix belongs in the generator. References are still checked everywhere.
- Use `@generated:` only in the header of a generated file.

## References

`@ref:` is the reference tag. A block can hold several `@ref:` lines, and one line can hold several references.
An `@ref:` line holds at least one of four forms. The hook resolves each one.

| Form | Example | The hook checks |
|---|---|---|
| `[[Symbol]]` (Scala only) | `[[CueFlowStore]]`, `[[Agent.headless]]`, `[[ujson.Value]]` | a repo Scala definition has that name |
| `@/path` (file or folder) | `@/tool/cue/rules/seal.rules.cue`, `@/tool/cue/rules/seal.rules.cue:12`, `@/tool/cue/rules/` | the path exists from the content root |
| `$> command` | `$> mise run tool:publish` | the mise task exists, or a path command exists |
| URL | `https://example.org/issues/123` | nothing (any `scheme://`) |

**Symbols: `[[Name]]`, in any tag of a Scala file.**

- When the target is a Scala type, write `[[Type]]`, not `@/path/to/Type.scala`. It is shorter, and it survives
  a file or package move.
- The hook reads every `class`, `object`, `trait`, `enum`, `type`, `def`, `val`, `var`, `given` and `case` name
  in the tracked Scala files.
- The first segment that starts upper-case must be a definition: `[[Agent.headless]]` checks
  `Agent`. A member is not checked. Without an upper-case segment, the last segment must be a definition.
- A library type takes its full name, `[[ujson.Value]]`. A name that starts with a lower-case package
  other than `kernel` is not checked. A bare `[[Value]]` is an error, because the repo does not define it.
- Backticks hide the form, so `` `[[repos]]` `` stays a TOML table name.
- Only `.scala` and `.sc` files are checked. Other languages keep `@/path`.

**Files, folders and commands: only on an `@ref:` line.**

- In `@what:`, `@why:`, `@invariant:` and `@todo:`, an `@/path` is an error. Name the file in the prose,
  and put `@/path` on an `@ref:` line of the same block.
- Prose may name a file or a folder. The block must then hold an `@ref:` to that exact target. The hook finds
  a mention in any of these forms, in backticks too:

  | Form | Example | Target |
  |---|---|---|
  | path | `tool/cue/rules/seal.rules.cue` | `@/tool/cue/rules/seal.rules.cue` |
  | relative path | `./tool/cue/rules` | `@/tool/cue/rules` |
  | folder | `tool/cue/rules/` | `@/tool/cue/rules` |
  | leading slash (classpath) | `/application.conf` | the tracked file with that name |
  | bare file name | `comment-tags-autofix.sh` | the tracked file with that name |

  A path counts when its first segment is a top-level repo entry. A bare name counts when exactly one tracked
  file has it. A name that several files share cannot be resolved in prose, so the hook skips it there.
- The `@ref:` that backs a mention can sit on any line of the block, also a line that the change does not touch.
- On an `@ref:` line itself, a path without `@/` is an error, in every form above.
- Backticks still hide a glob (`tool/**/*.scala`), a made-up example (`a/x.pl`) and syntax (`@/path`).
- `@/` is the content root (the repo root). A path never starts from the file that holds the comment.
- A gitignored path is valid. The hook checks it when it exists locally. Without it (CI), it passes.

**Commands: `$> ` on an `@ref:` line only. URLs: any tag.**

- `$> ` marks a runnable command. It runs to the end of the line. A ` # note` after it is a note.
- In `@what:`, `@why:`, `@invariant:` and `@todo:`, a `$> ` command or a bare `mise run` is an error.
  Name the action in the prose, and put `$> mise run <task>` on an `@ref:` line.
- On an `@ref:` line, a bare `mise run` without `$> ` is an error.
- Backticks hide `$> `, so `` `$> mise run <task>` `` describes the syntax.
- A URL is fine in any tag. The hook never fetches it.
- `$> mise run` names one exact task. No glob (`changelog:*`): point at the doc that lists the tasks instead.
  Placeholders in arguments (`<slug>`) are fine.
- Task names come from `mise tasks`, so a task added in the same change passes.

```scala
// @what: the folder of a project that holds its CUE module, its knowledge and its journal.
// @ref: @/cueverge/cue.mod/module.cue
```

```scala
// @invariant: the scaffold creates a missing file, and only adds the missing lines to a few existing ones.
// @ref: [[Templates]]
```

```toml
# @what: builds the cueverge binary and links it into mise.
# @ref: @/tool/kernel/build.sh
# @ref: $> mise run build
```

## Block comments

**Scala (`.scala`, `.sc`): none.** The repo publishes no Scaladoc, so a Scala comment is a `//` line.
A line that starts with `/*` or `/**` is an error. An inline block comment inside code (`case 0 /* x */ =>`) is out of scope.

```scala
// @what: the CUE module of the project that holds dir.
// @invariant: from the root of a repository, its cueverge folder.
def root(dir: String): JPath
```

Other languages: `/* */` and `/** */` follow the same rule as `//`, one tagged line per comment.

## Enforcement

One script, `.agents/scripts/comment-tags-staged.sh`, runs as two prek hooks (`prek.toml`):

| Hook | Checks | On |
|---|---|---|
| `comment-tags` | every rule | the lines a change adds. Old comments pass until a line in them changes |
| `comment-refs` | references only | every tagged comment in the repo. A moved file or a removed task breaks a comment that no diff touches |

jj runs no git hook. Run `mise run lint` before `jj describe`: it runs prek on the files changed at `@`.
`mise run lint --all` runs every hook on every file. Without a staged index, the script diffs `HEAD` (= `@-`) against the working copy.

Before a commit, the script runs `comment-tags-autofix.sh`. It fixes only a too-long tagged line it can wrap, and an exact
missing `@ref:` the lint reports. `COMMENT_TAGS_AUTOFIX=0` turns it off.

```bash
mise run lint                                                                  # prek on the files changed at @
.agents/scripts/comment-tags-staged.sh path/to/file.cue                        # check added lines vs HEAD
COMMENT_TAGS_ALL=1 .agents/scripts/comment-tags-staged.sh path/to/file.cue     # check every comment
COMMENT_TAGS_REFS=1 .agents/scripts/comment-tags-staged.sh                     # references in every tagged comment
```

## Never

- Never write an untagged comment in new code.
- Never continue a comment on a second line. Split it into two tagged lines, or cut it.
- Never state a count (of files, metrics, tests, fields, lines, entries) in a comment. Co-generation
  exports it.
- Never stretch a block past 300 characters with dated numbers or a narrative. Move it to
  a doc and add `@ref:`.
- Never write a repo path without `@/`, or a command without `$> `. The hook cannot check them.
- Never point `@ref:` at a path or a task that does not exist. Fix the reference when you move the target.
- Never write `@/path/to/Type.scala` for a Scala type. Write `[[Type]]`.
