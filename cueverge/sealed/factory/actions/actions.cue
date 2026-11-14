// @what: what to do next, in order. Each action is a sealed fact. It holds when done, and is unknown until then.
// @invariant: the factory rule applies here too. An action with no measure does not vet.
// @ref: @/cueverge/cogen/gen-sealed/factory/actions/actions.cue
package actions

import (
	"github.com/cyrildesch/cueverge/schema"
	"factory.local/kb/sealed/factory/experiments"
	"factory.local/kb/sealed/factory/questions"
)

#ExperimentRef: or([for k, _ in experiments.experiments {"cue://experiments/experiments.\(k)"}])
#QuestionRef:   or([for k, _ in questions.questions {"cue://questions/questions.\(k)"}])
#ActionRef:     or([for k, _ in actions {"cue://actions/actions.\(k)"}])

#Action: {
	schema.#Fact...
	_humanize: title
	order:     int & >0
	title:     string
	says:      title
	// @what: what to do.
	statement: string
	// @what: what is measured to say it is done.
	measure!: string
	// @what: the result that counts as done.
	verdict!: string
	status:   "to do" | "in progress" | "done"
	cost:     "low" | "medium" | "high"
	runs?:    [...#ExperimentRef]
	answers?: [...#QuestionRef]
	after?:   [...#ActionRef]
	// @invariant: an action that needs a person says so.
	needsHuman?: string

	// @invariant: the polarity follows the status. Done holds, the rest is unknown until its experiments run.
	if status == "done" {holds: true}
	if status != "done" {holds: "unknown"}
}

actions: [string]: #Action

// @what: every sealed fact of the package.
facts: {for k, a in actions {
	(k): a...
}}
retired: [string]: schema.#Retired
retired: {
	bring_the_pilot_back_to_green: {was: "Fix the open regressions of the pilot, the last round of cue-interpreter.", why: "cue-interpreter was dropped on 2026-11-14. Its regressions no longer mean anything."}
	wire_the_pilot_constraints:    {was: "Wire on the pilot the constraints of the catalog that it can carry.", why: "cue-interpreter was dropped on 2026-11-14. Replaced by wire_the_project_constraints."}
	settle_the_pilot_frame:        {was: "Settle three questions of the frame of the pilot, among them the meaning of no compilation.", why: "cue-interpreter was dropped on 2026-11-14. Replaced by settle_the_project_frame, without the question of compilation."}
}

actions: {
	set_up_the_first_project: {
		order:      1
		title:      "Set up the first project with cueverge init"
		statement:  "The first project is the fork of Mistral Vibe that replaces the shell of the agent with Tacit. cueverge init prepares it, a person approves its frame, then the kernel captures its exports into gen/."
		measure:    "One round of the kernel on the project, and its capture checked by cueverge capture check."
		verdict:    "The project vets with cue vet, a round holds, and the capture matches its hashes."
		status:     "to do"
		cost:       "medium"
		runs:       ["cue://experiments/experiments.differential_loop", "cue://experiments/experiments.rejection_location", "cue://experiments/experiments.time_budget", "cue://experiments/experiments.deterministic_replay"]
		needsHuman: "Write the problem statement of the project, then approve its frame."
	}
	measure_stability: {
		order:     2
		title:     "Measure the stability of the verdicts"
		statement: "Take up again the measure that was stopped."
		measure:   "Three runs with no change, number of cases whose verdict varies."
		verdict:   "Zero unstable cases, or the list of the unstable cases and the rule that makes them stable."
		status:    "to do"
		cost:      "low"
		runs:      ["cue://experiments/experiments.stability"]
		answers:   ["cue://questions/questions.verdict_stability"]
		after:     ["cue://actions/actions.set_up_the_first_project"]
	}
	judge_in_cue: {
		order:     3
		title:     "Take the judgement out of the kernel and write it in CUE"
		statement: "The kernel observes and writes its observations in CUE. The rules of the factory module give the verdicts. cue vet decides whether the round holds, against the last sealed round."
		measure:   "An injected regression, and a loosened rule."
		verdict:   "The regression gives ⊥, and the loosening is detected."
		status:    "to do"
		cost:      "low"
		runs:      ["cue://experiments/experiments.judge_in_cue"]
		answers:   ["cue://questions/questions.what_cue_brings"]
		after:     ["cue://actions/actions.measure_stability"]
	}
	settle_the_threshold: {
		order:      4
		title:      "Settle the time threshold"
		statement:  "Write in the rules what a case whose time equals the budget is worth."
		measure:    "Ten rounds in a row with no change of the candidate."
		verdict:    "No round refused on noise."
		status:     "to do"
		cost:       "low"
		answers:    ["cue://questions/questions.time_threshold"]
		after:      ["cue://actions/actions.judge_in_cue"]
		needsHuman: "Choose between a tolerance margin and a band around the threshold."
	}
	lock_the_fixed_points: {
		order:     5
		title:     "Lock the fixed points and forbid loosening a rule"
		statement: "Hash of the kernel, the extractor and the corpus checked before each round. A gate on the CUE rules of the factory module (factory/rules/*.rules.cue) with polaris projdiff: a new rule must be stricter than or equal to the old one (R' ⊑ R), or a human decides."
		measure:   "Two attempts: change the corpus with no signature, then loosen a rule."
		verdict:   "The kernel refuses both."
		status:    "to do"
		cost:      "low"
		runs:      ["cue://experiments/experiments.fixed_points"]
		answers:   ["cue://questions/questions.what_cue_brings"]
		after:     ["cue://actions/actions.settle_the_threshold"]
	}
	orchestration_table: {
		order:     6
		title:     "Write the orchestration table in CUE"
		statement: "Regression: revert. Crash: fix first. Then wrongly accepts, wrongly rejects, rejects at the wrong place, too slow, not built yet. Three rounds with no progress or the budget reached: stop and escalate."
		measure:   "Replay the journal of the rounds already done through the table."
		verdict:   "At each round, the table names the task that was chosen by hand, or the difference is explained."
		status:    "to do"
		cost:      "low"
		after:     ["cue://actions/actions.lock_the_fixed_points"]
	}
	run_an_autonomous_agent: {
		order:      7
		title:      "Run an agent with no human in the loop"
		statement:  "The table runs the agent, with one rule: no regression is sealed, except one that a person approves in an intent. Without the auto mode, each generation waits for a person: a run with no human needs this mode."
		measure:    "Score reached, number of rounds, cost in tokens, point where it gets stuck."
		verdict:    "The score of the project goes up with no sealed regression, and two runs give the same sequence of orchestration decisions."
		status:     "in progress"
		cost:       "high"
		runs:       ["cue://experiments/experiments.autonomous_agent", "cue://experiments/experiments.sonnet_agent", "cue://experiments/experiments.reproducible_agent"]
		answers:    ["cue://questions/questions.agent_convergence", "cue://questions/questions.intent_grain"]
		after:      ["cue://actions/actions.orchestration_table"]
		needsHuman: "Agree on the token budget before the run."
	}
	law_without_oracle: {
		order:     8
		title:     "Wire the order law"
		statement: "Reordering the fields of a case must not change the output."
		measure:   "Number of cases where the law fails, and how many of these bugs the reference already caught."
		verdict:   "A figure: the share of the known bugs that the law finds with no oracle."
		status:    "to do"
		cost:      "low"
		runs:      ["cue://experiments/experiments.order_law"]
		answers:   ["cue://questions/questions.without_oracle"]
		after:     ["cue://actions/actions.set_up_the_first_project"]
	}
	state_in_braid: {
		order:     9
		title:     "Carry the state of the orchestrator with Braid"
		statement: "The code lives in jj: a batch is a change, the trunk is made of the immutable changes. Braid carries the keys, the parents, the heights and the verdicts. gaps dispatches the work."
		measure:   "The journal replayed in ten shuffled orders, with duplicates."
		verdict:   "Ten identical final states, and gaps equal to the choice of the table at each step."
		status:    "to do"
		cost:      "medium"
		runs:      ["cue://experiments/experiments.braid_as_state"]
		answers:   ["cue://questions/questions.sealing_authority", "cue://questions/questions.task_identity"]
		after:     ["cue://actions/actions.orchestration_table"]
	}
	simplify_under_constraint: {
		order:     10
		title:     "Have an agent simplify the candidate"
		statement: "Objective: fewer lines. Constraint: no verdict regresses."
		measure:   "Lines removed, verdicts before and after, and a reading of what was removed."
		verdict:   "A net reduction with no regression, or the constraint that was missing when the agent cheated."
		status:    "to do"
		cost:      "medium"
		runs:      ["cue://experiments/experiments.constrained_simplification"]
		after:     ["cue://actions/actions.run_an_autonomous_agent"]
	}
	two_competing_variants: {
		order:      11
		title:      "Compare two variants by their cost of change"
		statement:  "A reduced version first: the current candidate against a second one built by an agent, on three hidden requests."
		measure:    "Cost per request and regressions, for each variant."
		verdict:    "A clear difference between the two, or the finding that there is none."
		status:     "to do"
		cost:       "high"
		runs:       ["cue://experiments/experiments.two_variants"]
		answers:    ["cue://questions/questions.measurable_taste"]
		after:      ["cue://actions/actions.run_an_autonomous_agent"]
		needsHuman: "Choose the hidden requests."
	}
	reviewed_intent: {
		order:      13
		title:      "Have the agent declare its intent, and make it keep it"
		statement:  "After each generation, the agent declares its goal, the cases it fixes and the regressions it accepts. The kernel extracts this intent, the intent rules of the factory module check that the round keeps it, and a person approves its hash. The auto mode alone approves an intent with no regression."
		measure:    "One run of the agent on the project: intents extracted, intents kept, approvals asked, and the case that passes by accident."
		verdict:    "No empty or false intent is sealed, and the fix that breaks the case passing by accident is sealed after approval."
		status:     "to do"
		cost:       "medium"
		runs:       ["cue://experiments/experiments.intent_on_a_project"]
		answers:    ["cue://questions/questions.passing_by_accident", "cue://questions/questions.intent_grain"]
		needsHuman: "Approve the intents, and decide on the auto mode."
	}
	kernel_in_scala: {
		order:      12
		title:      "Rewrite the kernel as a functor, with a second initiative"
		statement:  "Initiative trait, effects in the types, composition of two constraints."
		measure:    "The same verdicts as the current kernel on the first project, and a second initiative of another nature that runs."
		verdict:    "The same verdicts case by case, and no line of the kernel changed for the second initiative."
		status:     "to do"
		cost:       "medium"
		runs:       ["cue://experiments/experiments.kernel_functor"]
		answers:    ["cue://questions/questions.kernel_abstraction"]
		after:      ["cue://actions/actions.state_in_braid"]
		needsHuman: "Choose the second initiative."
	}
	service_initiative: {
		order:      14
		title:      "Set up a second initiative: a service with state and deployment"
		statement:  "Many constraints of the catalog need durable state, a deployment or an outgoing call. A small deployed service makes them measurable, continuously, with a human gate on what cannot be undone."
		measure:    "The constraints of the catalog with no equivalent on the first project, wired on the service, and the path of an irreversible write."
		verdict:    "Each wired constraint fails a round when it breaks, and an irreversible write waits for a person."
		status:     "to do"
		cost:       "high"
		after:      ["cue://actions/actions.kernel_in_scala"]
		needsHuman: "Choose the service."
	}
	wire_the_project_constraints: {
		order:      15
		title:      "Wire on the first project the constraints of the catalog that it can carry"
		statement:  "Old data, old clients, idempotence, secrets in the logs, memory leak, cost per request: each one becomes a line of the initiative and a verdict."
		measure:    "For each constraint that is possible on the project, a measure in the initiative and a round that breaks it on purpose."
		verdict:    "The broken round is refused for each constraint, or we write why it cannot be wired."
		status:     "to do"
		cost:       "medium"
		after:      ["cue://actions/actions.settle_the_threshold"]
		supersedes: "wire_the_pilot_constraints"
	}
	judge_without_measure: {
		order:      16
		title:      "Have an agent that plays the human judge a constraint with no measure"
		statement:  "An error message or an alert has no measure. An agent that plays the user, or the on-call engineer, gives a judgement. We compare it with the judgement of a person."
		measure:    "The agreement between the judgement of the agent and that of a person, on a sample of error messages of the project."
		verdict:    "A rate of agreement, and the decision to keep this judgement as a verdict or not."
		status:     "to do"
		cost:       "medium"
		answers:    ["cue://questions/questions.unmeasurable_constraints"]
		needsHuman: "Judge the sample."
	}
	settle_the_project_frame: {
		order:      17
		title:      "Settle two questions of the frame of the first project"
		statement:  "What the budget bounds, and whether the agent can query the reference by hand. Each choice becomes a rule of the frame of the initiative."
		measure:    "A rule in the frame for each choice, checked by cue vet."
		verdict:    "The two questions have a rule, or a written reason not to have one."
		status:     "to do"
		cost:       "low"
		answers:    ["cue://questions/questions.bypassable_budget", "cue://questions/questions.oracle_access"]
		needsHuman: "Make the two choices."
		supersedes: "settle_the_pilot_frame"
	}
	features_behind_a_flag: {
		order:      18
		title:      "Propose a feature behind a flag, and remove it with a trace"
		statement:  "The system proposes a feature that adds without loosening, declares its hypothesis, measures it, and removes it with a tombstone guarded by a condition."
		measure:    "A proposed feature, its hypothesis, its measure on real traffic, and its tombstone."
		verdict:    "The feature is kept or removed on its measure, and a removed tombstone comes back when its condition falls."
		status:     "to do"
		cost:       "high"
		after:      ["cue://actions/actions.service_initiative"]
		needsHuman: "Wait for real users."
	}
}
