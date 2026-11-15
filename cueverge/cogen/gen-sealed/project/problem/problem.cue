// @what: the problem of the factory is the exact text of a problem that a person approved, in the init journal.
// @ref: @/cueverge/sealed/project/problem/problem.cue
// @ref: @/cueverge/gen/journal/init
package problem

import (
	"github.com/cyrildesch/cueverge/project"
	s "factory.local/kb/sealed/project/problem"
	g "factory.local/kb/gen/journal/init:journal"
)

rules: (project.#ProblemRules & {
	sealed:   s
	approved: [for _, e in g.exports.executions if e.approval != _|_ {e.problem}]
}).rules
