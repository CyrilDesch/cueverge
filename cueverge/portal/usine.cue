package portal

import (
	"list"
	"strings"

	"factory.local/kb/sealed/usine/system"
)

// @what: each constraint of the factory with its status and its measures, as sealed facts state them.
// @invariant: no status is written here. It is the polarity of the fact, which the system cogen rules recompute.
_constraint: {for k, f in system.facts if f.kind == "contrainte" {
	(k): {
		fact:   f...
		status: [if f.holds == true {"tenue"}, if f.holds == false {"non tenue"}, "pas mesurée"][0]...
		_with: [for m in [if f.with != _|_ {
			f.with...
		}, []][0] {let M = system.facts[m]
			"\(M.says) : \(M.value) \(M.unit)"
		}]
		if f.value != _|_ {shown: strings.Join(list.Concat([["\(f.value) \(f.unit)"], _with]), " ; ")}
	}
}}

usinePage: {
	slug:        "contraintes-de-l-usine"
	title:       "Contraintes de l'usine"
	description: "Ce qui empêche de perdre le travail des agents, et ce qui garde le juge assez rapide et stable. Chaque valeur est un fait scellé, recalculé à partir du journal."
	footer:      "Une contrainte « pas mesurée » nomme l'action qui construira sa mesure, et cette action n'est pas faite."
	blocks: [
		{
			stats: [for st in ["tenue", "non tenue", "pas mesurée"] {
				label: st
				value: len([for _, c in _constraint if c.status == st {
					c...
				}])
				tone: _tone[st]
			}]
		},
		{
			cards: [for k, c in _constraint {
				title: c.fact.title
				tone:  _tone[c.status]
				badges: [(#Badge & {
					#v: c.status...
				}).out, {
					badge: c.fact.family...
					tone:  "info"
				}]
				md: c.fact.says + "\n\n" + [if c.shown != _|_ {"**Mesure.** \(c.shown)"}, "**Mesure.** \(c.fact.measure)"][0] + "\n\n*Pourquoi.* \(c.fact.why)"
			}]
		},
	]
}
