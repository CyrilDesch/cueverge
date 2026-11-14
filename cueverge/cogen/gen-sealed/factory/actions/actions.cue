// @what: checks each action against the experiments it runs. A done action rests on them, an action not done awaits one.
// @invariant: done needs at least one experiment, all done. Not done, with experiments, leaves at least one not done.
// @ref: @/cueverge/sealed/factory/actions/actions.cue
package actions

import (
	"github.com/cyrildesch/cueverge/kinds"
	a "factory.local/kb/sealed/factory/actions"
	ex "factory.local/kb/sealed/factory/experiments"
)

_experiment: {for k, e in ex.experiments {
	"cue://experiments/experiments.\(k)": e...
}}
_runs: {for k, x in a.actions {
	(k): [for r in [if x.runs != _|_ {
		x.runs...
	}, []][0] {
		_experiment[r]...
	}]
}}

rules: kinds.#Cover & {sealed: a, by: {
	for k, x in a.actions if x.status == "done" {
		(k): (kinds.#Derived & {
			from: _runs[k]...
		})...
	}
	for k, x in a.actions if x.status != "done" {
		(k): (kinds.#Pending & {
			action: x...
		})...
	}
}}

// @invariant: an action not done that runs experiments still has one to run.
unfinished: {for k, x in a.actions if x.status != "done" if len(_runs[k]) > 0 {
	(k): len([for e in _runs[k] if e.status != "done" {
		e...
	}]) > 0 & true
}}
