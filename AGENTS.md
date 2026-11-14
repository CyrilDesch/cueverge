# AGENTS.md

Instructions for every coding agent that works in this repository.

## What this repository is

cueverge is a software factory made of agents, where every rule is CUE and every fact is proven.

| Folder | Holds |
|---|---|
| `tool/cue/` | The CUE module of the tool, `github.com/cyrildesch/cueverge`: the rules of the judge and the seal, the kinds of rule, the shape of a fact, the frame of a project. Projects import it. |
| `tool/kernel/` | The `cueverge` CLI, in Scala 3 with Kyo. It runs, times and extracts. CUE decides. |
| `cueverge/` | The knowledge of the factory: experiments, principles, decisions, constraints, questions, actions, studies, and its portal. It is the first client of the tool, laid out as `cueverge init` lays out any project. |

## Check your work

```sh
mise run lint                     # every hook on the files changed at @, cue vet included
cd cueverge && cue vet -c ./...   # the knowledge of the factory
cd tool/cue && cue vet -c ./...   # the CUE module of the tool
mise run build                    # the CLI, into dist/cueverge/bin
```

`cue vet` is the only check of the knowledge. There is no exception list. The lint also gives it the list of every cue file (`-t tracked`), so the layout rule sees a package at any depth.

## Rules

- **Comments**: one tagged line each (`@what:`, `@why:`, `@invariant:`, `@todo:`, `@ref:`, `@generated:`), with references that resolve. Read [`.agents/rules/comment-tags.md`](.agents/rules/comment-tags.md) before you write a comment.
- **Judgement lives in CUE.** The kernel never holds a rule. A verdict, a budget or a no-regression check is a CUE rule.
- **Facts**: a fact in `cueverge/sealed/` has its rule at the same path under `cueverge/cogen/gen-sealed/`. Only a mechanism of the kernel writes `cueverge/gen/`.
- **People decide loosening.** Adding a rule or a fact is free. Modifying or deleting a rule, or retiring a fact, needs a person. A retired fact keeps a tombstone.
- **Generated files** start with a `@generated:` header. Fix the generator, never the generated file.
- **Version control** is jj. Commits follow Conventional Commits, in English, with a body. Run `mise run lint` before `jj describe`.
