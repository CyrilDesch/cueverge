package portal

import "factory.local/kb/sealed/usine/questions"

_weights:     ["décide de tout", "important", "secondaire"]
_weightTitle: {"décide de tout": "Décide de tout", "important": "Important", "secondaire": "Secondaire"}

// @what: the questions page. One group per weight, the decisive ones first.
questionsPage: {
	slug:  "questions"
	title: "Questions ouvertes"
	description: "\(len([for _, q in questions.questions if q.status == "ouverte" {
		q...
	}])) questions sans réponse et \(len([for _, q in questions.questions if q.status == "résolue" {
		q...
	}])) résolues, de la plus lourde à la plus légère. Une question ouverte nomme l'expérience ou l'action qui y répondra."
	footer: "Généré depuis le paquet `questions` au build."
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
		{filter: {facet: "weight", label: "Poids", options: _weights}},
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
							if q.status == "résolue" {{badge: "résolue", tone: "accepted"}},
							if q.answeredBy == _|_ {{badge: "aucune expérience", tone: "muted"}},
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
			{stats: [{label: "Poids", value: #q.weight, tone: _tone[#q.weight]}, {label: "Statut", value: #q.status}]},
			{group: {title: "Pourquoi elle compte", blocks: [{md: #q.whyItMatters}]}},
			{
				group: {title: "Expérience qui y répond", blocks: [
					if #q.answeredBy != _|_ {
						md: (#Links & {
							#kind: "experiment"
							#refs: #q.answeredBy...

							#title: _title.experiment...
						}).out
					},
					if #q.answeredBy == _|_ {hint: {style: "warning", md: "Aucune expérience ne répond encore à cette question."}},
				]}
			},
			{
				group: {title: "Actions qui y répondent", blocks: [
					if _actionsAnswering[#key] != _|_ {
						md: (#Links & {
							#kind: "action"
							#refs: [for k, _ in _actionsAnswering[#key] {_prefix.action + k}]

							#title: _title.action...
						}).out
					},
					if _actionsAnswering[#key] == _|_ {hint: {style: "warning", md: "Aucune action ne vise encore cette question."}},
				]}
			},
		]
		footer: "Source : `questions.questions.\(#key)`."
	}
}
