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
		mai:     {says: "Environ 2 500 fusions par jour en mai", holds: true, value: 2500}
		equipe:  {says: "Sept personnes ont fait Scion", holds: true, value: 7}
		antique: {says: "Antique fait partie de l'équipe", holds: true}
		sapling: {says: "La page nomme Sapling", holds: false}
		somme:   {says: "La somme des deux chiffres", holds: true, value: 2507}
		appui:   {says: "Une conclusion qui repose sur deux faits", holds: true}
		tenue:   {says: "La somme reste sous 3000", holds: true}
		attente: {says: "Une mesure qui n'existe pas encore", holds: "inconnu"}
	}
	retired: ancien: {was: "Un ancien chiffre faux", why: "absent de la page"}
}

cover: kinds.#Cover & {sealed: _sealed, by: {
	mai:     kinds.#Number & {page: _page, at: 0, re: "around ([0-9,]+) changes"}
	equipe:  kinds.#Number & {page: _page, at: 1, re: "team of ([a-z]+) people"}
	antique: kinds.#Mentions & {page: _page, at: 1, terms: ["scion", "antique", "five months"]}
	sapling: kinds.#Absent & {page: _page, term: "Sapling"}
	somme:   kinds.#Computed & {of: _sealed.facts.mai.value + _sealed.facts.equipe.value}
	appui:   kinds.#Derived & {from: [_sealed.facts.mai, _sealed.facts.antique]}
	tenue:   kinds.#Computed & {holds: _sealed.facts.somme.value < 3000}
	attente: kinds.#Pending & {action: {status: "à faire"}}
}}
