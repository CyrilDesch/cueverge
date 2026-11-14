// @what: checks the catalog. A constraint wired on the project is measured on its capture, another awaits its action.
// @invariant: a wired constraint without a measure here fails. Its polarity is computed, never written alone.
// @ref: @/cueverge/sealed/factory/constraints/constraints.cue
package constraints

import (
	"github.com/cyrildesch/cueverge/kinds"
	c "factory.local/kb/sealed/factory/constraints"
	"factory.local/kb/sealed/factory/actions"
)

// @what: the measure of each wired constraint, from the capture of the project. None is wired yet.
_measured: {}

rules: kinds.#Cover & {sealed: c, by: {
	for k, x in c.constraints if x.onProject == "wired" {
		(k): (kinds.#Computed & {
			holds: _measured[k]...
		})...
	}
	for k, x in c.constraints if x.onProject != "wired" {
		(k): (kinds.#Pending & {
			action: actions.actions[x.action]...
		})...
	}
}}
