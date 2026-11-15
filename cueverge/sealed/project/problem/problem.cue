// @what: the problem of the factory, as a person stated it and approved it at cueverge init.
// @invariant: a person edits the problem. Its rule finds this exact text in an approved init of the journal.
// @ref: @/cueverge/cogen/gen-sealed/project/problem/problem.cue
package problem

import "github.com/cyrildesch/cueverge/project"

project.#ProblemPackage

facts: problem: {
	says:         "The goal of cueverge is to be a semi-autonomous software factory with no bottleneck. Its entry point is objectives and constraints, which can express any kind of test to validate the state of the software."
	holds:        true
	attributedTo: "a person, at cueverge init, draft 63b1bfb05284"
}

retired: {}
