package portal

import "strings"

// @what: the front page. The thesis, what is not proven, the key figures, what was measured, what decides, what comes next.
// @invariant: every figure comes from the front page aggregate, never written here.
// @ref: @/cueverge/portal/overview.cue
accueil: {
	slug:        "accueil"
	title:       "Vue d'ensemble"
	description: _overview.thesis
	footer:      "Chiffres calculés au build depuis les paquets `experiments`, `principles`, `questions`, `decisions` et `actions`."
	blocks: [
		for n in _overview.notice {hint: {style: "danger", md: n.text}},
		{
			stats: [for m in _overview.metrics {
				label: m.label
				value: m.value
				if m.tone != _|_ {tone: m.tone}
				let Parts = [if m.hint != _|_ {
					m.hint...
				}, if m.detail != _|_ {
					m.detail...
				}]
				if len(Parts) > 0 {md: strings.Join(Parts, " · ")}
			}]
		},
		// @why: with no experiment done, the group is left out, since the site refuses an empty one.
		if len(_overview.measured) > 0 {
			group: {
				title: "Ce qui a été mesuré"
				blocks: [{
					cards: [for e in _overview.measured {
						title: e.title
						href:  _href.experiment[e.key]
						tone:  "accepted"
						md:    "\(e.result)\n\n> **Ce que ça ne montre pas.** \(e.limit)"
					}]
				}]
			}
		},
		{
			group: {
				title: "Ce qui décide de tout"
				blocks: [
					{md: "Trois questions sans réponse. Chacune peut invalider l'approche."},
					{
						cards: [for q in _overview.decisive {
							title: q.question
							href:  _href.question[q.key]
							tone:  "high"
							md:    q.whyItMatters
						}]
					},
				]
			}
		},
		{
			group: {
				title: "Les trois prochaines actions"
				blocks: [
					{
						steps: [for a in _overview.next {
							title:  "\(a.title)"
							blocks: [{md: "**Mesure.** \(a.measure)\n\n**Verdict.** \(a.verdict)\n\nCoût : \(a.cost) · [Lire l'action](\(_href.action[a.key]))"}]
						}]
					},
					{md: "[Toutes les actions, dans l'ordre](/actions/)"},
				]
			}
		},
	]
}
