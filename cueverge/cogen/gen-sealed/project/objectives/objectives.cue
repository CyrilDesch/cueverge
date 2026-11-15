// @what: checks the objectives of the factory. Each state follows from the constraints that serve it, and each objective is served.
// @ref: @/cueverge/sealed/project/objectives/objectives.cue
package objectives

import (
	"github.com/cyrildesch/cueverge/project"
	c "factory.local/kb/sealed/project/constraints"
	o "factory.local/kb/sealed/project/objectives"
)

_rules: project.#ObjectiveRules & {
	sealed:      o
	constraints: c.facts
}

rules:  _rules.rules
served: _rules.served
