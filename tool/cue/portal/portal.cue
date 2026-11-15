// @what: generic parts of a project portal. A project portal is a Polaris site (polaris.yaml names it).
// @ref: @/cueverge/polaris.yaml
// @why: the package does not import the Polaris site package, which needs CUE v0.18. polaris site build checks the shape.
// @ref: @/cueverge/polaris.yaml
package portal

import (
	"strings"

	"github.com/cyrildesch/cueverge/frame"
	"github.com/cyrildesch/cueverge/project"
)

// @what: the slug of a key. A page path accepts [a-z0-9-] only, so "_" becomes "-".
// @why: a key with an accent fails cue vet here, instead of giving a broken URL.
#Slug: {
	#key: string
	out:  strings.Replace(#key, "_", "-", -1) & =~"^[a-z0-9][a-z0-9-]*$"
}

// @what: the frame page of a project. The problem, then the objectives, the constraints and the intents as cards.
#FramePage: {
	#frame: frame.#Frame
	#intents: [string]: frame.#Intent
	out: {
		slug:        "frame"
		title:       "Frame"
		description: #frame.problem
		footer:      "Generated from frame/ and intents/ at build time."
		// @why: an empty group is left out, since the site refuses it. Before the approval of init, the frame holds only the problem.
		blocks: [
			{
				stats: [
					{label: "objectives", value: len(#frame.objectives), tone: "info"},
					{label: "constraints", value: len(#frame.constraints), tone: "info"},
					{label: "intents", value: len(#intents), tone: "info"},
				]
			},
			if len(#frame.objectives) > 0 {group: {title: "Objectives", blocks: [{cards: [for k, o in #frame.objectives {title: k, tone: "info", md: "\(o.says)\n\n*\(o.why)*"}]}]}},
			if len(#frame.constraints) > 0 {
				group: {title: "Constraints", blocks: [{
					cards: [for k, c in #frame.constraints {
						title: k
						tone:  "medium"
						md:    "\(c.says)\n\nMeasure: \(c.measure)\n\nServes: \(strings.Join(c.serves, ", "))"
					}]
				}]}
			},
			if len(#intents) > 0 {group: {title: "Intents", blocks: [{cards: [for k, i in #intents {title: k, tone: "accepted", md: "\(i.says)\n\nServes: \(i.serves)"}]}]}},
		]
	}
}

// @what: the state of an objective or a constraint, as its rule computes it, and its tone.
_state: {
	constraint: {"true": "holds", "false": "does not hold", "unknown": "not measured"}
	objective:  {"true": "reached", "false": "missed", "unknown": "open"}
	tone:       {"true": "accepted", "false": "high", "unknown": "muted"}
}

// @what: the page of the objectives and constraints of a project. The problem, then each objective with its state, then the constraints.
// @invariant: no state is written here. Each one is the polarity of a sealed fact, which its rule computes.
#ProjectPage: {
	#problem:     project.#ProblemPackage
	#objectives:  project.#ObjectivesPackage
	#constraints: project.#ConstraintsPackage
	let P = [for _, f in #problem.facts {f.says}]
	out: {
		slug:        "objectives"
		title:       "Objectives and constraints"
		description: strings.Join(P, " ")
		footer:      "Generated at build time from the sealed packages problem, objectives and constraints. Each state is computed by a rule."
		// @why: an empty group is left out, since the site refuses it.
		blocks: [
			{
				stats: [
					{label: "objectives", value: len(#objectives.facts), tone: "info"},
					for v in ["true", "false", "unknown"] {
						label: "constraints \(_state.constraint[v])"
						value: len([for _, c in #constraints.facts if "\(c.holds)" == v {c}])
						tone:  _state.tone[v]
					},
				]
			},
			if len(#objectives.facts) > 0 {
				group: {title: "Objectives", blocks: [{
					cards: [for k, o in #objectives.facts {
						title:  k
						tone:   _state.tone["\(o.holds)"]
						badges: [{badge: _state.objective["\(o.holds)"], tone: _state.tone["\(o.holds)"]}]
						let By = [for ck, c in #constraints.facts for s in c.serves if s == k {"`\(ck)`"}]
						md: "\(o.says)\n\n*\(o.why)*\n\nServed by: \(strings.Join(By, ", "))"
					}]
				}]}
			},
			if len(#constraints.facts) > 0 {
				group: {title: "Constraints", blocks: [{
					table: {
						columns: ["Constraint", "Measure", "Serves", "State"]
						rows: [for k, c in #constraints.facts {[
							"**\(k)**. \(c.says)",
							c.measure,
							strings.Join([for o in c.serves {"`\(o)`"}], ", "),
							{badge: _state.constraint["\(c.holds)"], tone: _state.tone["\(c.holds)"]},
						]}]
					}
				}]}
			},
		]
	}
}
