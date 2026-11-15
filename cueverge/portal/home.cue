package portal

import (
	"strings"

	"factory.local/kb/sealed/project/problem"
)

// @what: the front page. The problem, what is not proven, the key figures, what was measured, what decides, what comes next.
// @invariant: every figure comes from the front page aggregate, never written here.
// @ref: @/cueverge/portal/overview.cue
homePage: {
	slug:        "home"
	title:       "Overview"
	description: problem.facts.problem.says
	footer:      "Figures computed at build time from the packages `experiments`, `principles`, `questions`, `decisions` and `actions`."
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
				title: "What was measured"
				blocks: [{
					cards: [for e in _overview.measured {
						title: e.title
						href:  _href.experiment[e.key]
						tone:  "accepted"
						md:    "\(e.result)\n\n> **What it does not show.** \(e.limit)"
					}]
				}]
			}
		},
		{
			group: {
				title: "What decides everything"
				blocks: [
					{md: "Three questions with no answer. Each one can invalidate the approach."},
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
				title: "The next three actions"
				blocks: [
					{
						steps: [for a in _overview.next {
							title:  "\(a.title)"
							blocks: [{md: "**Measure.** \(a.measure)\n\n**Verdict.** \(a.verdict)\n\nCost: \(a.cost) · [Read the action](\(_href.action[a.key]))"}]
						}]
					},
					{md: "[All the actions, in order](/actions/)"},
				]
			}
		},
	]
}
