package portal

import (
	"strings"

	"factory.local/kb/sealed/usine/experiments"
	"factory.local/kb/sealed/usine/principles"
	"factory.local/kb/sealed/usine/questions"
)

_statuses:    ["fait", "interrompu", "prévu", "écarté"]
_statusTitle: {"fait": "Faites", "interrompu": "Interrompues", "prévu": "Prévues", "écarté": "Écartées"}

// @what: The keys of the principles that cite each experiment as evidence.
_principlesCiting: {for k, p in principles.principles if p.evidence != _|_ for r in p.evidence {(strings.TrimPrefix(r, _prefix.experiment)): (k): true}}

// @what: the sealed measures of each experiment, as the experiments cogen recomputes them.
_measuresOf: {for k, _ in experiments.experiments {
	(k): [for m in experiments.measures if m.experiment == k {
		m...
	}]
}}

// @what: The keys of the questions that each experiment answers.
_questionsAnswered: {for k, q in questions.questions if q.answeredBy != _|_ for r in q.answeredBy {(strings.TrimPrefix(r, _prefix.experiment)): (k): true}}

// @what: the experiments page. What was measured first, then what did not run, then what is planned.
experiencesPage: {
	slug:        "experiences"
	title:       "Expériences"
	description: "\(len(experiments.experiments)) expériences : ce qui a été mesuré, et ce qui ne l'est pas encore."
	footer:      "Généré depuis le paquet `experiments` au build. Chaque chiffre est une mesure scellée, recalculée depuis les exécutions du noyau ou le journal."
	blocks: [
		{
			stats: [for s in _statuses {
				label: s
				value: len([for _, e in experiments.experiments if e.status == s {
					e...
				}])
				tone: _tone[s]
			}]
		},
		{filter: {facet: "status", label: "État", options: _statuses}},
		{filter: {facet: "cost", label: "Coût", options: ["faible", "moyen", "élevé"]}},
		{search: {placeholder: "Chercher une expérience"}},
		// @why: a status with no experiment shows no group, since the site refuses an empty one.
		for s in _statuses if len([for _, e in experiments.experiments if e.status == s {
			e...
		}]) > 0 {
			group: {
				title: _statusTitle[s]
				blocks: [{
					cards: [for k, e in experiments.experiments if e.status == s {
						title: e.title
						href:  _href.experiment[k]
						tone:  _tone[e.status]
						badges: [{
							badge: "coût \(e.cost)"
							tone:  _tone[e.cost]...
						}]
						md: [
							if e.result != _|_ {
								e.result...
							},
							"*\(e.question)*",
						][0]
						facets: {status: e.status, cost: e.cost}
					}]
				}]
			}
		},
	]
	pages: [for k, e in experiments.experiments {
		(#ExperimentPage & {
			#key: k...

			#e: e...
		}).out...
	}]
}

#ExperimentPage: {
	#key: string
	#e:   experiments.#Experiment
	let K = #key
	let Result = {
		"fait":       "success"
		"interrompu": "warning"
		"écarté":     "info"
		"prévu":      "info"
	}
	out: {
		slug:        (#Slug & {#key: K}).out
		title:       #e.title
		hidden:      true
		description: "*\(#e.question)*"
		blocks: [
			{
				stats: [
					{label: "État", value: #e.status, tone: _tone[#e.status]},
					{label: "Coût", value: #e.cost, tone: _tone[#e.cost]},
				]
			},
			if #e.result != _|_ {hint: {style: Result[#e.status], title: "Résultat", md: #e.result}},
			if #e.result == _|_ {hint: {style: "info", title: "Pas encore lancée", md: "Aucun résultat : l'expérience est prévue."}},
			if len(_measuresOf[K]) > 0 {
				group: {title: "Chiffres", blocks: [{
					table: {
						columns: ["Mesure", "Valeur"]
						rows:    [for m in _measuresOf[K] {[m.says, "**\(m.value) \(m.unit)**"]}]
					}
				}]}
			},
			{group: {title: "Méthode", blocks: [{md: #e.method}]}},
			if #e.learned != _|_ {
				group: {title: "Ce qu'on a appris", blocks: [{
					md: (#Bullets & {#items: #e.learned...}).out...
				}]}
			},
			if #e.limits != _|_ {
				group: {title: "Ce que ça ne montre pas", blocks: [{
					hint: {
						style: "warning"
						md:    (#Bullets & {#items: #e.limits...}).out...
					}
				}]}
			},
			if _questionsAnswered[K] != _|_ {
				group: {title: "Questions auxquelles elle répond", blocks: [{
					md: (#Links & {
						#kind: "question"
						#refs: [for q, _ in _questionsAnswered[K] {_prefix.question + q}]

						#title: _title.question...
					}).out...
				}]}
			},
			if _actionsRunning[K] != _|_ {
				group: {title: "Actions qui la lancent", blocks: [{
					md: (#Links & {
						#kind: "action"
						#refs: [for a, _ in _actionsRunning[K] {_prefix.action + a}]

						#title: _title.action...
					}).out...
				}]}
			},
			if _principlesCiting[K] != _|_ {
				group: {title: "Principes qu'elle appuie", blocks: [{
					md: (#Links & {
						#kind: "principle"
						#refs: [for p, _ in _principlesCiting[K] {_prefix.principle + p}]

						#title: _title.principle...
					}).out...
				}]}
			},
		]
		footer: "Source : `experiments.experiments.\(K)`."
	}
}
