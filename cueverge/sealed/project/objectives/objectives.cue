// @what: what the factory must achieve, as a person approved it at cueverge init. Each state follows from the constraints.
// @invariant: an objective is intent. Its rule computes its state from the constraints that serve it.
// @ref: @/cueverge/cogen/gen-sealed/project/objectives/objectives.cue
package objectives

import "github.com/cyrildesch/cueverge/project"

project.#ObjectivesPackage

facts: {
	autonomy: {
		says:  "The factory builds and changes software by itself, and a person only sets the objectives and constraints."
		why:   "The people who own a project should not have to review each step, so work keeps moving."
		holds: "unknown"
	}
	no_bottleneck: {
		says:  "No single step, agent or person blocks the flow of work in the factory."
		why:   "A blocked step stops the whole factory, so throughput and delivery speed fall for every project."
		holds: "unknown"
	}
	expressive_tests: {
		says:  "Objectives and constraints can express any kind of test that validates the state of the software."
		why:   "A person can only trust the factory if every property they care about can be checked by a machine."
		holds: "unknown"
	}
}

retired: {}
