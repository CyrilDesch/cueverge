// @what: binds each sealed fact on the Claude Code review article to a block of the captured page.
// @ref: @/cueverge/sealed/anthropic/claude-code-review/review.cue
// @ref: @/cueverge/gen/web/claude-code-review/page.gen.cue
package review

import (
	"github.com/cyrildesch/cueverge/kinds"
	s "factory.local/kb/sealed/anthropic/claude-code-review:review"
	page "factory.local/kb/gen/web/claude-code-review:web"
)

_p: {source: page.source, blocks: page.blocks}

rules: kinds.#Cover & {sealed: s, by: {
	claude_writes:        kinds.#Number & {page: _p, at: 2, re: "Claude writes about ([0-9]+) percent of Claude Code"}
	reverts:              kinds.#Number & {page: _p, at: 3, re: "the share that had to be reverted fell by more than ([0-9]+) percent"}
	prs_doubled:          kinds.#Quote & {page: _p, at: 3, quote: "merged pull requests to Claude Code's codebase more than doubled"}
	names_antique:        kinds.#Absent & {page: _p, term: "Antique"}
	at_most_one_human:    kinds.#Quote & {page: _p, at: 18, quote: "merge with at most one human in the loop"}
	guardrail:            kinds.#Quote & {page: _p, at: 18, quote: "Revert and incident rates are the guardrail"}
	show_the_output:      kinds.#Quote & {page: _p, at: 25, quote: "ask it to show the output instead of saying it's done"}
	fix_at_the_source:    kinds.#Mentions & {page: _p, at: 28, terms: ["we fix it at the source", "lint rule", "instructional files"]}
	comments_before:      kinds.#Number & {page: _p, at: 34, re: "substantive review comments went from ([0-9]+)% to"}
	comments_after:       kinds.#Number & {page: _p, at: 34, re: "substantive review comments went from [0-9]+% to ([0-9]+)%"}
	agent_vote:           kinds.#Mentions & {page: _p, at: 35, terms: ["Several agents look for bugs at the same time", "a separate group votes on each finding"]}
	every_finding:        kinds.#Quote & {page: _p, at: 36, quote: "Every finding has to be answered. You either fix it or resolve the thread with a reason."}
	security_blocks:      kinds.#Quote & {page: _p, at: 38, quote: "A PR can't merge while any finding from the bug review or the security review is still open"}
	low_risk:             kinds.#Quote & {page: _p, at: 49, quote: "None required once automated review and security checks are green"}
	medium_risk:          kinds.#Mentions & {page: _p, at: 52, terms: ["One person"]}
	high_risk:            kinds.#Mentions & {page: _p, at: 55, terms: ["Two people"]}
	classifier:           kinds.#Quote & {page: _p, at: 56, quote: "The change sets the tier, not the author. A classifier reads the change and picks its risk tier."}
	agent_does_not_count: kinds.#Quote & {page: _p, at: 57, quote: "An agent's approval never counts as a person's"}
	director_is_reviewer: kinds.#Quote & {page: _p, at: 58, quote: "the person directing the agent counts as one of the required reviewers"}
	one_commit:           kinds.#Quote & {page: _p, at: 59, quote: "An approval covers one specific commit"}
	merge_queue:          kinds.#Quote & {page: _p, at: 61, quote: "The merge queue re-runs every check against main with the change applied"}
	no_circuit_breaker:   kinds.#Quote & {page: _p, at: 64, quote: "We don't yet have circuit breakers that tighten approval when those numbers move"}
	incidents_as_eval:    kinds.#Quote & {page: _p, at: 68, quote: "Any incidents are now an eval"}
	agent_noise:          kinds.#Mentions & {page: _p, at: 71, terms: ["Noise costs more when the author is an agent", "An agent fixes it"]}
	fifty_rounds:         kinds.#Number & {page: _p, at: 72, re: "more than ([a-z]+) rounds of review and fixes overnight"}
	old_code:             kinds.#Number & {page: _p, at: 73, re: "about ([0-9]+)% of it was code that had been there since the reviewer's first pass"}
	round_cap:            kinds.#Number & {page: _p, at: 75, re: "After ([a-z]+) rounds, the reviewer asks the author to step back"}
	no_repeats:           kinds.#Quote & {page: _p, at: 78, quote: "No repeats of findings already posted"}
}}
