// @what: what is not known yet. An open question is unknown. A resolved one rests on the experiment that answered it.
// @invariant: an open question names an experiment or an action that will answer it, not done yet. Its rule checks it.
// @ref: @/cueverge/cogen/gen-sealed/factory/questions/questions.cue
package questions

import (
	"github.com/cyrildesch/cueverge/schema"
	"factory.local/kb/sealed/factory/experiments"
)

#ExperimentRef: or([for k, _ in experiments.experiments {"cue://experiments/experiments.\(k)"}])

#Question: {
	schema.#Fact...
	_humanize:    question
	question:     string
	says:         question
	whyItMatters: string
	answeredBy?:  [...#ExperimentRef]
	weight:       "decides everything" | "important" | "secondary"
	status:       "open" | "resolved"

	// @invariant: open is unknown. Resolved holds, and names the experiments that answered it.
	if status == "open" {holds: "unknown"}
	if status == "resolved" {
		holds:       true
		answeredBy!: [_, ...]
	}
}

questions: [string]: #Question

// @what: every sealed fact of the package.
facts: {for k, q in questions {
	(k): q...
}}
retired: [string]: schema.#Retired
retired: {
	without_compilation: {was: "What exactly does no compilation mean for the interpreter?", why: "Specific to cue-interpreter, dropped on 2026-11-14."}
}

questions: {
	agent_convergence: {
		question:     "Does an agent alone converge on the loop, in a reproducible way?"
		whyItMatters: "It is the central hypothesis of the factory. It also needs reproducibility, orchestration by a table, and the case with no oracle."
		answeredBy:   ["cue://experiments/experiments.autonomous_agent"]
		weight:       "decides everything"
		status:       "open"
	}
	without_oracle: {
		question:     "What are partial oracles worth when there is no reference?"
		whyItMatters: "A complete oracle is rare. If the laws and the previous version catch only a small share of the bugs, the factory does not hold without review."
		answeredBy:   ["cue://experiments/experiments.order_law"]
		weight:       "decides everything"
		status:       "open"
	}
	what_cue_brings: {
		question:     "Where does CUE bring more than a configuration format?"
		whyItMatters: "It is the first ambition: co-generation. Generation is stochastic, extraction and the meeting of constraints are deterministic. The judge is designed as a meeting of constraints, where a regression is a unification conflict. The base also checks its own facts: a fact is declared, generated, or refused. What remains is the gate against loosening a rule, and the constraints that state an absence."
		answeredBy:   ["cue://experiments/experiments.judge_in_cue", "cue://experiments/experiments.fixed_points"]
		weight:       "decides everything"
		status:       "open"
	}

	sealing_authority: {
		question:     "Who seals a version?"
		whyItMatters: "Braid consumes the decision, it does not make it. The judge alone, or the judge plus a human for what loosens a rule?"
		answeredBy:   ["cue://experiments/experiments.braid_as_state"]
		weight:       "important"
		status:       "open"
	}
	intent_grain: {
		question:     "At what grain does the human approve an intent?"
		whyItMatters: "Per round, the human becomes the bottleneck: Scion, the source control system of Anthropic, handles more than 30,000 merges per day, and its engineers review the intent, not each line. Per initiative, a broad intent covers rounds that the human did not see. Lead: per initiative in auto mode, per round as soon as a regression is announced or a rule is touched."
		weight:       "important"
		status:       "open"
	}
	task_identity: {
		question:     "How do we give a task a stable identity, computed from the state?"
		whyItMatters: "Too fine, and two agents fix the same bug under two names. An earlier study shows that a deterministic grouping by root cause does not hold."
		weight:       "important"
		status:       "open"
	}
	kernel_abstraction: {
		question:     "Does the kernel serve an initiative of another nature, such as mathematics?"
		whyItMatters: "Only the differential JSON judge exists."
		answeredBy:   ["cue://experiments/experiments.kernel_functor"]
		weight:       "important"
		status:       "open"
	}
	measurable_taste: {
		question:     "Does the cost of change really tell two correct solutions apart?"
		whyItMatters: "If the difference is zero, the automatic taste criterion is of no use."
		answeredBy:   ["cue://experiments/experiments.two_variants"]
		weight:       "important"
		status:       "open"
	}
	verdict_stability: {
		question:     "Are the verdicts of a project stable from one run to the next?"
		whyItMatters: "An unstable verdict makes it impossible to define done as a fixed point."
		answeredBy:   ["cue://experiments/experiments.stability"]
		weight:       "important"
		status:       "open"
	}
	unmeasurable_constraints: {
		question:     "What do we do with the constraints that we cannot measure?"
		whyItMatters: "An error message that lets the user fix the problem alone, an alert understood at three in the morning: a judgement, not a measure."
		weight:       "secondary"
		status:       "open"
	}
	passing_by_accident: {
		question:     "Must a case that passes by accident block a correct fix?"
		whyItMatters: "A correct fix can break a case that passed for a wrong reason. The no-regression rule then protects an error. We need a way to amend, decided by a person: a regression announced in an approved intent."
		answeredBy:   ["cue://experiments/experiments.intent_on_a_project"]
		weight:       "important"
		status:       "open"
	}
	bypassable_budget: {
		question:     "What must the budget bound: the rounds, or the total evaluation?"
		whyItMatters: "Filtered rounds do not count and can cover almost the whole corpus. An agent could use them without saying so."
		weight:       "secondary"
		status:       "open"
	}
	time_threshold: {
		question:     "What does the judge do with a case whose time equals the budget?"
		whyItMatters: "A case whose real time equals the budget flips from one run to the next. A single flip reads as a regression and gets the round refused. Possible choices: a tolerance margin, or keep the previous verdict in a band around the threshold."
		weight:       "important"
		status:       "open"
	}
	oracle_access: {
		question:     "Is the agent allowed to query the oracle by hand?"
		whyItMatters: "A rule can forbid the candidate to call the reference without forbidding the agent to use it to learn. With no oracle, this help goes away, and the result may depend on it."
		weight:       "important"
		status:       "open"
	}
}
