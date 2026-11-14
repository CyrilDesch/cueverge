// @what: what was run, or is to be run, and what it showed. Every number is a measure that the experiments cogen recomputes.
// @invariant: this package computes nothing. A number in a result is the value of a measure of the same experiment.
// @ref: @/cueverge/cogen/gen-sealed/factory/experiments/experiments.cue
package experiments

import "github.com/cyrildesch/cueverge/schema"

#Experiment: {
	schema.#Fact...
	kind:      "experiment"
	_humanize: title
	title:     string
	says:      title
	question:  string
	method:    string
	status:    "done" | "planned" | "stopped" | "discarded"
	cost:      "low" | "medium" | "high"
	result?:   string
	learned?:  [...string]
	limits?:   [...string]

	// @invariant: the polarity follows the status. Done holds, planned is unknown, stopped or discarded does not hold.
	if status == "done" {holds: true}
	if status == "planned" {holds: "unknown"}
	if status == "stopped" || status == "discarded" {holds: false}

	// @invariant: a finished experiment states its result and what it does not show.
	if status == "done" {
		result!: string
		limits!: [string, ...string]
	}

	// @invariant: an experiment that did not run says why.
	if status == "stopped" || status == "discarded" {
		result!: string
	}
}

// @what: one number an experiment measured. The experiments cogen recomputes it from the runs or the journal.
#Measure: {
	schema.#Fact...
	kind: "measure"
	experiment: or([for k, _ in experiments {
		k...
	}])
	holds: true
	value: number
}

experiments: [string]: #Experiment
measures: [string]:    #Measure

// @what: every sealed fact of the package. An experiment and a measure never share a key.
facts: {
	for k, e in experiments {
		(k): e...
	}
	for k, m in measures {
		(k): m...
	}
}

experiments: {
	differential_loop: {
		title:    "A differential loop against a reference"
		question: "Is an e2e test against a live oracle quick to set up, and does it steer the fixes?"
		method:   "On the first project, the fork of Mistral Vibe with Tacit. The kernel sends each case of the corpus to the reference, the version of Vibe frozen at the start, and to the candidate, compares the outputs and records the round."
		status:   "planned"
		cost:     "low"
	}

	rejection_location: {
		title:    "Compare where a rejection happens, not only the rejection"
		question: "When both sides reject an input, do they reject it at the same place?"
		method:   "A rule of the initiative extracts the place that each rejection names. The kernel compares the places, not only the fact of rejecting."
		status:   "planned"
		cost:     "low"
	}

	time_budget: {
		title:    "A response time constraint carried by the loop"
		question: "Is a non-functional constraint declared in the initiative applied without the agent having to remember it?"
		method:   "One line in the initiative declares a time budget. A correct answer outside the budget gets the verdict late and fails the round."
		status:   "planned"
		cost:     "low"
	}

	stability: {
		title:    "Do three runs with no change give the same verdicts?"
		question: "Is the project deterministic?"
		method:   "Run the kernel three times with no change and count the cases whose verdict changes. Measure again with the time retry rule, then under heavy load."
		status:   "planned"
		cost:     "low"
	}

	effectful_program: {
		title:    "A program with three effects and five mutations"
		question: "How many more bugs does comparing effects catch than comparing results?"
		method:   "A small program (outgoing HTTP call, key-value store, clock), a journal of effects, rules written first, five injected mutations."
		status:   "discarded"
		cost:     "medium"
		result:   "Discarded: the CUE interpreter stays the right exercise. The idea of effects was generalized into observations at a stable address."
	}

	autonomous_agent: {
		title:    "An agent with no human in the loop"
		question: "Does an agent alone converge, and in a reproducible way?"
		method:   "Run an agent alone from a sealed candidate, with no person in the loop. One editable scope, no regression tolerated, a budget of rounds. The hash of the fixed points is taken before and computed again after, and the result is measured again without the report of the agent."
		status:   "planned"
		cost:     "high"
	}

	reproducible_agent: {
		title:    "Two runs, the same decisions"
		question: "Do two runs of an agent from the same start give the same sequence of orchestration decisions?"
		method:   "Run the agent twice through the orchestration table, from the same sealed candidate and with the same budget. Compare, round by round, the chosen task and the decision of the judge."
		status:   "planned"
		cost:     "high"
	}

	constrained_simplification: {
		title:    "Shrink the candidate without breaking anything"
		question: "Can an agent simplify the inside with no human review?"
		method:   "Objective: reduce the size of the candidate. Constraint: no verdict regresses. Look at whether it really simplifies, or whether it deletes code that the corpus does not cover."
		status:   "planned"
		cost:     "medium"
	}

	two_variants: {
		title:    "Two variants against a series of hidden requests"
		question: "Do two solutions that are correct at the same moment differ by their cost of change?"
		method:   "Two agents each build a candidate under the same constraints. The same series of hidden requests is applied to both. Measure the cost per request and the regressions."
		status:   "planned"
		cost:     "high"
	}

	order_law: {
		title:    "Reordering the fields does not change the result"
		question: "Does a law checked with no oracle catch bugs?"
		method:   "For each case, produce a variant with reordered fields and require the same output from the candidate."
		status:   "planned"
		cost:     "low"
	}

	braid_as_state: {
		title:    "The state of the orchestrator as a Braid"
		question: "Can gaps serve as the dispatcher of the work?"
		method:   "Write the state as a Braid over the jj changes (a batch is a change) with the existing module. Replay the exports of the real journal of the project in shuffled orders and with duplicates. Check that the final state is the same and that gaps names the work chosen by hand."
		status:   "planned"
		cost:     "medium"
	}

	judge_in_cue: {
		title:    "The judge written as CUE constraints, decided by cue vet"
		question: "Can the judgement of a round leave the code of the kernel and become a meeting of constraints?"
		method:   "The kernel only executes: it writes its observations in CUE, the rules of the factory module give the verdicts, and cue vet decides against the last sealed round. Controls: an injected regression, a loosened rule."
		status:   "planned"
		cost:     "low"
	}

	fixed_points: {
		title:    "Fixed points by hash, and rules that do not loosen"
		question: "Can we make it physically impossible for an agent to move a fixed point or loosen a rule?"
		method:   "Check the hash of the kernel, the extractor and the corpus before each round. Refuse, with polaris projdiff, a change of the CUE rules that is not stricter than the old one: the new rule R' must be subsumed by the old rule R (R' ⊑ R), unless a human agrees."
		status:   "planned"
		cost:     "low"
	}

	kernel_functor: {
		title:    "The kernel as a functor in Scala"
		question: "Does the abstraction hold on real code and on two initiatives?"
		method:   "Give the Scala kernel the shape of a functor: an Initiative trait with abstract type members. First instance: the first project. Second: an initiative of another nature. Compose two constraints and check that the verdict is their conjunction."
		status:   "planned"
		cost:     "medium"
	}

	sonnet_agent: {
		title:    "Sonnet loops on the Kyo kernel"
		question: "Does a small model, run by the kernel between two rounds, move the trunk forward?"
		method:   "Loops of generations. Each generation runs Claude Code headless (claude -p, model sonnet) in the sandbox, with one editable scope. A refused round restores the sealed candidate."
		status:   "planned"
		cost:     "low"
	}

	intent_on_a_project: {
		title:      "An intent declared, kept, then approved"
		question:   "Does an intent declared by the agent and approved by a person unblock a fix that a case passing by accident was blocking?"
		method:     "A Sonnet loop on the Kyo kernel. After each generation, the agent ends with its intent: goal, cases fixed, regressions it accepts with their reason. The intent rules of the factory module judge the round, and a person approves the hash of an intent that excuses a regression."
		status:     "planned"
		cost:       "low"
		supersedes: "intent_on_the_pilot"
	}
	deterministic_replay: {
		title:    "Replay a round from its journal"
		question: "Are the decisions of a round a function of what it recorded?"
		method:   "Replay a recorded round: a new round gets the fields of the first one up to the decision, and decides again, without running the candidate again. One round that held, and one refused round."
		status:   "planned"
		cost:     "low"
	}
}

measures: {}

retired: [string]: schema.#Retired
retired: {
	"differential_loop.cases":           {was: "Cases in the corpus: 339 cases.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"differential_loop.accepted":        {was: "Cases accepted by the reference: 154 cases.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"differential_loop.empty":           {was: "Empty candidate, correct valid inputs: 0 of 154.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"differential_loop.first_draft":     {was: "First draft, correct valid inputs: 94 of 154.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"differential_loop.after_one_pass":  {was: "After one pass, correct valid inputs: 114 of 154.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"differential_loop.regressions":     {was: "Regressions in the second round: 8 cases.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"rejection_location.same_path":      {was: "Both reject at the same path: 109 cases.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"rejection_location.different_path": {was: "Both reject at a different path: 32 cases.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"rejection_location.no_path":        {was: "One side gives no path: 26 cases.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"rejection_location.both_reject":    {was: "Both reject: 167 cases.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"time_budget.over_budget":           {was: "Correct cases outside the budget: 4 cases.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"time_budget.median":                {was: "Median time of a case: 53 ms.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"time_budget.p99":                   {was: "99th percentile: 306 ms.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"time_budget.worst":                 {was: "Worst correct case outside the budget: 1490 ms.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"stability.cases":                   {was: "Cases in the corpus: 339 cases.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"stability.unstable":                {was: "With no rule, unstable cases over three runs: 15 cases.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"stability.unstable_not_time":       {was: "With no rule, unstable cases with no too-slow verdict: 0 cases.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"stability.slow_1":                  {was: "With no rule, too slow in the first run: 21 cases.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"stability.slow_2":                  {was: "With no rule, too slow in the second run: 7 cases.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"stability.slow_3":                  {was: "With no rule, too slow in the third run: 6 cases.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"stability.with_rule":               {was: "With the rule, measured runs: 9 runs.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"stability.with_rule_min":           {was: "With the rule, the fewest too-slow cases in a run: 2 cases.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"stability.with_rule_max":           {was: "With the rule, the most too-slow cases in a run: 4 cases.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"stability.under_load":              {was: "Under load, too slow with immediate retry: 303 cases.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"stability.median_min":              {was: "Median time of a case, the lowest of the runs with no load: 49 ms.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"stability.median_max":              {was: "Median time of a case, the highest of the runs with no load: 61 ms.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"autonomous_agent.valid":            {was: "Valid inputs in the corpus: 154 inputs.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"autonomous_agent.start":            {was: "Start, correct valid inputs: 111 of 154.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"autonomous_agent.start_passed":     {was: "Start, passed cases: 243 of 339.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"autonomous_agent.end":              {was: "Opus agent, end, correct valid inputs: 144 of 154.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"autonomous_agent.end_passed":       {was: "Opus agent, end, passed cases: 319 of 339.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"autonomous_agent.first_agent":      {was: "First agent, at the cut: 133 of 154.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"autonomous_agent.gained":           {was: "Cases gained by the Opus agent: 76 cases.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"autonomous_agent.lost":             {was: "Cases lost compared with the start: 0 cases.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"autonomous_agent.crashes_at_end":   {was: "At the end, crashes, timeouts and cases not built: 0 cases.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"judge_in_cue.rounds_decided":       {was: "Complete rounds of the journal decided by cue vet: 23 rounds.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"sonnet_agent.generations":          {was: "Sonnet generations: 6 generations.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"sonnet_agent.cost":                 {was: "Cost of the generations: 1.66 USD.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"sonnet_agent.refusals":             {was: "Rounds refused for a regression: 4 rounds.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"sonnet_agent.same_case":            {was: "Refusals that break the same case as the first one: 3 rounds.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"intent_on_the_pilot.generations":   {was: "Sonnet generations: 2 generations.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"intent_on_the_pilot.cost":          {was: "Cost of the generations: 0.89 USD.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"intent_on_the_pilot.before":        {was: "Before, correct valid inputs: 146 of 154.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"intent_on_the_pilot.after":         {was: "After, correct valid inputs: 149 of 154.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"intent_on_the_pilot.valid":         {was: "Valid inputs in the corpus: 154 inputs.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"intent_on_the_pilot.fixed":         {was: "Cases fixed: 4 cases.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"intent_on_the_pilot.excused":       {was: "Regressions excused by a person: 1 case.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	"deterministic_replay.replays":      {was: "Rounds replayed from their journal: 2 rounds.", why: "Measured on cue-interpreter, dropped on 2026-11-14. The experiment must be run again on the first project."}
	intent_on_the_pilot:                 {was: "An intent declared, kept, then approved, measured on cue-interpreter.", why: "The word pilot no longer names anything, and the experiment must be run again. Replaced by intent_on_a_project."}
	"differential_loop.round_duration":  {was: "Duration of a round: about 12 s, of which 10 s for a case that times out.", why: "The runs of the Go kernel do not keep the duration of a round."}
	"time_budget.three_disjunctions":    {was: "Three of the too-slow cases are cases with disjunctions.", why: "Only 2 of the 4 paths name a disjunction. The content of the cases is not exported."}
	"stability.with_rule_per_run":       {was: "With the rule, 2 too slow in nine runs out of ten, 3 in one.", why: "The runs give 9 runs with the rule: 8 with 2 too slow, 1 with 4."}
	"stability.zero_unstable_four":      {was: "With the rule, zero unstable cases over four runs, load included.", why: "Nothing says which four runs. The 9 runs with the rule range from 2 to 4 too slow."}
	"stability.retry_after_phase":       {was: "Under load -j 32, 2 too slow with retry after the parallel phase.", why: "No exported run says that it runs under load with this retry."}
	"stability.median_56_60":            {was: "Median time of a case: 56 to 60 ms.", why: "The runs with no load give medians from 49 to 61 ms."}
	"autonomous_agent.thirteen_rounds":  {was: "The Opus agent did 13 complete rounds out of the 15 allowed.", why: "The exported runs do not say which round belongs to which agent."}
	"autonomous_agent.round_duration":   {was: "Duration of a round: from 12 s to about 4 s.", why: "The runs of the Go kernel do not keep the duration of a round."}
	"autonomous_agent.hash":             {was: "Hash of the fixed points unchanged.", why: "The hash was printed by the Go kernel, never exported."}
	"judge_in_cue.parity":               {was: "Parity: 337 verdicts of 339 the same as the old judge.", why: "The observations of the time are kept with no verdict: the old judge would have to be replayed."}
	"judge_in_cue.first_sealed_round":   {was: "First sealed round: 145 of 154 correct valid inputs.", why: "This round comes before the Kyo journal. No exported run holds it."}
	"judge_in_cue.round_duration":       {was: "Duration of a round: about 4 s, CUE evaluation included.", why: "This round comes before the Kyo journal. No exported run holds it."}
}
