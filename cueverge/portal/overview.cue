package portal

// @what: the figures of the front page. Every number is computed from the sealed packages.
// @why: an aggregate for the front page, not knowledge. It lives in the portal, so no sealed package holds it.
// @ref: @/cueverge/portal/accueil.cue

import (
	"list"

	"factory.local/kb/sealed/usine/actions"
	"factory.local/kb/sealed/usine/decisions"
	"factory.local/kb/sealed/usine/experiments"
	"factory.local/kb/sealed/usine/principles"
	"factory.local/kb/sealed/usine/questions"
)

_overview: {
	_done: [for _, e in experiments.experiments if e.status == "fait" {
		e...
	}]
	_tested: [for _, p in principles.principles if p.status == "testé sur un projet" {
		p...
	}]
	_decisive: [for _, q in questions.questions if q.weight == "décide de tout" if q.status == "ouverte" {
		q...
	}]
	_pending: [for _, d in decisions.decisions if d.status == "à confirmer" {
		d...
	}]

	notice: [{
		text: "**Les expériences sont à refaire sur le premier projet.** Le premier exemple, cue-interpreter, est abandonné. Le premier projet est un fork de Mistral Vibe qui remplace le shell de l'agent par Tacit, des capacités typées que le compilateur vérifie. Tant qu'il n'a pas tourné, la base n'affirme aucune mesure."
		tone: "high"
	}]

	thesis: "L'humain écrit une problématique et des contraintes, et approuve l'intention des changements. Des agents propriétaires de leurs ressources écrivent tout le code. Une boucle déterministe observe le système aux frontières, en continu, et le compare à sa version précédente selon des règles écrites avant. Les règles ne peuvent que se resserrer ; relâcher demande un humain."

	metrics: [
		{label: "Premier projet", hint: "Mistral Vibe avec Tacit", value: actions.actions.monter_le_premier_projet.status, detail: "monté par cueverge init", tone: "info"},
		{label: "Principes testés", hint: "sur un projet", value: "\(len(_tested)) / \(len(principles.principles))", detail: "les autres sont posés sans mesure", tone: "info"},
		{label: "Expériences faites", hint: "avec leurs chiffres", value: "\(len(_done)) / \(len(experiments.experiments))", tone: "accepted"},
		{label: "Questions décisives", hint: "sans réponse", value: "\(len(_decisive))", tone: "high"},
		{label: "Décisions à confirmer", value: "\(len(_pending))", tone: "info"},
	]

	next: list.Take(list.Sort([for k, a in actions.actions if a.status != "fait" {
		order:   a.order
		title:   a.title
		measure: a.measure
		verdict: a.verdict
		cost:    a.cost
		key:     k
		ref:     "cue://actions/actions.\(k)"
	}], {x: _, y: _, less: x.order < y.order}), 3)

	decisive: [for k, q in questions.questions if q.weight == "décide de tout" if q.status == "ouverte" {
		question:     q.question
		whyItMatters: q.whyItMatters
		key:          k
		ref:          "cue://questions/questions.\(k)"
	}]

	measured: [for k, e in experiments.experiments if e.status == "fait" {
		title:  e.title
		result: e.result
		limit:  e.limits[0]
		key:    k
		ref:    "cue://experiments/experiments.\(k)"
	}]
}
