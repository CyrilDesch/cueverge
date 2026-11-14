// @what: checks the constraints of the factory. Each measure is computed from the capture of a project, or awaits its action.
// @invariant: a constraint or a measure with no capture yet is unknown and names an action not done.
// @ref: @/cueverge/sealed/usine/system/system.cue
package system

import (
	"github.com/cyrildesch/cueverge/kinds"
	sy "factory.local/kb/sealed/usine/system"
	"factory.local/kb/sealed/usine/actions"
)

rules: kinds.#Cover & {sealed: sy, by: {
	for k, f in sy.facts if f.holds == "inconnu" {
		(k): (kinds.#Pending & {
			action: actions.actions[f.action]...
		})...
	}
}}

// @invariant: a measure shown with a constraint exists, and is a measure.
shown: {for k, f in sy.facts if f.with != _|_ for m in f.with {
	"\(k).\(m)": (sy.facts[m].kind & "mesure")...
}}
