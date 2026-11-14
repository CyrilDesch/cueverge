// @what: the decision. A round holds if the meet of observations, rules and seal is not bottom.
// @invariant: no regression is a meet. A case that passed in the last sealed round must unify with passes.
// @why: this is monotone. Loosening a rule here or in the judge passes in silence, so a person reviews that edit.
package rules

import (
	"list"
	"strings"
)

#NoRegression: {
	verdicts: [string]: #Verdict
	sealed: [string]:   #Verdict
	// @what: the regressions a person approved in an intent. The one loosening of the seal, opened only by that approval.
	excused: [...string] | *[]
	kept:    {for k, v in sealed if list.Contains(passing, v) && !list.Contains(excused, k) {(k): (verdicts[k] & #Passes)...}}
}

// @what: the last round that sealed, read from the exports of a journal. A project checks its seal against it, the factory reads its captures with
// @what: it.
// @invariant: a replay decides again and never seals, so it never counts.
#LastSeal: {
	executions: [string]: {...}
	let Sealing = [for id, e in executions
	if e.flow == "round"
	if e.decision.holds
	if !strings.Contains(id, "-replay-") {
		execution: id
		completed: e.completed
		summary:   e.summary
		verdicts:  e.verdicts
	}]

	// @what: absent while no round has sealed.
	if len(Sealing) > 0 {out: list.Sort(Sealing, {x: _, y: _, less: x.completed < y.completed})[len(Sealing)-1]}
}

// @what: the last generation of a journal, the one whose intent the initiative holds until a round seals.
#LastGeneration: {
	executions: [string]: {...}
	let Generations = list.Sort([for _, e in executions if e.flow == "generate" {
		e...
	}], {x: _, y: _, less: x.completed < y.completed})
	if len(Generations) > 0 {out: Generations[len(Generations)-1]}
}
