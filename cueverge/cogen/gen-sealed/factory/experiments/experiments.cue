// @what: checks the experiments. A done one rests on its measures, a planned one on an action not done, a discarded one is cited by none.
// @invariant: every measure is computed from a capture of the project it was measured on. None exists yet, so no measure is sealed.
// @ref: @/cueverge/sealed/factory/experiments/experiments.cue
package experiments

import (
	"regexp"
	"strconv"
	"strings"

	"github.com/cyrildesch/cueverge/kinds"
	ex "factory.local/kb/sealed/factory/experiments"
	"factory.local/kb/sealed/factory/actions"
	"factory.local/kb/sealed/factory/principles"
	"factory.local/kb/sealed/factory/questions"
)

// @what: the value of each measure, computed from the captures in gen. Empty until the first project is captured.
_of: {}

// @what: who cites an experiment, as evidence, as an answer, or as a run of an action.
_citedBy: {
	for k, p in principles.principles if p.evidence != _|_ for x in p.evidence {(strings.TrimPrefix(x, "cue://experiments/experiments.")): "principles.\(k)": true}
	for k, q in questions.questions if q.answeredBy != _|_ for x in q.answeredBy {(strings.TrimPrefix(x, "cue://experiments/experiments.")): "questions.\(k)": true}
	for k, a in actions.actions if a.runs != _|_ for x in a.runs {(strings.TrimPrefix(x, "cue://experiments/experiments.")): "actions.\(k)": true}
}
_runners: {for k, a in actions.actions if a.runs != _|_ for x in a.runs {
	(strings.TrimPrefix(x, "cue://experiments/experiments.")): {
		(k): a...
	}
}}

rules: kinds.#Cover & {sealed: ex, by: {
	for k, _ in ex.measures {
		(k): (kinds.#Computed & {
			of: _of[k]...
		})...
	}
	for k, e in ex.experiments if e.status == "done" {
		(k): (kinds.#Derived & {
			from: [for m in ex.measures if m.experiment == k {
				m...
			}]
		})...
	}
	for k, e in ex.experiments if e.status == "planned" {
		(k): (kinds.#Pending & {
			action: [for _, a in _runners[k] if a.status != "done" {
				a...
			}][0]...
		})...
	}
	for k, e in ex.experiments if e.status == "discarded" || e.status == "stopped" {
		(k): (kinds.#Discarded & {
			citedBy: [for c, _ in [if _citedBy[k] != _|_ {
				_citedBy[k]...
			}, {}][0] {
				c...
			}]
		})...
	}
}}

// @what: the numbers a result states, written with digits. Thousands may be split by a comma, decimals use a point.
_number: "(?:^|[^0-9A-Za-z_])([0-9]+(?:,[0-9]{3})*(?:\\.[0-9]+)?)(?:$|[^0-9A-Za-z_])"

// @invariant: every number a result states is the value of a measure of its experiment.
stated: {for k, e in ex.experiments if e.result != _|_ {
	let Values = [for m in ex.measures if m.experiment == k {
		m.value...
	}]
	(k): {for x in [for g in [if regexp.Match(_number, e.result) {regexp.FindAllSubmatch(_number, e.result, -1)}, []][0] {
		g[1]...
	}] {
		let N = strconv.ParseFloat(strings.Replace(x, ",", "", -1), 64)
		(x): len([for v in Values if v == N {
			v...
		}]) > 0 & true
	}}
}}

// @invariant: every computation here checks a sealed measure. A computation with no measure is a rule without a fact.
computedOnly: {for k, _ in _of {
	(k): ex.measures[k].kind...
}}
