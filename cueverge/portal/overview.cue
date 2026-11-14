package portal

// @what: the figures of the front page. Every number is computed from the sealed packages.
// @why: an aggregate for the front page, not knowledge. It lives in the portal, so no sealed package holds it.
// @ref: @/cueverge/portal/home.cue

import (
	"list"

	"factory.local/kb/sealed/factory/actions"
	"factory.local/kb/sealed/factory/decisions"
	"factory.local/kb/sealed/factory/experiments"
	"factory.local/kb/sealed/factory/principles"
	"factory.local/kb/sealed/factory/questions"
)

_overview: {
	_done: [for _, e in experiments.experiments if e.status == "done" {
		e...
	}]
	_tested: [for _, p in principles.principles if p.status == "tested on a project" {
		p...
	}]
	_decisive: [for _, q in questions.questions if q.weight == "decides everything" if q.status == "open" {
		q...
	}]
	_pending: [for _, d in decisions.decisions if d.status == "to confirm" {
		d...
	}]

	notice: [{
		text: "**The experiments must be run again on the first project.** The first example, cue-interpreter, is dropped. The first project is a fork of Mistral Vibe that replaces the shell of the agent with Tacit, typed capabilities that the compiler checks. Until it has run, the base states no measure."
		tone: "high"
	}]

	thesis: "The human writes a problem and constraints, and approves the intent of the changes. Agents that own their resources write all the code. A deterministic loop observes the system at its boundaries, continuously, and compares it with its previous version by rules written beforehand. The rules can only tighten; loosening needs a human."

	metrics: [
		{label: "First project", hint: "Mistral Vibe with Tacit", value: actions.actions.set_up_the_first_project.status, detail: "set up by cueverge init", tone: "info"},
		{label: "Principles tested", hint: "on a project", value: "\(len(_tested)) / \(len(principles.principles))", detail: "the others are stated with no measure", tone: "info"},
		{label: "Experiments done", hint: "with their figures", value: "\(len(_done)) / \(len(experiments.experiments))", tone: "accepted"},
		{label: "Decisive questions", hint: "with no answer", value: "\(len(_decisive))", tone: "high"},
		{label: "Decisions to confirm", value: "\(len(_pending))", tone: "info"},
	]

	next: list.Take(list.Sort([for k, a in actions.actions if a.status != "done" {
		order:   a.order
		title:   a.title
		measure: a.measure
		verdict: a.verdict
		cost:    a.cost
		key:     k
		ref:     "cue://actions/actions.\(k)"
	}], {x: _, y: _, less: x.order < y.order}), 3)

	decisive: [for k, q in questions.questions if q.weight == "decides everything" if q.status == "open" {
		question:     q.question
		whyItMatters: q.whyItMatters
		key:          k
		ref:          "cue://questions/questions.\(k)"
	}]

	measured: [for k, e in experiments.experiments if e.status == "done" {
		title:  e.title
		result: e.result
		limit:  e.limits[0]
		key:    k
		ref:    "cue://experiments/experiments.\(k)"
	}]
}
