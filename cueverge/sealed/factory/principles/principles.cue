// @what: the ideas the factory rests on. Each one says whether a project tested it, or what will test it.
// @invariant: a principle is intent. Its rule checks that it is consistent with the experiments and actions, never a source.
// @ref: @/cueverge/cogen/gen-sealed/factory/principles/principles.cue
package principles

import (
	"github.com/cyrildesch/cueverge/schema"
	"factory.local/kb/sealed/factory/actions"
	"factory.local/kb/sealed/factory/experiments"
)

#ExperimentRef: or([for k, _ in experiments.experiments {"cue://experiments/experiments.\(k)"}])
#ActionRef:     or([for k, _ in actions.actions {"cue://actions/actions.\(k)"}])

#Principle: {
	schema.#Fact...
	_humanize: title
	title:     string
	says:      title
	statement: string
	status:    "tested on a project" | "stated, not tested"
	evidence?: [...#ExperimentRef]
	// @what: the experiment or the action that will test an untested principle.
	testedBy?: #ExperimentRef | #ActionRef
	limits?:   [...string]

	// @invariant: the status follows from the evidence. It is never declared alone.
	if evidence != _|_ if len(evidence) > 0 {status: "tested on a project"}
	if evidence == _|_ {status: "stated, not tested"}

	// @invariant: tested holds, untested is unknown and names what will test it.
	if status == "tested on a project" {holds: true}
	if status == "stated, not tested" {
		holds:     "unknown"
		testedBy!: _
	}
}

principles: [string]: #Principle

// @what: every sealed fact of the package.
facts: {for k, p in principles {
	(k): p...
}}
retired: [string]: schema.#Retired
retired: {}

principles: {
	envelope: {
		title:     "The human writes the frame, the agents write the code"
		statement: "The human sets the problem, the constraints and what is tolerated. No one reviews the code that is produced. We review the frame, the intents and what loosens the frame."
		status:    "stated, not tested"
		testedBy:  "cue://actions/actions.run_an_autonomous_agent"
	}
	problem_and_constraints: {
		title:     "A problem and constraints"
		statement: "Constraints alone pull towards nothing: an empty program respects many of them. A measurable objective must pull, and constraints must bound. Innovation is then optimization under constraints."
		status:    "stated, not tested"
		testedBy:  "cue://experiments/experiments.constrained_simplification"
		limits:    ["A problem that we cannot measure gives the agent no direction."]
	}
	boundaries: {
		title:     "Observe at the boundaries, never the inside"
		statement: "We do not check each function. What is not observed can be rewritten or deleted without touching a check: this is what makes the system simplifiable."
		status:    "stated, not tested"
		testedBy:  "cue://experiments/experiments.constrained_simplification"
	}
	rule_before_observation: {
		title:     "We observe only what a rule reads"
		statement: "Three levels: the verdict, the place, the internal detail. The last one opens only on a case that fails. A level is added only if it catches bugs that the previous one let through."
		status:    "stated, not tested"
		testedBy:  "cue://experiments/experiments.rejection_location"
	}
	addressed_observations: {
		title:     "A journal of observations at a stable address"
		statement: "The view by effects, generalized. For a service, the address is the outgoing call. For an interpreter, the path in the tree. For a proof, the step. We write the comparison rules before we run."
		status:    "stated, not tested"
		testedBy:  "cue://experiments/experiments.rejection_location"
		limits:    ["The journal of a candidate is not compared from one iteration to the next yet."]
	}
	previous_version_as_oracle: {
		title:     "The previous version is the oracle"
		statement: "A complete oracle is rare. From the second version on, the previous one says what changed. A feature is a declared difference; any other difference is a regression."
		status:    "stated, not tested"
		testedBy:  "cue://experiments/experiments.differential_loop"
		limits:    ["It says different, not correct. The first version has no base."]
	}
	executed_constraint: {
		title:     "A constraint that is not executed will be forgotten"
		statement: "A constraint exists if it has a statement, a measure that the loop can take and a verdict that fails the round. The agent does not have to remember it: the loop remembers it. With no measure, it is a debt to make visible."
		status:    "stated, not tested"
		testedBy:  "cue://experiments/experiments.time_budget"
	}
	continuous_test: {
		title:     "The test is continuous, not attached to the PR"
		statement: "Three cadences: a fast subset at each change, the cheap constraints continuously on the deployed system, the costly exercises on a schedule. In exchange, we must know which change broke something and revert with no human."
		status:    "stated, not tested"
		testedBy:  "cue://actions/actions.service_initiative"
		limits:    ["The first project has no deployment and no continuous run yet."]
	}
	reviewed_intent: {
		title:     "The human reviews the intent, the loop checks that it is kept"
		testedBy:  "cue://experiments/experiments.intent_on_a_project"
		statement: "Before a round, the agent declares its intent: the goal, the scope it touches, the expected effect on the cases, and the announced regressions with their reason. The human reviews these few lines, never the diff. The judge refuses a round that goes outside the approved intent, even if all the other rules pass. An auto mode alone approves a routine intent: no announced regression, a scope inside that of the initiative, no rule and no fixed point touched. Turning on this mode removes a human look: it is a loosening, and only the human turns it on."
		limits: [
			"The judge checks the scope and the direction of the effects, not that a given reason is true.",
			"A vague intent passes every check: the format must require the expected effect.",
		]
	}
	semi_lights_off: {
		title:     "Semi: a human gate on the irreversible"
		statement: "What can be undone is detected afterwards and reverted. What cannot be undone (destructive migration, sending to a third party, writing in production) goes through a human approval before it runs."
		status:    "stated, not tested"
		testedBy:  "cue://actions/actions.service_initiative"
	}
	three_layers: {
		title:     "A determinism that grows around fixed points"
		statement: "Fixed points: invariants, judge, meaning of a verdict, changed by the human alone. Evolving rules: the agents add some as long as it tightens. Produced code: free. Loosening a rule is a request to the human."
		status:    "stated, not tested"
		testedBy:  "cue://experiments/experiments.fixed_points"
		limits:    ["A fixed point must be a physical impossibility, not an instruction."]
	}
	deterministic_orchestration: {
		title:     "The orchestrator is a program, not an agent"
		statement: "A table of rules: such a state, such an action. The model is called as a function on a bounded task. When no line matches, the decision goes up to a human and becomes a line."
		status:    "stated, not tested"
		testedBy:  "cue://actions/actions.orchestration_table"
	}
	convergent_state: {
		title:     "The state is the join of the journal"
		statement: "The state of an initiative is a Braid: open candidates, sealed trunk. The reports arrive in any order. The work to start is the gaps of the state. After a failure, we replay the journal."
		status:    "stated, not tested"
		testedBy:  "cue://experiments/experiments.braid_as_state"
		limits: [
			"The authority that seals is still to define.",
			"A node has a single parent: the candidates rebase, they do not merge.",
		]
	}
	exclusive_ownership: {
		title:     "Workers that own, with no messaging"
		statement: "A worker owns its sandbox, its files and its budget. The workers do not talk to each other: they read and write a shared state. No private fact."
		status:    "stated, not tested"
		testedBy:  "cue://experiments/experiments.braid_as_state"
	}
	sync_at_sealing: {
		title:     "A single point of synchronization: the sealing"
		statement: "Read the head, work alone, publish, seal, rebase. Duplicate work is limited by a dated claim, a deterministic tie-break, assignment by ownership and cancellation by the state."
		status:    "stated, not tested"
		testedBy:  "cue://experiments/experiments.braid_as_state"
		limits:    ["Two distinct tasks with the same root cause are not seen as duplicates."]
	}
	taste_by_cost_of_change: {
		title:     "Taste is measured by the cost of the next change"
		statement: "We test several solutions under a series of requests and keep the one that absorbs them at the lowest cost."
		status:    "stated, not tested"
		testedBy:  "cue://experiments/experiments.two_variants"
		limits:    ["Taste on the product needs real users."]
	}
	features_and_tombstones: {
		title:     "The system proposes, measures, and removes with a trace"
		statement: "A proposed feature adds without loosening, starts behind a flag and declares its hypothesis before the experiment. When removed, it leaves a tombstone guarded by a condition read on observations. When the condition falls, the feature can come back."
		status:    "stated, not tested"
		testedBy:  "cue://actions/actions.features_behind_a_flag"
		limits:    ["New software has little traffic: most A/B tests will not conclude."]
	}
	abstract_kernel: {
		title:     "An abstract kernel around any initiative"
		statement: "The kernel is a functor: an initiative goes in, a loop comes out. It composes on validation (tighten, conjoin), not on generation."
		status:    "stated, not tested"
		testedBy:  "cue://experiments/experiments.kernel_functor"
		limits:    ["Only one initiative and one type of judge exist."]
	}
}
