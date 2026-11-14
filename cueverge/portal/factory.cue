package portal

import (
	"list"
	"strings"

	"factory.local/kb/sealed/factory/system"
)

// @what: each constraint of the factory with its status and its measures, as sealed facts state them.
// @invariant: no status is written here. It is the polarity of the fact, which the system cogen rules recompute.
_constraint: {for k, f in system.facts if f.kind == "constraint" {
	(k): {
		fact:   f...
		status: [if f.holds == true {"holds"}, if f.holds == false {"does not hold"}, "not measured"][0]...
		_with: [for m in [if f.with != _|_ {
			f.with...
		}, []][0] {let M = system.facts[m]
			"\(M.says): \(M.value) \(M.unit)"
		}]
		if f.value != _|_ {shown: strings.Join(list.Concat([["\(f.value) \(f.unit)"], _with]), "; ")}
	}
}}

factoryPage: {
	slug:        "factory-constraints"
	title:       "Constraints of the factory"
	description: "What keeps the work of the agents from being lost, and what keeps the judge fast and stable enough. Each value is a sealed fact, computed again from the journal."
	footer:      "A constraint that is “not measured” names the action that will build its measure, and this action is not done."
	blocks: [
		{
			stats: [for st in ["holds", "does not hold", "not measured"] {
				label: st
				value: len([for _, c in _constraint if c.status == st {
					c...
				}])
				tone: _tone[st]
			}]
		},
		{
			cards: [for k, c in _constraint {
				title: c.fact.title
				tone:  _tone[c.status]
				badges: [(#Badge & {
					#v: c.status...
				}).out, {
					badge: c.fact.family...
					tone:  "info"
				}]
				md: c.fact.says + "\n\n" + [if c.shown != _|_ {"**Measure.** \(c.shown)"}, "**Measure.** \(c.fact.measure)"][0] + "\n\n*Why.* \(c.fact.why)"
			}]
		},
	]
}
