// @what: the cogen rule kinds on a small page. Each case must hold. The failing cases are checked by hand in the change that adds a kind.
// @ref: @/tool/cue/kinds/kinds.cue
package test

import (
	"github.com/cyrildesch/cueverge/kinds"
	"github.com/cyrildesch/cueverge/schema"
)

_page: kinds.#Page & {
	source: {url: "https://example.org/a", fetched: "2026-11-14T00:00:00Z", sha256: "00"}
	blocks: [
		{tag: "p", text: "In May, we merged around 2,500 changes per day."},
		{tag: "p", text: "A team of seven people built Scion and Antique in five months."},
	]
}

_sealed: schema.#Sealed & {
	facts: {
		may:     {says: "About 2,500 merges per day in May", holds: true, value: 2500}
		team:    {says: "Seven people built Scion", holds: true, value: 7}
		antique: {says: "The team also built Antique", holds: true}
		sapling: {says: "The page names Sapling", holds: false}
		sum:     {says: "The sum of the two figures", holds: true, value: 2507}
		support: {says: "A conclusion that rests on two facts", holds: true}
		held:    {says: "The sum stays under 3000", holds: true}
		waiting: {says: "A measure that does not exist yet", holds: "unknown"}
	}
	retired: old: {was: "An old wrong figure", why: "not on the page"}
}

cover: kinds.#Cover & {sealed: _sealed, by: {
	may:     kinds.#Number & {page: _page, at: 0, re: "around ([0-9,]+) changes"}
	team:    kinds.#Number & {page: _page, at: 1, re: "team of ([a-z]+) people"}
	antique: kinds.#Mentions & {page: _page, at: 1, terms: ["scion", "antique", "five months"]}
	sapling: kinds.#Absent & {page: _page, term: "Sapling"}
	sum:     kinds.#Computed & {of: _sealed.facts.may.value + _sealed.facts.team.value}
	support: kinds.#Derived & {from: [_sealed.facts.may, _sealed.facts.antique]}
	held:    kinds.#Computed & {holds: _sealed.facts.sum.value < 3000}
	waiting: kinds.#Pending & {action: {status: "to do"}}
}}
