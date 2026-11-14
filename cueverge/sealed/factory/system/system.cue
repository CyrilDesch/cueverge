// @what: the constraints of the factory itself, and the measures that say whether each one holds.
// @invariant: this package computes nothing. It states each value, and the system cogen rules recompute it from a capture of a project.
// @ref: @/cueverge/cogen/gen-sealed/factory/system/system.cue
package system

import (
	"github.com/cyrildesch/cueverge/schema"
	"factory.local/kb/sealed/factory/actions"
)

#ActionRef: or([for k, _ in actions.actions {
	k...
}])

// @what: a constraint we set, or a measure that a constraint shows.
#Entry: {
	schema.#Fact...
	kind: "constraint" | "measure"
	if kind == "constraint" {
		title:   string
		why:     string
		family:  "organization" | "verdict" | "judge" | "cost"
		measure: string
	}
	title?:   string
	why?:     string
	family?:  string
	measure?: string
	// @what: the measures shown with the constraint.
	with?: [...string]
	// @what: the action that builds what the constraint needs.
	action?: #ActionRef
}

facts: [string]:   #Entry
retired: [string]: schema.#Retired
retired: {}

facts: {
	refusals:            {kind: "measure", says: "Complete rounds refused", holds: "unknown", action: "set_up_the_first_project"}
	money_lost:          {kind: "measure", says: "Money of the generations lost", holds: "unknown", action: "set_up_the_first_project"}
	money_spent:         {kind: "measure", says: "Money spent on generations", holds: "unknown", action: "set_up_the_first_project"}
	generation_duration: {kind: "measure", says: "Median duration of a generation", holds: "unknown", action: "set_up_the_first_project"}

	one_task_one_agent: {
		kind:    "constraint"
		title:   "Never two agents on the same task"
		says:    "A task is reserved by the agent that takes it. Another agent cannot take it at the same time."
		holds:   "unknown"
		why:     "With two agents on the same task, one of the two works for nothing."
		family:  "organization"
		measure: "The tasks taken twice at the same time, in the journal."
		action:  "orchestration_table"
	}

	replay_not_discard: {
		kind:    "constraint"
		title:   "A change that loses its place is replayed, not thrown away"
		says:    "If another change got in before it, it is replayed on the new base: one more test, not a new generation."
		holds:   "unknown"
		why:     "The test costs almost nothing, the generation costs a lot."
		family:  "organization"
		measure: "The changes lost to concurrency and never replayed."
		action:  "state_in_braid"
	}

	move_not_discard: {
		kind:    "constraint"
		title:   "What was built on a failed attempt is moved, not thrown away"
		says:    "The work built on a change that fails is replayed on what holds."
		holds:   "unknown"
		why:     "The work was not wrong: its base was."
		family:  "organization"
		measure: "The changes built on a failed attempt and never replayed."
		action:  "state_in_braid"
	}

	never_the_same_wall: {
		kind:    "constraint"
		title:   "Never the same wall twice"
		says:    "An attempt whose effect was already refused is not run again. The next task says what must not be broken."
		holds:   "unknown"
		with:    ["refusals"]
		why:     "On 12 November, three generations broke the same case, one after the other."
		family:  "organization"
		measure: "The refused rounds that break exactly the same cases as an earlier refusal."
		action:  "orchestration_table"
	}

	single_decider: {
		kind:    "constraint"
		title:   "A single decider at a time"
		says:    "A single table chooses what goes into trial. It writes its decision, and everyone reads it."
		holds:   "unknown"
		why:     "Two contradictory decisions lose the work started on one of them."
		family:  "organization"
		measure: "The trial decisions written by two deciders at the same time."
		action:  "orchestration_table"
	}

	coherence_before_generation: {
		kind:    "constraint"
		title:   "The coherence of the rules is checked before generating"
		says:    "A request that is incompatible with another one is detected before an agent is paid to write it."
		holds:   "unknown"
		why:     "Checking rules costs almost nothing; writing code that can never pass costs a generation."
		family:  "verdict"
		measure: "The generations started on rules whose meeting is empty."
		action:  "lock_the_fixed_points"
	}

	test_before_proposing: {
		kind:    "constraint"
		title:   "The agent runs the real test before proposing"
		says:    "In its copy, the agent runs the same judge as the trial. It sees its regressions before it proposes."
		holds:   "unknown"
		why:     "On 12 November, the agent only had a reduced test: 4 refusals out of 4, with no warning."
		family:  "verdict"
		measure: "The changes proposed without a complete round of the judge in the copy of the agent."
		action:  "state_in_braid"
	}

	evolution_without_loss: {
		kind:    "constraint"
		title:   "Changing the request throws away only what contradicts it"
		says:    "When a person changes the objective or the constraints, the work in progress that stays compatible is kept."
		holds:   "unknown"
		why:     "A person can change the request at any time."
		family:  "verdict"
		measure: "The work thrown away after a change while it stayed compatible."
		action:  "orchestration_table"
	}

	lost_cost: {
		kind:    "constraint"
		title:   "The lost cost stays under a ceiling"
		says:    "The share of the money spent on generations that never reaches what is acquired stays under 20 %."
		holds:   "unknown"
		action:  "set_up_the_first_project"
		with:    ["money_lost", "money_spent"]
		why:     "A generation costs a lot; the rest of the loop almost nothing. It is the measure that sums up all the others."
		family:  "cost"
		measure: "The cost of the generations of which the next round kept nothing, over the cost of all the generations."
	}

	judge_cadence: {
		kind:    "constraint"
		title:   "The judge goes ten times faster than the agents"
		says:    "A round of the judge lasts at most a tenth of a generation. If not, the agents build on what is not judged yet."
		holds:   "unknown"
		action:  "set_up_the_first_project"
		with:    ["generation_duration"]
		why:     "As in a blockchain: when the validators lag, reorganizations happen."
		family:  "judge"
		measure: "The median duration of a complete round, and that of a generation."
	}

	stable_judge: {
		kind:    "constraint"
		title:   "The judge is stable"
		says:    "With no change of the code, no verdict flips from one round to the next."
		holds:   "unknown"
		why:     "An unstable verdict is a faulty validator: it undoes work with no fault at all."
		family:  "judge"
		measure: "The verdicts that change between two rounds with no change of the candidate."
		action:  "settle_the_threshold"
	}

	rare_reorganizations: {
		kind:    "constraint"
		title:   "Reorganizations stay rare"
		says:    "The share of the work built on an attempt that fails stays under 20 %."
		holds:   "unknown"
		why:     "Each reorganization replays work, and sometimes loses it."
		family:  "judge"
		measure: "The changes built on a head in trial that failed, over all the changes."
		action:  "state_in_braid"
	}
}
