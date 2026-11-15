// @what: the properties every change of the factory must keep, as a person approved them at cueverge init, and how a round measures them.
// @invariant: a constraint with no verdict from a round is unknown. Its rule says that no round measures it yet.
// @ref: @/cueverge/cogen/gen-sealed/project/constraints/constraints.cue
package constraints

import "github.com/cyrildesch/cueverge/project"

project.#ConstraintsPackage

facts: {
	every_rule_is_cue: {
		says:    "Every rule of judgement is written in CUE, and the kernel holds no rule."
		measure: "Run cue vet -c ./... in cueverge and in tool/cue, and it must exit with code 0."
		serves:  ["expressive_tests", "autonomy"]
		holds:   "unknown"
	}
	every_check_is_runnable: {
		says:    "Every constraint carries a measure that a machine can run without a person."
		measure: "A round of tests runs the measure of each constraint and records a pass or a fail, with no manual step."
		serves:  ["autonomy", "no_bottleneck"]
		holds:   "unknown"
	}
}

retired: {}
