// @what: checks each principle against the experiments and actions. Tested rests on done experiments, untested on a test to run.
// @invariant: a principle is intent. Nothing here reads a raw source, only other sealed facts.
// @ref: @/cueverge/sealed/usine/principles/principles.cue
package principles

import (
	"github.com/cyrildesch/cueverge/kinds"
	p "factory.local/kb/sealed/usine/principles"
	"factory.local/kb/sealed/usine/actions"
	ex "factory.local/kb/sealed/usine/experiments"
)

_ref: {
	for k, e in ex.experiments {
		"cue://experiments/experiments.\(k)": e...
	}
	for k, x in actions.actions {
		"cue://actions/actions.\(k)": x...
	}
}

rules: kinds.#Cover & {sealed: p, by: {
	for k, x in p.principles if x.status == "testé sur un projet" {
		(k): (kinds.#Derived & {
			from: [for e in x.evidence {
				_ref[e]...
			}]
		})...
	}
	for k, x in p.principles if x.status == "posé, non testé" {
		(k): (kinds.#Pending & {
			action: _ref[x.testedBy]...
		})...
	}
}}
