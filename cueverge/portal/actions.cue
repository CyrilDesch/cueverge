package portal

import (
	"list"
	"strings"

	"factory.local/kb/sealed/usine/actions"
)

// @what: The actions in their order, as [key, action] pairs.
_actionsInOrder: list.Sort([for k, v in actions.actions {key: k, a: v}], {x: _, y: _, less: x.a.order < y.a.order})

// @what: The keys of the actions that run each experiment or answer each question.
_actionsRunning:   {for k, a in actions.actions if a.runs != _|_ for r in a.runs {(strings.TrimPrefix(r, _prefix.experiment)): (k): true}}
_actionsAnswering: {for k, a in actions.actions if a.answers != _|_ for r in a.answers {(strings.TrimPrefix(r, _prefix.question)): (k): true}}
_actionsAfter:     {for k, a in actions.actions if a.after != _|_ for r in a.after {(strings.TrimPrefix(r, _prefix.action)): (k): true}}

// @what: the actions page. One card per action, in order, and one hidden page each.
actionsPage: {
	slug:        "actions"
	title:       "Actions"
	description: "\(len(actions.actions)) actions, dans l'ordre. Chacune a une mesure et un verdict : sans eux, `cue vet` la refuse."
	footer:      "Généré depuis le paquet `actions` au build."
	blocks: [
		{filter: {facet: "cost", label: "Coût", options: ["faible", "moyen", "élevé"]}},
		{filter: {facet: "status", label: "État", options: ["à faire", "en cours", "fait"]}},
		{
			cards: [for x in _actionsInOrder {
				let A = x.a
				title: "\(A.order). \(A.title)"
				href:  _href.action[x.key]
				tone:  _tone[A.cost]
				badges: [(#Badge & {
					#v: A.status...
				}).out, {
					badge: "coût \(A.cost)"
					tone:  _tone[A.cost]...
				}, if A.needsHuman != _|_ {{badge: "demande un humain", tone: "medium"}}]
				md:     "**Verdict.** \(A.verdict)"
				facets: {cost: A.cost, status: A.status}
			}]
		},
	]
	pages: [for x in _actionsInOrder {
		(#ActionPage & {
			#key: x.key...

			#a: x.a...
		}).out...
	}]
}

// @what: The page of one action. A section shows only when its field is set.
#ActionPage: {
	#key: string
	#a:   actions.#Action
	let K = #key
	out: {
		slug:        (#Slug & {#key: K}).out
		title:       "\(#a.order). \(#a.title)"
		"nav-title": #a.title
		hidden:      true
		description: #a.statement
		blocks: [
			{
				stats: [
					{label: "Ordre", value: "\(#a.order) / \(len(actions.actions))"},
					{label: "État", value: #a.status, tone: _tone[#a.status]},
					{label: "Coût", value: #a.cost, tone: _tone[#a.cost]},
				]
			},
			{group: {title: "Mesure", blocks: [{md: #a.measure}]}},
			{group: {title: "Verdict", blocks: [{hint: {style: "success", title: "Compte comme fait", md: #a.verdict}}]}},
			if #a.needsHuman != _|_ {hint: {style: "warning", title: "Demande un humain", md: #a.needsHuman}},
			if #a.after != _|_ {
				group: {title: "Après", blocks: [{
					md: (#Links & {
						#kind: "action"
						#refs: #a.after...

						#title: _title.action...
					}).out...
				}]}
			},
			if _actionsAfter[#key] != _|_ {
				group: {title: "Débloque", blocks: [{
					md: (#Links & {
						#kind: "action"
						#refs: [for k, _ in _actionsAfter[#key] {_prefix.action + k}]

						#title: _title.action...
					}).out...
				}]}
			},
			if #a.runs != _|_ {
				group: {title: "Expérience", blocks: [{
					md: (#Links & {
						#kind: "experiment"
						#refs: #a.runs...

						#title: _title.experiment...
					}).out...
				}]}
			},
			if #a.answers != _|_ {
				group: {title: "Répond à", blocks: [{
					md: (#Links & {
						#kind: "question"
						#refs: #a.answers...

						#title: _title.question...
					}).out...
				}]}
			},
		]
		footer: "Source : `actions.actions.\(#key)`."
	}
}
