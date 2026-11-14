# Kernel

The kernel runs one round of an initiative. **CUE decides, Scala acts.**
The orchestration is Scala 3 with Kyo. Values are read and written with Polaris
(`cue-extended`); `cue vet` decides.

```
          Scala + Kyo (effects)                    CUE (decisions)
   ┌─────────────────────────────────┐     ┌──────────────────────────────────┐
   │ Run       start, wait, time     │     │ factory/rules      the shapes     │
   │ Extract   forget, keep hashes   │ ──▶ │ rules/judge       answer→verdict │
   │ Tools     Polaris + cue vet     │     │ rules/round       verdicts, view │
   │ Main      the round as a Flow   │ ◀── │ rules/seal        no regression  │
   └─────────────────────────────────┘     └──────────────────────────────────┘
```

## A round

A round is a Kyo `Flow` (`Main.round`). Every named node is recorded before the
next one starts; the decisions are a function of what was recorded. Generated
with `cueverge diagram`:

```mermaid
graph LR
    n1[initiative]
    n2[cases]
    n4[[observe [x8]]]
    n6{{retime}}
    n9[decision]
    n11[seal]
    n1 --> n2
    n2 --> n4
    n6 --> n6
    n4 --> n6
    n6 --> n9
    n9 --> n11
```

| Node | Who | What |
|---|---|---|
| `initiative` | `Tools` | Reads `initiative.cue` with `cue-extended render`. |
| `cases` | `Main` | The cases of the round, in path order. |
| `observe` | `Run` | `foreach`, 8 at a time: oracle (cached) and candidate. One record per case. |
| `retime` | `Extract`, `Tools`, `rules/` | `loop`: writes `observed.gen.cue` (`cue-extended patch set`), reads the verdicts (`render`), times the late cases again, one at a time, as many times as the initiative allows. |
| `intent` | `rules/intent.rules.cue` | Reads `round.intent`: does the round hold the declared intent (`none`, `malformed`, `outside`, `awaiting`, `held`), and who approved it. |
| `decision` | `rules/seal.rules.cue`, `check/` | `cue vet -c ./<initiative>/check`: `observations & rules & seal` = ⊥ means the round is refused. |
| `seal` | `Tools` | The round holds: `cue-extended patch set` writes its verdicts to `sealed.gen.cue`. |

The store is in memory for now (`Flow.runLocal`): a round is recorded while it
runs, not after.

## Modules

| Module | Language | Role | Can it loosen a rule? |
|---|---|---|---|
| `factory/rules/*.rules.cue` | CUE | Every decision: verdicts, time budget, no regression. Named `*.rules.cue` so that `polaris projdiff` compares them. | **Yes.** Each edit is reviewed by a person. |
| `Extract.scala` | Scala | What is kept of an answer. | **Yes.** A coarser extractor loosens without touching the rules. |
| `Run.scala` | Scala + Kyo | Start a command (`kyo.Command`), time it (`Clock`), cache the oracle. | No. |
| `Tools.scala` | Scala + Kyo | Calls `cue-extended render`, `cue-extended patch set`, `cue vet`. No CUE logic of its own. | No. |
| `Main.scala` | Scala + Kyo | `KyoApp`: the round as a `Flow`, and the printing. Holds no rule. | No. |
| `project.scala` | scala-cli | Scala 3.9.0, JVM 25, Kyo 1.0.0-RC7 (core, system, flow). | No. |

## An initiative

An initiative is a CUE package of a project that imports `github.com/cyrildesch/cueverge/rules`:

| File | Written by | Role |
|---|---|---|
| `initiative.cue` | a person | `rules.#Initiative`: cases, oracle, candidate, budget, judge. |
| `round.cue` | a person, once | Wires the initiative to `rules.#Round`. Reading it never fails. |
| `check/check.cue` | a person, once | The decision, in its own package: wires the round to `rules.#NoRegression`. |
| `observed.gen.cue` | the kernel | The observations of the last round. Not versioned. |
| `sealed.gen.cue` | the kernel | The verdicts of the last round that held. |
| `intent.gen.cue` | the kernel | The intent extracted from the last generation (` ```intent ` block). Cleared when a round seals. |
| `approval.cue` | a person | `approval: intent: "<hash>"`: the intent a person approved. The only way to excuse a regression. |

## Intent

After a generation, Claude ends its message with its intent: the goal, the cases it fixes, the
regressions it causes on purpose and why. The kernel extracts it to `intent.gen.cue`;
`rules/intent.rules.cue` decides. A round holds its intent when every claimed fix failed before and
passes now, every regression is announced, and the intent is approved: by a person (its hash in
`approval.cue`), or by the auto-mode (`generator.intent.auto: true`) when it announces no regression.
An intent that awaits a person stops `-agent` and keeps the candidate; approve with `cueverge approve <hash> <dir>`, then run `cueverge round <dir>`.

## Build

```sh
mise run build                       # dist/cueverge/bin, linked into mise (JVM 25)
cueverge round initiatives/<name>    # from the root of a project
```

## Look around

```sh
cue-extended render ./initiatives/<name> --path round.summary --mode yaml
cue-extended where initiative.candidate.budgetMs ./initiatives/<name>   # who sets the budget
```

## Files

What each file of the kernel does, in more detail than its header.

### Main.scala

```
The kernel runs one round of an initiative as a Kyo Flow. It observes; CUE decides.

Every named node of the flow is recorded before the next one starts. The
decisions are a function of what was recorded: replaying an execution reads
the recorded values back instead of running the candidate again.

  initiative  read the initiative (CUE, through Polaris)
  reference   the verdicts of the last sealed round
  cases       the cases of this round
  observe     every case goes to the oracle and to the candidate, and is
              extracted at once: the journal holds observations, not raw answers
  retime      write observed.gen.cue; CUE gives the verdicts; late cases are
              timed again, one at a time, as the rules ask
  intent      what CUE says of the declared intent: held, outside, awaiting a person
  decision    write observed and reference back from the record, then
              `cue vet -c` on check/: observations & rules & seal ≠ ⊥ ?
  seal        the round holds: its verdicts go to sealed.gen.cue

The store is a CueFlowStore: every record lands in <initiative>/journal as
append-only CUE. `kernel -replay <execution> <dir>` seeds a new execution with
what was recorded before `decision`, decides again, and compares.

This file holds no rule. `kernel -diagram` prints the flow as Mermaid.
```

### Agent.scala

```
Agent: the generation side of co-generation. Claude Code, run headless
(`claude -p`), edits the candidate between two rounds. Generation is the one
stochastic step of the loop, so it is a Flow of its own and its record lands
in the journal like a round's: what Claude was told, what it did, what it
cost, and the patch.

  round → generate → round → generate → … → round

A round that holds seals the candidate. A round that is refused restores the
candidate the last sealed round judged: a regression is never kept.
After each generation, the kernel extracts Claude's intent from its last
message into intent.gen.cue; CUE judges whether the round holds it
(rules/intent.rules.cue). A round whose intent awaits a person stops the loop
and keeps the candidate: the person approves the hash in approval.cue, then
runs a round.

The loop stops when no valid input fails, when maxRounds generations ran,
when a fixed point moved, or when an intent awaits a person.
```

### CueFlowStore.scala

```
CueFlowStore: a Kyo FlowStore whose record is CUE.

The coordination of a FlowStore (claims, leases, tokens, invariants I1-I9)
stays in Kyo's memory store. This store wraps it and, after every write,
appends what the memory store now holds that the journal does not yet:
the new fields and the new history events of the execution.

The journal is append-only CUE. Each line is one declaration, and CUE unifies
them: the journal is a meet of facts, in any order, any number of times.

  <journal dir>/<execution>.gen.cue

  executions: "<id>": flow:   "round"
  executions: "<id>": hash:   "<structural hash of the flow>"
  executions: "<id>": fields: "observe": {tag: …, value: <the value, as CUE data>}
  executions: "<id>": events: "000007":  {<the event, as CUE data>}

Replaying an execution reads its fields back and seeds a new execution with
them: the engine skips every node whose field is present.
```

### Tools.scala

```
Tools calls the CUE toolchain. The kernel holds no CUE logic of its own: it
reads and writes values with Polaris (cue-extended), and lets `cue vet` decide.

  read → cue-extended render --path <path> --mode yaml
  set  → cue-extended patch set <path> --value-file … -f <file>
  vet  → cue vet -c <package>
```

### Extract.scala

```
Extract is the extractor: from a full answer to what can be observed of it
(#Answer in factory/rules/schema.rules.cue).

It is forgetful on purpose: a value is kept as two hashes, one of its text
(field order counts) and one of the value (field order does not count).

It belongs to the fixed points. A coarser extractor makes the rules looser
without touching them: changing it is a retraction.
```

### Export.scala

```
Export: the projection of the journal that we keep, versioned.

The raw journal (<execution>.gen.cue, claude-<session>.gen.cue) is Kyo Flow's
store and stays out of version control. factory/rules/export.rules.cue says,
in CUE, what we keep of it. Export writes one file per execution and per
Claude session that has none yet:

  journal/<execution>.export.cue     exports: executions: "<execution>": {…}
  journal/claude-<session>.export.cue exports: traces: "<session>": {…}

then `cue vet` checks the journal package: every export file unifies with what
the raw journal gives. An export that its journal does not give is refused.
```

### Run.scala

```
Run is the effect of the kernel: start a command on a case, wait for it,
time it. It knows nothing about what the answer means.
```

### Init.scala

```
cueverge init, a deterministic and journaled Kyo flow:

  problem   the problem, as the person states it
  scaffold  the files of a project, without AI. A missing file is created;
            .gitignore, mise.toml and cue.mod/module.cue get only the lines they lack
  draft     claude -p in the sandbox runtime: reads the repository, writes only
            .cueverge/draft/draft.cue. Model, budget and instructions come from
            the frame package of the factory module, at the version the project pins
  vet       cue vet on the draft and the check the kernel adds, then its hash
  approval  a Kyo input node: `cueverge approve <hash>` seeds a new execution
            <id>-approval with the recorded fields and the hash
  adopted   the draft becomes frame/frame.cue and intents/intents.cue; the project vets

`cueverge init -replay <execution>` vets again from the journal, without Claude.
```
