// @what: checks each decision. A settled one rests on tested principles, another names what settles it.
// @invariant: a principle anchors with its own polarity, and only when the principles cogen rules cover it.
// @ref: @/cueverge/sealed/usine/decisions/decisions.cue
// @ref: @/cueverge/cogen/gen-sealed/usine/principles/principles.cue
package decisions

import (
	"github.com/cyrildesch/cueverge/kinds"
	d "factory.local/kb/sealed/usine/decisions"
	"factory.local/kb/sealed/usine/actions"
	ex "factory.local/kb/sealed/usine/experiments"
	"factory.local/kb/sealed/usine/principles"
	prules "factory.local/kb/cogen/gen-sealed/usine/principles"
)

_principle: {for k, p in principles.principles {
	"cue://principles/principles.\(k)": {
		holds: p.holds...
		rule:  prules.rules.covered[k]...
	}
}}
_settler: {
	for k, e in ex.experiments {
		"cue://experiments/experiments.\(k)": e...
	}
	for k, x in actions.actions {
		"cue://actions/actions.\(k)": x...
	}
}

rules: kinds.#Cover & {sealed: d, by: {
	for k, x in d.decisions if x.status == "acté" {
		(k): (kinds.#Derived & {
			from: [for r in x.restsOn {
				_principle[r]...
			}]
		})...
	}
	for k, x in d.decisions if x.status != "acté" {
		(k): (kinds.#Pending & {
			action: _settler[x.settledBy]...
		})...
	}
}}
