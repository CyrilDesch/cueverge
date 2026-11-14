package portal

import (
	"strings"

	"factory.local/kb/sealed/factory/constraints"
	"factory.local/kb/sealed/factory/decisions"
	"factory.local/kb/sealed/factory/principles"
)

// @what: The keys of the decisions that rest on each principle.
_decisionsOn: {for k, d in decisions.decisions if d.restsOn != _|_ for r in d.restsOn {(strings.TrimPrefix(r, _prefix.principle)): (k): true}}

_principleStatuses: ["tested on a project", "stated, not tested"]

// @what: the principles page, the tested ones first.
principlesPage: {
	slug:        "principles"
	title:       "Principles"
	description: "\(len(principles.principles)) principles. A tested principle names its experiment: without it, `cue vet` refuses it."
	footer:      "Generated from the package `principles` at build time."
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
		{filter: {facet: "status", label: "Status", options: _principleStatuses}},
		{search: {placeholder: "Search a principle"}},
		// @why: a status with no principle shows no group, since the site refuses an empty one.
		for s in _principleStatuses if len([for _, p in principles.principles if p.status == s {
			p...
		}]) > 0 {
			group: {
				title: {"tested on a project": "Tested on a project", "stated, not tested": "Stated, not tested"}[s]
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
			{stats: [{label: "Status", value: #p.status, tone: _tone[#p.status]}]},
			if #p.evidence != _|_ {
				group: {title: "Evidence", blocks: [{
					md: (#Links & {
						#kind: "experiment"
						#refs: #p.evidence...

						#title: _title.experiment...
					}).out...
				}]}
			},
			if #p.evidence == _|_ {hint: {style: "info", md: "Stated with no measure: no experiment supports it yet."}},
			if #p.limits != _|_ {
				group: {title: "Limits", blocks: [{
					hint: {
						style: "warning"
						md:    (#Bullets & {#items: #p.limits...}).out...
					}
				}]}
			},
			if _decisionsOn[K] != _|_ {group: {title: "Decisions that follow from it", blocks: [{md: strings.Join([for d, _ in _decisionsOn[K] {"- [\(_title.decision[d])](\(_href.decision[d]))"}], "\n")}]}},
		]
		footer: "Source: `principles.principles.\(K)`."
	}
}

_decisionStatuses: ["settled", "to confirm", "postponed"]

// @what: the decisions page. Settled, then to confirm, then postponed.
decisionsPage: {
	slug:        "decisions"
	title:       "Decisions"
	description: "\(len(decisions.decisions)) decisions taken, or leaned towards, during the conversation."
	footer:      "Generated from the package `decisions` at build time."
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
		{filter: {facet: "status", label: "Status", options: _decisionStatuses}},
		// @why: a status with no decision shows no group, since the site refuses an empty one.
		for s in _decisionStatuses if len([for _, d in decisions.decisions if d.status == s {
			d...
		}]) > 0 {
			group: {
				title: {"settled": "Settled", "to confirm": "To confirm", "postponed": "Postponed"}[s]
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
			{stats: [{label: "Status", value: #d.status, tone: _tone[#d.status]}]},
			{group: {title: "Why", blocks: [{md: #d.why}]}},
			if #d.rejected != _|_ {group: {title: "Option rejected", blocks: [{md: #d.rejected...}]}},
			if #d.restsOn != _|_ {
				group: {title: "Rests on", blocks: [{
					md: (#Links & {
						#kind: "principle"
						#refs: #d.restsOn...

						#title: _title.principle...
					}).out...
				}]}
			},
		]
		footer: "Source: `decisions.decisions.\(K)`."
	}
}

_families: ["simple", "breaking something", "several versions", "rare interleaving", "absence", "time and scale", "no known measure"]
_familyTitle: {
	"simple":             "Simple"
	"breaking something": "Breaking something"
	"several versions":   "Several versions"
	"rare interleaving":  "Rare interleavings"
	"absence":            "Absences"
	"time and scale":     "Time and scale"
	"no known measure":   "No known measure"
}
_cadences:  ["every round", "every deployment", "nightly", "weekly", "none"]
_onProject: ["wired", "possible", "no equivalent"]

// @what: the catalog of constraints. One table per family, with no page per constraint.
constraintsPage: {
	slug:        "constraints"
	title:       "Catalog of constraints"
	description: "\(len(constraints.constraints)) constraints that an agent forgets, with the measure that keeps them. A constraint with no known measure has no cadence: it is a visible debt."
	footer:      "Generated from the package `constraints` at build time."
	blocks: [
		{
			stats: [for o in _onProject {
				label: "on the project: \(o)"
				value: len([for _, c in constraints.constraints if c.onProject == o {
					c...
				}])
				tone: _tone[o]
			}]
		},
		{filter: {facet: "family", label: "Family", options: _families}},
		{filter: {facet: "cadence", label: "Cadence", options: _cadences}},
		{filter: {facet: "onProject", label: "On the project", options: _onProject}},
		{search: {placeholder: "Search a constraint"}},
		for f in _families {
			group: {
				title: _familyTitle[f]
				blocks: [{
					table: {
						columns: ["Constraint", "Measure", "Cadence", "On the project"]
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
