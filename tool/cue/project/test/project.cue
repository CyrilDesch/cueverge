// @what: the rules of the problem, the objectives and the constraints on a small project. Each case must hold.
// @what: the failing cases are checked by hand in the change that adds a rule.
// @ref: @/tool/cue/project/project.cue
package test

import "github.com/cyrildesch/cueverge/project"

_problem: project.#ProblemPackage & {
	facts: problem: {says: "A small project to test the rules of the objectives.", holds: true, attributedTo: "a person, at init"}
	retired: {}
}

_constraints: project.#ConstraintsPackage & {
	facts: {
		fast:   {says: "A page answers in under a second.", measure: "Time each page in a round.", serves: ["usable"], holds: true}
		secure: {says: "No route answers without a login.", measure: "Call each route with no identity.", serves: ["safe"], holds: false}
		logged: {says: "No secret is written in a log.", measure: "Inject a marked secret and look for it.", serves: ["safe", "known"], holds: "unknown"}
		traced: {says: "Each request has a trace identifier.", measure: "Look for the identifier in each log line.", serves: ["known"], holds: "unknown"}
	}
	retired: {}
}

_objectives: project.#ObjectivesPackage & {
	facts: {
		usable: {says: "People can use the service every day.", why: "A slow service is not used at all.", holds: true}
		safe:   {says: "The data of a person stays private.", why: "A leak loses the trust of every user.", holds: false}
		known:  {says: "An operator knows what the service does.", why: "An incident is fixed faster with traces.", holds: "unknown"}
	}
	retired: {}
}

problem: (project.#ProblemRules & {sealed: _problem, approved: ["A small project to test the rules of the objectives."]}).rules

constraints: project.#ConstraintRules & {
	sealed:     _constraints
	objectives: _objectives.facts
	measured:   {fast: true, secure: false}
}

objectives: project.#ObjectiveRules & {
	sealed:      _objectives
	constraints: _constraints.facts
}
