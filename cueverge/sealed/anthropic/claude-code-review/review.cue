// @what: what the Claude Code team article on code review states. Every fact is attributed to its authors.
// @ref: @/cueverge/cogen/gen-sealed/anthropic/claude-code-review/review.cue
// @ref: @/cueverge/gen/web/claude-code-review/page.gen.cue
package review

import "github.com/cyrildesch/cueverge/schema"

schema.#Sealed

_attributedTo: "Claude Code team, “How the Claude Code team does code review”"
facts: [string]: attributedTo: _attributedTo

facts: {
	claude_writes:        {says: "Claude writes about 90 % of the code of Claude Code.", holds: true, value: 90, unit: "%"}
	reverts:              {says: "From June to September, the share of reverted PRs fell by more than 40 %.", holds: true, value: 40, unit: "%"}
	prs_doubled:          {says: "Over the same period, the merged PRs more than doubled.", holds: true}
	names_antique:        {says: "The article names Antique.", holds: false}
	at_most_one_human:    {says: "The goal: most PRs merge with at most one person in the loop.", holds: true}
	guardrail:            {says: "The revert and incident rates are the guardrail on the human time saved.", holds: true}
	show_the_output:      {says: "Claude must show the output of its check, not say that it is done.", holds: true}
	fix_at_the_source:    {says: "A repeated finding is fixed at the source: skill, lint rule, CLAUDE.md.", holds: true}
	comments_before:      {says: "Before AI review, 16 % of internal PRs got a substantive comment.", holds: true, value: 16, unit: "%"}
	comments_after:       {says: "With AI review, this share goes to 54 %.", holds: true, value: 54, unit: "%"}
	agent_vote:           {says: "Several agents look for bugs, then another group votes on each finding.", holds: true}
	every_finding:        {says: "Each finding gets an answer: fixed, or closed with a reason.", holds: true}
	security_blocks:      {says: "A PR does not merge while a bug or security finding is still open.", holds: true}
	low_risk:             {says: "Low risk: no human approval once the automated checks are green.", holds: true}
	medium_risk:          {says: "Medium risk: one person approves.", holds: true}
	high_risk:            {says: "High risk: two people approve.", holds: true}
	classifier:           {says: "The change sets the risk tier, not its author: a classifier reads it.", holds: true}
	agent_does_not_count: {says: "The approval of an agent never counts as that of a person.", holds: true}
	director_is_reviewer: {says: "The person who directs the agent counts as one of the required reviewers.", holds: true}
	one_commit:           {says: "An approval covers one specific commit.", holds: true}
	merge_queue:          {says: "The merge queue runs each check again on main with the change applied.", holds: true}
	no_circuit_breaker:   {says: "No circuit breaker yet that tightens approval when the reverts go up.", holds: true}
	incidents_as_eval:    {says: "Each past incident becomes a case of the evaluation of the reviewer.", holds: true}
	agent_noise:          {says: "Noise costs more when the author is an agent: it fixes every detail.", holds: true}
	fifty_rounds:         {says: "One PR went through more than 50 rounds of review and fixes in one night.", holds: true, value: 50, unit: "rounds"}
	old_code:             {says: "About 59 % of what the reviewer still flagged was there from its first pass.", holds: true, value: 59, unit: "%"}
	round_cap:            {says: "After 3 rounds, the reviewer asks the author to step back and rethink the approach.", holds: true, value: 3, unit: "rounds"}
	no_repeats:           {says: "The reviewer does not repeat a finding already posted.", holds: true}
}

retired: {}
