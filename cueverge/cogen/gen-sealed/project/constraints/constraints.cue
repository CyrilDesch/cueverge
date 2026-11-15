// @what: checks the constraints of the factory. A constraint that a round measures takes its verdict, any other is unknown.
// @invariant: no round exports a verdict per constraint yet, so every constraint is unknown.
// @ref: @/cueverge/sealed/project/constraints/constraints.cue
package constraints

import (
	"github.com/cyrildesch/cueverge/project"
	c "factory.local/kb/sealed/project/constraints"
	o "factory.local/kb/sealed/project/objectives"
)

_rules: project.#ConstraintRules & {
	sealed:     c
	objectives: o.facts
	// @todo: the verdict of each constraint, from the exports of the rounds, once a round measures the constraints.
	measured: {}
}

rules:  _rules.rules
serves: _rules.serves
