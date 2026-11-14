// @what: what we conclude from the Scion and review articles. Each conclusion names the facts it rests on, ours and theirs.
// @invariant: a conclusion is ours. It is anchored by the facts it rests on, never proven by them.
// @ref: @/cueverge/cogen/gen-sealed/studies/scion/study.cue
package study

import "github.com/cyrildesch/cueverge/schema"

schema.#Sealed

facts: [string]: {
	rests: [_, ...]
	role:  _
	// @invariant: only a proposal may wait on a fact of ours not tested yet. Every other conclusion holds.
	if role != "proposal" {holds: true}
}

facts: {
	global_state: {role: "parallel", holds: true, says: "A shared global state does not scale: for us, a single decider at a time.", rests: ["scion.refs_discouraged", "system.single_decider"]}
	moving_ci:    {role: "parallel", holds: true, says: "When everything merges during the tests, the judge must go faster than the agents.", rests: ["scion.no_queue_lock", "system.judge_cadence"]}
	lock_free:    {role: "parallel", holds: true, says: "Accept a change with no lock: a change that loses its place is replayed, not thrown away.", rests: ["scion.lock_free", "system.replay_not_discard"]}
	stale_copy:   {role: "parallel", holds: true, says: "A copy stays behind the head: the agent runs the real judge in its copy before it proposes.", rests: ["scion.mirrors", "system.test_before_proposing"]}
	history:      {role: "parallel", holds: true, says: "Query the history with no copy: know fast whether an effect was already refused.", rests: ["scion.all_in_api", "system.never_the_same_wall"]}
	cost:         {role: "parallel", holds: true, says: "The cost follows the size of the change, not of the repository: for us, the lost cost stays under a ceiling.", rests: ["scion.commit_cost", "system.lost_cost"]}
	conflicts:    {role: "parallel", holds: true, says: "A conflict is fixed forward, without doing the whole generation again.", rests: ["scion.conflicts", "system.replay_not_discard"]}

	risk_tier:            {role: "proposal", holds: "unknown", says: "The risk tier, read on the change, sets the number of people who approve.", rests: ["review.classifier", "review.low_risk", "review.high_risk", "scion.semantic_approvals", "principles.reviewed_intent"]}
	review_the_intent:    {role: "proposal", holds: "unknown", says: "People review the intent, not each line.", rests: ["scion.intent_review", "principles.reviewed_intent"]}
	approve_a_commit:     {role: "lesson", holds: true, says: "An approval must cover one specific commit, not only the text of the intent.", rests: ["review.one_commit", "review.agent_does_not_count"]}
	answer_every_refusal: {role: "lesson", holds: true, says: "Each refusal gets an answer from the agent: fixed, or dropped with a reason.", rests: ["review.every_finding", "system.never_the_same_wall"]}
	cap_the_rounds:       {role: "lesson", holds: true, says: "Cap the rounds: beyond the cap, the agent rethinks its approach instead of starting again.", rests: ["review.round_cap", "review.old_code", "system.never_the_same_wall"]}
	incidents_as_tests:   {role: "proposal", holds: "unknown", says: "Each false or empty intent becomes a test case of the intent rules.", rests: ["review.incidents_as_eval", "principles.reviewed_intent"]}

	no_code_server:      {role: "refusal", holds: true, says: "No central server for the code: jj and git are enough at our scale.", rests: ["scion.server_computes", "scion.not_for_everyone"]}
	no_vote:             {role: "proposal", holds: "unknown", says: "No judge made of agents that vote: the verdict stays with cue vet.", rests: ["review.agent_vote", "principles.executed_constraint"]}
	no_figures_as_proof: {role: "refusal", holds: true, says: "The figures of Anthropic give an order of magnitude, not a proof for us.", rests: ["scion.merges_september", "scion.footprint"]}

	pointer_server: {role: "proposal", holds: "unknown", says: "An orchestration server holds the journal, the state and the leases, with pointers into jj, never code.", rests: ["scion.server_computes", "scion.content_addressing", "actions.orchestration_table"]}
	seal_by_cas:    {role: "proposal", holds: "unknown", says: "Sealing is a compare-and-swap on the sealed tip: our single point of synchronization.", rests: ["scion.ref_cas", "principles.sync_at_sealing"]}
	derived_views:  {role: "proposal", holds: true, says: "The known walls and the lost cost are computed as data derived from the journal.", rests: ["scion.derived_data", "system.never_the_same_wall", "system.lost_cost"]}
}

retired: {}
