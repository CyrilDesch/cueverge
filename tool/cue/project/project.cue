// @what: the problem, the objectives and the constraints of a project as sealed facts, and the generic rules that check them.
// @invariant: an objective or a constraint is intent. Its rule computes its state, never from a raw source.
// @what: a project seals each one under sealed/project, with its rules at the same path under cogen.
package project

import (
	"list"
	"strings"

	"github.com/cyrildesch/cueverge/kinds"
	"github.com/cyrildesch/cueverge/schema"
)

// @what: a key of an objective, a constraint or an intent. The portal turns it into a page path.
#Key: =~"^[a-z][a-z0-9_]*$"

#Statement: string & strings.MinRunes(8) & strings.MaxRunes(300)

// @what: the problem a person states at init, in their words. It may be longer than a fact, so it has its own shape.
#ProblemPackage: {
	facts: [#Key]: {
		says:         string & strings.MinRunes(20) & strings.MaxRunes(600)
		holds:        true
		attributedTo: string
	}
	retired: [string]: schema.#Retired
}

// @what: what the project must achieve. Its state follows from the constraints that serve it.
#Objective: {
	schema.#Fact...
	says:  #Statement
	why:   #Statement
	holds: bool | "unknown"
}

// @what: a property every change must keep, and how a round measures it. Its state is the verdict of a round.
#Constraint: {
	schema.#Fact...
	says:    #Statement
	measure: #Statement
	serves:  [#Key, ...#Key]
	holds:   bool | "unknown"
}

#ObjectivesPackage: {
	facts: [#Key]:     #Objective
	retired: [string]: schema.#Retired
}

#ConstraintsPackage: {
	facts: [#Key]:     #Constraint
	retired: [string]: schema.#Retired
}

// @what: the rules of the problem. Each problem fact is the exact text of a problem that a person approved at init.
#ProblemRules: {
	sealed: #ProblemPackage
	// @what: the problems of the approved inits, from the exports of the init journal.
	approved: [...string]
	rules: kinds.#Cover & {"sealed": sealed, by: {for k, _ in sealed.facts {
		(k): (kinds.#Approved & {"approved": approved})...
	}}}
}

// @what: the rules of the constraints. A constraint that a round measures takes its verdict. Any other is unknown.
#ConstraintRules: {
	sealed: #ConstraintsPackage
	objectives: [#Key]: _
	// @what: the verdict of each measured constraint, from the exports of the rounds.
	measured: [string]: bool
	rules: kinds.#Cover & {"sealed": sealed, by: {
		for k, _ in sealed.facts if measured[k] != _|_ {
			(k): (kinds.#Computed & {holds: measured[k]})...
		}
		for k, _ in sealed.facts if measured[k] == _|_ {
			(k): (kinds.#Unmeasured & {"measured": measured, key: k})...
		}
	}}
	// @invariant: a constraint serves objectives that exist.
	serves: {for k, c in sealed.facts for o in c.serves {"\(k)/\(o)": (objectives[o] != _|_) & true}}
}

// @what: the rules of the objectives. An objective holds when every constraint that serves it holds, and fails when one fails.
#ObjectiveRules: {
	sealed: #ObjectivesPackage
	constraints: [#Key]: #Constraint
	_serving: {for k, _ in sealed.facts {
		(k): [for _, c in constraints if list.Contains(c.serves, k) {c}]
	}}
	rules: kinds.#Cover & {"sealed": sealed, by: {for k, _ in sealed.facts {
		let S = _serving[k]
		let False = len([for c in S if c.holds == false {c}])
		let Unknown = len([for c in S if c.holds == "unknown" {c}])
		if False > 0 {(k): (kinds.#Computed & {holds: false})...}
		if False == 0 && Unknown == 0 {(k): (kinds.#Computed & {holds: true})...}
		if False == 0 && Unknown > 0 {(k): (kinds.#Open & {from: S})...}
	}}}
	// @invariant: an objective is served. With no constraint, nothing would ever say whether it is reached.
	served: {for k, _ in sealed.facts {(k): (len(_serving[k]) > 0) & true}}
}
