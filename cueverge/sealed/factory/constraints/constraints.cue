// @what: a catalog of constraints an agent forgets.
// @invariant: a constraint has a statement, a measure and a cadence, or it says that no measure is known.
// @invariant: a wired constraint holds as its measure says. Any other is unknown and names an action not done.
// @ref: @/cueverge/cogen/gen-sealed/factory/constraints/constraints.cue
package constraints

import (
	"github.com/cyrildesch/cueverge/schema"
	"factory.local/kb/sealed/factory/actions"
)

#ActionRef: or([for k, _ in actions.actions {
	k...
}])

#Constraint: {
	schema.#Fact...
	says:      statement
	statement: string
	// @what: the action that builds the measure of a constraint not wired on the project.
	action?:   #ActionRef
	family:    "breaking something" | "several versions" | "rare interleaving" | "absence" | "time and scale" | "simple" | "no known measure"
	measure:   string
	cadence:   "every round" | "every deployment" | "nightly" | "weekly" | "none"
	onProject: "wired" | "possible" | "no equivalent"

	// @why: a constraint with no known measure is a visible debt, not an assumed property.
	if family == "no known measure" {
		cadence: "none"
	}
	if family != "no known measure" {
		cadence: !="none"
	}
	if onProject == "wired" {holds: bool}
	if onProject != "wired" {
		holds:   "unknown"
		action!: _
	}
}

constraints: [string]: #Constraint

// @what: every sealed fact of the package.
facts: {for k, c in constraints {
	(k): c...
}}
retired: [string]: schema.#Retired
retired: {}

constraints: {
	fast_response: {statement: "An endpoint responds in under 100 ms", family: "simple", measure: "Time each response", cadence: "every round", onProject: "possible", action: "wire_the_project_constraints"}

	two_dc_restart:  {statement: "Restart on 2 data centers with no backup in under 10 minutes", family: "breaking something", measure: "Destroy everything, time until the first correct response", cadence: "weekly", onProject: "no equivalent", action: "service_initiative"}
	rollback:        {statement: "Every deployment can be rolled back in under 5 minutes", family: "breaking something", measure: "Deploy, roll back, compare the state before and after", cadence: "every deployment", onProject: "no equivalent", action: "service_initiative"}
	lost_dependency: {statement: "Losing a dependency degrades the service without stopping it", family: "breaking something", measure: "Cut the dependency, check which routes still respond", cadence: "nightly", onProject: "no equivalent", action: "service_initiative"}

	old_data:     {statement: "Data written by version 1 stays readable by version N", family: "several versions", measure: "Keep a data set per version, read it again", cadence: "every round", onProject: "possible", action: "wire_the_project_constraints"}
	two_versions: {statement: "Two versions run side by side during an update", family: "several versions", measure: "Run N and N+1 on the same state, compare", cadence: "every deployment", onProject: "no equivalent", action: "service_initiative"}
	old_clients:  {statement: "A client from six months ago still works", family: "several versions", measure: "Replay the recorded requests of the old clients", cadence: "every round", onProject: "possible", action: "wire_the_project_constraints"}

	idempotence:       {statement: "Replaying a request changes nothing", family: "rare interleaving", measure: "Send each write twice, compare the state", cadence: "every round", onProject: "possible", action: "wire_the_project_constraints"}
	concurrent_writes: {statement: "Two concurrent writes lose neither of them", family: "rare interleaving", measure: "N concurrent writes, count what remains", cadence: "nightly", onProject: "no equivalent", action: "service_initiative"}
	exactly_once:      {statement: "A message is processed once, even after a crash", family: "rare interleaving", measure: "Kill the process at random points, check the count", cadence: "nightly", onProject: "no equivalent", action: "service_initiative"}

	no_secret:      {statement: "No secret in the logs", family: "absence", measure: "Inject a marked secret, look for it in all the outputs", cadence: "every round", onProject: "possible", action: "wire_the_project_constraints"}
	access_control: {statement: "No route without access control", family: "absence", measure: "List the routes, call each one with no identity", cadence: "every round", onProject: "no equivalent", action: "service_initiative"}
	region:         {statement: "No data leaves the region", family: "absence", measure: "Record the outgoing calls, check the destinations", cadence: "every round", onProject: "no equivalent", action: "service_initiative"}

	memory_leak:      {statement: "No memory leak", family: "time and scale", measure: "Memory after 10,000 requests against memory after 100", cadence: "nightly", onProject: "possible", action: "wire_the_project_constraints"}
	load:             {statement: "Holds ten times the current load", family: "time and scale", measure: "Load test, check the other constraints during it", cadence: "weekly", onProject: "no equivalent", action: "service_initiative"}
	deletion:         {statement: "Deleted data is deleted everywhere within 30 days", family: "time and scale", measure: "Create, delete, search in all the stores, with an accelerated clock", cadence: "nightly", onProject: "no equivalent", action: "service_initiative"}
	cost_per_request: {statement: "The cost per request stays under a ceiling", family: "time and scale", measure: "Resources consumed divided by requests served", cadence: "every round", onProject: "possible", action: "wire_the_project_constraints"}

	field_order: {statement: "Reordering the fields of an input does not change the result", family: "simple", measure: "Evaluate a reordered variant of each case", cadence: "every round", onProject: "possible", action: "law_without_oracle"}

	error_message:    {statement: "An error message lets the user fix the problem alone", family: "no known measure", measure: "A judgement, by a human or by an agent that plays the human", cadence: "none", onProject: "no equivalent", action: "judge_without_measure"}
	understood_alert: {statement: "The on-call engineer understands the alert at three in the morning", family: "no known measure", measure: "A human judgement", cadence: "none", onProject: "no equivalent", action: "judge_without_measure"}
}
