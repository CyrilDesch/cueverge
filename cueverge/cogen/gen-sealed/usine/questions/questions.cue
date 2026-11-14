// @what: checks each question against what answers it. Open awaits an experiment or an action, resolved rests on done experiments.
// @invariant: what answers an open question is its experiments and the actions that name it. One of them is not done.
// @ref: @/cueverge/sealed/usine/questions/questions.cue
package questions

import (
	"list"
	"strings"

	"github.com/cyrildesch/cueverge/kinds"
	q "factory.local/kb/sealed/usine/questions"
	"factory.local/kb/sealed/usine/actions"
	ex "factory.local/kb/sealed/usine/experiments"
)

_experiment: {for k, e in ex.experiments {
	"cue://experiments/experiments.\(k)": e...
}}
_actions: {for k, x in actions.actions if x.answers != _|_ for r in x.answers {
	(strings.TrimPrefix(r, "cue://questions/questions.")): {
		(k): x...
	}
}}
_answering: {for k, x in q.questions {
	(k): list.Concat([
		[for r in [if x.answeredBy != _|_ {
			x.answeredBy...
		}, []][0] {
			_experiment[r]...
		}],
		[for _, y in [if _actions[k] != _|_ {
			_actions[k]...
		}, {}][0] {
			y...
		}],
	])
}}

rules: kinds.#Cover & {sealed: q, by: {
	for k, x in q.questions if x.status == "résolue" {
		(k): (kinds.#Derived & {
			from: [for r in x.answeredBy {
				_experiment[r]...
			}]
		})...
	}
	for k, x in q.questions if x.status == "ouverte" {
		(k): (kinds.#Pending & {
			action: [for y in _answering[k] if y.status != "fait" {
				y...
			}][0]...
		})...
	}
}}

// @invariant: nothing that answers a resolved question is still to do.
settled: {for k, x in q.questions if x.status == "résolue" {
	(k): len([for y in _answering[k] if y.status != "fait" {
		y...
	}]) & 0
}}
