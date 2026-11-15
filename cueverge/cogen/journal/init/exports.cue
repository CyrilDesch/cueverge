// @what: the exports of the init journal, computed from the raw journal by the factory rules.
// @invariant: every export file unifies with what the raw journal gives. The kernel applies it when it writes an export.
@if(journalraw)

package journal

import (
	"github.com/cyrildesch/cueverge/rules"

	g "factory.local/kb/gen/journal/init:journal"
)

// @why: before the first export, the journal has no exports field, and before a Claude trace no traces field.
_g:      {executions: [string]: _, traces: [string]: _, exports: {...}} & g
exports: _g.exports & (rules.#Exports & {executions: _g.executions, traces: _g.traces}).out
