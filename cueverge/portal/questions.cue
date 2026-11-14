package portal

import "factory.local/kb/sealed/factory/questions"

_weights:     ["decides everything", "important", "secondary"]
_weightTitle: {"decides everything": "Decides everything", "important": "Important", "secondary": "Secondary"}

// @what: the questions page. One group per weight, the decisive ones first.
questionsPage: {
	slug:  "questions"
	title: "Open questions"
	description: "\(len([for _, q in questions.questions if q.status == "open" {
		q...
	}])) questions with no answer and \(len([for _, q in questions.questions if q.status == "resolved" {
		q...
	}])) resolved, from the heaviest to the lightest. An open question names the experiment or the action that will answer it."
	footer: "Generated from the package `questions` at build time."
	blocks: [
		{
			stats: [for w in _weights {
				label: w
				value: len([for _, q in questions.questions if q.weight == w {
					q...
				}])
				tone: _tone[w]
			}]
		},
		{filter: {facet: "weight", label: "Weight", options: _weights}},
		for w in _weights {
			group: {
				title: _weightTitle[w]
				blocks: [{
					cards: [for k, q in questions.questions if q.weight == w {
						title: q.question
						href:  _href.question[k]
						tone:  _tone[q.weight]
						md:    q.whyItMatters
						badges: [
							if q.status == "resolved" {{badge: "resolved", tone: "accepted"}},
							if q.answeredBy == _|_ {{badge: "no experiment", tone: "muted"}},
						]
						facets: weight: q.weight
					}]
				}]
			}
		},
	]
	pages: [for k, q in questions.questions {
		(#QuestionPage & {
			#key: k...

			#q: q...
		}).out...
	}]
}

#QuestionPage: {
	#key: string
	#q:   questions.#Question
	let K = #key
	out: {
		slug:   (#Slug & {#key: K}).out
		title:  #q.question
		hidden: true
		blocks: [
			{stats: [{label: "Weight", value: #q.weight, tone: _tone[#q.weight]}, {label: "Status", value: #q.status}]},
			{group: {title: "Why it matters", blocks: [{md: #q.whyItMatters}]}},
			{
				group: {title: "Experiment that answers it", blocks: [
					if #q.answeredBy != _|_ {
						md: (#Links & {
							#kind: "experiment"
							#refs: #q.answeredBy...

							#title: _title.experiment...
						}).out
					},
					if #q.answeredBy == _|_ {hint: {style: "warning", md: "No experiment answers this question yet."}},
				]}
			},
			{
				group: {title: "Actions that answer it", blocks: [
					if _actionsAnswering[#key] != _|_ {
						md: (#Links & {
							#kind: "action"
							#refs: [for k, _ in _actionsAnswering[#key] {_prefix.action + k}]

							#title: _title.action...
						}).out
					},
					if _actionsAnswering[#key] == _|_ {hint: {style: "warning", md: "No action targets this question yet."}},
				]}
			},
		]
		footer: "Source: `questions.questions.\(#key)`."
	}
}
