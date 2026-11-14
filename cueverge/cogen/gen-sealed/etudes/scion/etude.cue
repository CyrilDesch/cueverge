// @what: anchors each conclusion of the Scion study on its facts, at least one of them external.
// @invariant: a conclusion holds when every anchor holds. With an unknown anchor it waits on what tests it.
// @invariant: a parallel rests on a constraint of our factory, or it is only a summary.
// @ref: @/cueverge/sealed/etudes/scion/etude.cue
package etude

import (
	"strings"

	"github.com/cyrildesch/cueverge/kinds"
	s "factory.local/kb/sealed/etudes/scion:etude"
	scion "factory.local/kb/sealed/anthropic/scion"
	revue "factory.local/kb/sealed/anthropic/revue-claude-code:revue"
	"factory.local/kb/sealed/usine/system"
	"factory.local/kb/sealed/usine/principles"
	"factory.local/kb/sealed/usine/actions"
	sysrules "factory.local/kb/cogen/gen-sealed/usine/system"
	prules "factory.local/kb/cogen/gen-sealed/usine/principles"
	arules "factory.local/kb/cogen/gen-sealed/usine/actions"
)

// @what: every fact a conclusion may rest on. A fact of an article anchors with its own polarity.
// @why: a parallel says we have the constraint, not that it holds. Its anchor is the constraint and its rule.
// @invariant: a constraint anchors only when the system cogen rules cover it. Nothing anchors because it is written.
_anchors: {
	for k, f in scion.facts {
		"scion.\(k)": f...
	}
	for k, f in revue.facts {
		"revue.\(k)": f...
	}
	for k, f in system.facts if f.kind == "contrainte" {
		"system.\(k)": {
			holds: true
			rule:  sysrules.rules.covered[k]...
		}
	}

	// @why: a principle or an action is intent. It anchors with its polarity, and an unknown one with what will test it.
	for k, p in principles.principles {
		"principles.\(k)": {
			holds: p.holds...
			rule:  prules.rules.covered[k]...
			if p.holds == "inconnu" {awaits: prules.rules.by[k].action}
		}
	}
	for k, a in actions.actions {
		"actions.\(k)": {
			holds: a.holds...
			rule:  arules.rules.covered[k]...
			if a.holds == "inconnu" {awaits: a}
		}
	}
}

_unknown: {for k, f in s.facts {
	(k): [for r in f.rests if _anchors[r].holds == "inconnu" {
		_anchors[r]...
	}]
}}

rules: kinds.#Cover & {sealed: s, by: {
	for k, f in s.facts if len(_unknown[k]) == 0 {
		(k): (kinds.#Derived & {
			from: [for r in f.rests {
				_anchors[r]...
			}]
		})...
	}
	for k, f in s.facts if len(_unknown[k]) > 0 {
		(k): (kinds.#Pending & {
			action: _unknown[k][0].awaits...
		})...
	}
}}

// @invariant: no conclusion rests on a fact that does not hold, even while it waits.
sound: {for k, f in s.facts {
	(k): len([for r in f.rests if _anchors[r].holds == false {
		r...
	}]) & 0
}}

// @invariant: every conclusion rests on a fact of an article.
external: {for k, f in s.facts {
	(k): len([for r in f.rests if strings.HasPrefix(r, "scion.") || strings.HasPrefix(r, "revue.") {
		r...
	}]) > 0 & true
}}
// @invariant: every parallel rests on a constraint of our factory.
ours: {for k, f in s.facts if f.role == "parallèle" {
	(k): len([for r in f.rests if strings.HasPrefix(r, "system.") {
		r...
	}]) > 0 & true
}}
