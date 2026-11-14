// @what: what the conversation settled, and what it only leaned towards.
// @invariant: a decision is intent. Its rule checks it against the principles and actions, never against a source.
// @ref: @/cueverge/cogen/gen-sealed/factory/decisions/decisions.cue
package decisions

import (
	"github.com/cyrildesch/cueverge/schema"
	"factory.local/kb/sealed/factory/actions"
	"factory.local/kb/sealed/factory/experiments"
	"factory.local/kb/sealed/factory/principles"
)

#PrincipleRef:  or([for k, _ in principles.principles {"cue://principles/principles.\(k)"}])
#ActionRef:     or([for k, _ in actions.actions {"cue://actions/actions.\(k)"}])
#ExperimentRef: or([for k, _ in experiments.experiments {"cue://experiments/experiments.\(k)"}])

#Decision: {
	schema.#Fact...
	_humanize: title
	title:     string
	says:      title
	decision:  string
	why:       string
	status:    "settled" | "to confirm" | "postponed"
	rejected?: string
	restsOn?:  [...#PrincipleRef]
	// @what: the action or the experiment that will settle a decision not settled yet.
	settledBy?: #ActionRef | #ExperimentRef

	// @invariant: a settled decision holds and rests on tested principles. The others are unknown and name what settles them.
	if status == "settled" {
		holds:    true
		restsOn!: [_, ...]
	}
	if status != "settled" {
		holds:      "unknown"
		settledBy!: _
	}
}

decisions: [string]: #Decision

// @what: every sealed fact of the package.
facts: {for k, d in decisions {
	(k): d...
}}
retired: [string]: schema.#Retired
retired: {
	pilot_cue_interpreter: {was: "The pilot is a CUE interpreter with no compilation.", why: "cue-interpreter was dropped on 2026-11-14. Replaced by first_project_vibe_tacit."}
}

decisions: {
	start_from_scratch: {
		title:     "New software, not existing code"
		decision:  "The factory builds software from scratch. The studies made on existing code are things learned, not the ground."
		why:       "With no existing code, the stack and the process are free, and the stack decides the duration of an iteration."
		status:    "to confirm"
		settledBy: "cue://actions/actions.run_an_autonomous_agent"
		restsOn:   ["cue://principles/principles.envelope"]
	}
	first_project_vibe_tacit: {
		title:      "The first project is Mistral Vibe with Tacit"
		decision:   "The first project that the factory builds is a fork of Mistral Vibe that replaces the shell of the agent with Tacit: Scala code with typed capabilities, which the compiler checks."
		why:        "The control of shell commands in Vibe has open flaws. The project has its own tests and scenarios to judge with, and it serves a European need."
		status:     "to confirm"
		settledBy:  "cue://actions/actions.set_up_the_first_project"
		restsOn:    ["cue://principles/principles.abstract_kernel"]
		supersedes: "pilot_cue_interpreter"
	}
	real_e2e_first: {
		title:     "A real e2e test before any design"
		decision:  "Each idea goes through a measure on a real project before it is developed."
		why:       "The conversation was drifting towards an imaginary tool."
		status:    "to confirm"
		settledBy: "cue://experiments/experiments.time_budget"
		restsOn:   ["cue://principles/principles.executed_constraint"]
	}
	no_per_function_check: {
		title:     "No function-by-function check"
		decision:  "The complete journal of the inside of the candidate is dropped."
		why:       "The whole must stay simplifiable."
		rejected:  "Emit path and value for the whole tree at each round."
		status:    "to confirm"
		settledBy: "cue://experiments/experiments.constrained_simplification"
		restsOn:   ["cue://principles/principles.boundaries", "cue://principles/principles.rule_before_observation"]
	}
	continuous_test_over_pr: {
		title:     "The constraints live in continuous testing"
		decision:  "The PR keeps only a fast subset. The rest is checked on the running system."
		why:       "Many constraints mean nothing on a diff, and checking everything before a merge makes the loop longer."
		status:    "to confirm"
		settledBy: "cue://actions/actions.service_initiative"
		restsOn:   ["cue://principles/principles.continuous_test", "cue://principles/principles.semi_lights_off"]
	}
	no_flink: {
		title:     "No Flink and no Fluss for now"
		decision:  "The orchestrator is a pure function on a journal. The engine is a deployment decision, postponed."
		why:       "An agent run is long, costly and has effects: a stream engine would replay it after a failure. The target throughput does not justify a cluster."
		status:    "to confirm"
		settledBy: "cue://actions/actions.orchestration_table"
		restsOn:   ["cue://principles/principles.deterministic_orchestration", "cue://principles/principles.convergent_state"]
	}
	ownership_over_actors: {
		title:     "Exclusive ownership and shared state, not actors"
		decision:  "From actors we keep the ownership of resources, the isolation of failures and serial processing. We drop direct messaging and private state."
		why:       "Spawn saw the volume of messages grow four times when the number of agents doubled, and removed this channel."
		status:    "to confirm"
		settledBy: "cue://experiments/experiments.braid_as_state"
		restsOn:   ["cue://principles/principles.exclusive_ownership"]
	}
	jj_as_version_control: {
		title:     "jj, on the model of Mercurial"
		decision:  "jj carries the candidates: stable identity of the change, automatic rebase, conflicts as data, immutable heads, one workspace per agent."
		why:       "The phases and the obsolescence markers of Mercurial match the open and sealed zones. jj gives them and keeps Git as storage."
		rejected:  "Plain Git: a rebase breaks the identity of the change."
		status:    "to confirm"
		settledBy: "cue://experiments/experiments.braid_as_state"
		restsOn:   ["cue://principles/principles.sync_at_sealing"]
	}
	braid_for_the_orchestrator: {
		title:     "Braid carries the state of the orchestrator"
		decision:  "Reuse the Braid module: open zone for the candidates, sealed zone for the trunk, gaps as the dispatcher."
		why:       "The join does not depend on the order and its laws are already checked."
		status:    "to confirm"
		settledBy: "cue://actions/actions.state_in_braid"
		restsOn:   ["cue://principles/principles.convergent_state"]
	}
	kernel_in_scala: {
		title:     "The kernel in Scala with Kyo"
		decision:  "The kernel is written in Scala 3 with Kyo. The functor shape (Initiative trait, effects in the types) is still to write."
		why:       "The types guarantee that a candidate does not touch the world without saying so. The kernel is a fixed point, rarely compiled. Braid is in Scala."
		status:    "to confirm"
		settledBy: "cue://experiments/experiments.kernel_functor"
		restsOn:   ["cue://principles/principles.abstract_kernel"]
	}
	autonomous_features: {
		title:     "Features proposed by the system, A/B and tombstones"
		decision:  "Wanted, but built after the base loop and the arrival of real users."
		why:       "A feature registry makes sense only with traffic to measure."
		status:    "postponed"
		settledBy: "cue://actions/actions.features_behind_a_flag"
		restsOn:   ["cue://principles/principles.features_and_tombstones"]
	}
	base_as_source_of_truth: {
		title:     "The base holds the knowledge of the factory and the captures of its projects"
		decision:  "The knowledge of the factory, its rules and the captures of the exports of its projects live in this base. Each project keeps its frame, its seal, its journal and its code, and imports the tool."
		why:       "A constraint, a problem or a trace outside a base cannot be checked by it. Importing a project from the tool that it imports would make a loop."
		status:    "to confirm"
		settledBy: "cue://actions/actions.set_up_the_first_project"
		restsOn:   ["cue://principles/principles.executed_constraint"]
	}
	every_fact_backed: {
		title:     "Every fact is backed, or the base does not pass"
		decision:  "A fact is declared by a described jj change, or generated by a mechanism that the base checks. A claim says what it is about; it is stale as soon as its subject changes after it. An observation is computed, it is not copied."
		why:       "A text that stays true out of habit is the debt that is hardest to see: four texts still described a kernel that was rewritten."
		status:    "to confirm"
		settledBy: "cue://experiments/experiments.time_budget"
		restsOn:   ["cue://principles/principles.executed_constraint"]
	}
	round_as_kyo_flow: {
		title:     "A round is a Kyo Flow, journaled in CUE"
		decision:  "Each node of a round is recorded before the next one. The raw journal is the storage of Kyo; what we keep is its export, checked against it."
		why:       "The decisions become a function of the journal: a round replays without running the candidate again."
		status:    "to confirm"
		settledBy: "cue://experiments/experiments.braid_as_state"
		restsOn:   ["cue://principles/principles.convergent_state"]
	}
	claude_code_generator: {
		title:     "The generator is Claude Code, headless"
		decision:  "A generation runs claude -p with the model, the budget and the permissions declared in the frame of the example, and journals its trace."
		why:       "Do exactly what Claude Code does, with a small model while we test."
		status:    "to confirm"
		settledBy: "cue://actions/actions.run_an_autonomous_agent"
		restsOn:   ["cue://principles/principles.envelope"]
	}
}
