# Cueverge

A software factory made of agents, where every rule is CUE and every fact is proven.

The repository holds the tool and the knowledge of the factory about itself:

| Folder | Holds |
|---|---|
| `tool/cue/` | The CUE module of the tool, `github.com/cyrildesch/cueverge`: the rules of the judge and the seal, the kinds of rule, the shape of a fact, the frame of a project. A project imports it. |
| `tool/kernel/` | The `cueverge` CLI, in Scala with Kyo: `init`, `round`, `approve`, `site`, `upgrade`, `capture`… |
| `cueverge/` | The knowledge of the factory: experiments, principles, decisions, constraints, questions, actions, studies, and its portal. It is the first client of the tool, laid out as `cueverge init` lays out a project. |

## Check

```sh
cd cueverge && cue vet -c ./...
```

The command checks all the knowledge: each fact of `sealed/` against its source in `gen/`, by the rules of `cogen/`. There is no other check, and no exception. It needs CUE v0.18 (`mise.toml`). The lint (`mise run lint`) runs it too, with the check of the module of the tool.

## Build the tool

```sh
mise run tool:publish   # publishes tool/cue to the registry of CUE_REGISTRY
mise run build          # builds dist/cueverge/bin and links it into mise
```

## Build the portal

```sh
cueverge site build
```

Hugo 0.145.0 comes from mise (`mise.toml`). For a local preview: `cueverge site serve`.
