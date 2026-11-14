package portal

import (
	"strings"

	"factory.local/kb/sealed/usine/constraints"
	"factory.local/kb/sealed/usine/decisions"
	"factory.local/kb/sealed/usine/principles"
)

// @what: The keys of the decisions that rest on each principle.
_decisionsOn: {for k, d in decisions.decisions if d.restsOn != _|_ for r in d.restsOn {(strings.TrimPrefix(r, _prefix.principle)): (k): true}}

_principleStatuses: ["testé sur un projet", "posé, non testé"]

// @what: the principles page, the tested ones first.
principesPage: {
	slug:        "principes"
	title:       "Principes"
	description: "\(len(principles.principles)) principes. Un principe testé nomme son expérience : sans elle, `cue vet` le refuse."
	footer:      "Généré depuis le paquet `principles` au build."
	blocks: [
		{
			stats: [for s in _principleStatuses {
				label: s
				value: len([for _, p in principles.principles if p.status == s {
					p...
				}])
				tone: _tone[s]
			}]
		},
		{filter: {facet: "status", label: "État", options: _principleStatuses}},
		{search: {placeholder: "Chercher un principe"}},
		// @why: a status with no principle shows no group, since the site refuses an empty one.
		for s in _principleStatuses if len([for _, p in principles.principles if p.status == s {
			p...
		}]) > 0 {
			group: {
				title: {"testé sur un projet": "Testés sur un projet", "posé, non testé": "Posés, non testés"}[s]
				blocks: [{
					cards: [for k, p in principles.principles if p.status == s {
						title: p.title
						href:  _href.principle[k]
						tone:  _tone[p.status]
						md:    p.statement
						facets: status: p.status
					}]
				}]
			}
		},
	]
	pages: [for k, p in principles.principles {
		(#PrinciplePage & {
			#key: k...

			#p: p...
		}).out...
	}]
}

#PrinciplePage: {
	#key: string
	#p:   principles.#Principle
	let K = #key
	out: {
		slug:        (#Slug & {#key: K}).out
		title:       #p.title
		hidden:      true
		description: #p.statement
		blocks: [
			{stats: [{label: "État", value: #p.status, tone: _tone[#p.status]}]},
			if #p.evidence != _|_ {
				group: {title: "Preuve", blocks: [{
					md: (#Links & {
						#kind: "experiment"
						#refs: #p.evidence...

						#title: _title.experiment...
					}).out...
				}]}
			},
			if #p.evidence == _|_ {hint: {style: "info", md: "Posé sans mesure : aucune expérience ne l'appuie encore."}},
			if #p.limits != _|_ {
				group: {title: "Limites", blocks: [{
					hint: {
						style: "warning"
						md:    (#Bullets & {#items: #p.limits...}).out...
					}
				}]}
			},
			if _decisionsOn[K] != _|_ {group: {title: "Décisions qui en découlent", blocks: [{md: strings.Join([for d, _ in _decisionsOn[K] {"- [\(_title.decision[d])](\(_href.decision[d]))"}], "\n")}]}},
		]
		footer: "Source : `principles.principles.\(K)`."
	}
}

_decisionStatuses: ["acté", "à confirmer", "reporté"]

// @what: the decisions page. Settled, then to confirm, then postponed.
decisionsPage: {
	slug:        "decisions"
	title:       "Décisions"
	description: "\(len(decisions.decisions)) décisions prises ou penchées pendant la conversation."
	footer:      "Généré depuis le paquet `decisions` au build."
	blocks: [
		{
			stats: [for s in _decisionStatuses {
				label: s
				value: len([for _, d in decisions.decisions if d.status == s {
					d...
				}])
				tone: _tone[s]
			}]
		},
		{filter: {facet: "status", label: "État", options: _decisionStatuses}},
		// @why: a status with no decision shows no group, since the site refuses an empty one.
		for s in _decisionStatuses if len([for _, d in decisions.decisions if d.status == s {
			d...
		}]) > 0 {
			group: {
				title: {"acté": "Actées", "à confirmer": "À confirmer", "reporté": "Reportées"}[s]
				blocks: [{
					cards: [for k, d in decisions.decisions if d.status == s {
						title: d.title
						href:  _href.decision[k]
						tone:  _tone[d.status]
						md:    d.decision
						facets: status: d.status
					}]
				}]
			}
		},
	]
	pages: [for k, d in decisions.decisions {
		(#DecisionPage & {
			#key: k...

			#d: d...
		}).out...
	}]
}

#DecisionPage: {
	#key: string
	#d:   decisions.#Decision
	let K = #key
	out: {
		slug:        (#Slug & {#key: K}).out
		title:       #d.title
		hidden:      true
		description: #d.decision
		blocks: [
			{stats: [{label: "État", value: #d.status, tone: _tone[#d.status]}]},
			{group: {title: "Pourquoi", blocks: [{md: #d.why}]}},
			if #d.rejected != _|_ {group: {title: "Option écartée", blocks: [{md: #d.rejected...}]}},
			if #d.restsOn != _|_ {
				group: {title: "Repose sur", blocks: [{
					md: (#Links & {
						#kind: "principle"
						#refs: #d.restsOn...

						#title: _title.principle...
					}).out...
				}]}
			},
		]
		footer: "Source : `decisions.decisions.\(K)`."
	}
}

_families: ["simple", "casser quelque chose", "plusieurs versions", "entrelacement rare", "absence", "temps et échelle", "sans mesure connue"]
_familyTitle: {
	"simple":               "Simples"
	"casser quelque chose": "Casser quelque chose"
	"plusieurs versions":   "Plusieurs versions"
	"entrelacement rare":   "Entrelacements rares"
	"absence":              "Absences"
	"temps et échelle":     "Temps et échelle"
	"sans mesure connue":   "Sans mesure connue"
}
_cadences:  ["chaque tour", "à chaque déploiement", "nocturne", "hebdomadaire", "aucune"]
_onProject: ["branché", "possible", "sans équivalent"]

// @what: the catalog of constraints. One table per family, with no page per constraint.
contraintesPage: {
	slug:        "contraintes"
	title:       "Catalogue de contraintes"
	description: "\(len(constraints.constraints)) contraintes qu'un agent oublie, avec la mesure qui les tient. Une contrainte sans mesure connue n'a pas de cadence : c'est une dette visible."
	footer:      "Généré depuis le paquet `constraints` au build."
	blocks: [
		{
			stats: [for o in _onProject {
				label: "sur le projet : \(o)"
				value: len([for _, c in constraints.constraints if c.onProject == o {
					c...
				}])
				tone: _tone[o]
			}]
		},
		{filter: {facet: "family", label: "Famille", options: _families}},
		{filter: {facet: "cadence", label: "Cadence", options: _cadences}},
		{filter: {facet: "onProject", label: "Sur le projet", options: _onProject}},
		{search: {placeholder: "Chercher une contrainte"}},
		for f in _families {
			group: {
				title: _familyTitle[f]
				blocks: [{
					table: {
						columns: ["Contrainte", "Mesure", "Cadence", "Sur le projet"]
						rows: [for _, c in constraints.constraints if c.family == f {
							cells: ["**\(c.statement)**", c.measure, {
								badge: c.cadence...
								tone:  "muted"
							}, (#Badge & {
								#v: c.onProject...
							}).out]
							facets: {family: c.family, cadence: c.cadence, onProject: c.onProject}
						}]
					}
				}]
			}
		},
	]
}
