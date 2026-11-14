# Cueverge

Une usine logicielle faite d'agents, dont chaque règle est en CUE et chaque fait est prouvé.

Le dépôt contient l'outil et le savoir de l'usine sur elle-même :

| Dossier | Contenu |
|---|---|
| `tool/cue/` | Le module CUE de l'outil, `github.com/cyrildesch/cueverge` : les règles du juge et du sceau, les sortes de règle, la forme d'un fait, le cadre d'un projet. Un projet l'importe. |
| `tool/kernel/` | Le CLI `cueverge`, en Scala avec Kyo : `init`, `round`, `approve`, `site`, `upgrade`, `capture`… |
| `cueverge/` | Le savoir de l'usine : expériences, principes, décisions, contraintes, questions, actions, études, et son portail. C'est le premier client de l'outil, rangé comme `cueverge init` range un projet. |

## Vérifier

```sh
cd cueverge && cue vet -c ./...
```

La commande vérifie tout le savoir : chaque fait de `sealed/` contre sa source dans `gen/`, par les règles de `cogen/`. Il n'y a pas d'autre contrôle, ni d'exception. Il faut CUE v0.18 (`mise.toml`). Le lint (`mise run lint`) la lance aussi, avec la vérification du module de l'outil.

## Construire l'outil

```sh
mise run tool:publish   # publie tool/cue au registre de CUE_REGISTRY
mise run build          # construit dist/cueverge/bin et le lie dans mise
```

## Construire le portail

```sh
cueverge site build
```

Hugo 0.145.0 vient de mise (`mise.toml`). Pour un aperçu local : `cueverge site serve`.
