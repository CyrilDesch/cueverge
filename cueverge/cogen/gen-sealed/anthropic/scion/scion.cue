// @what: binds each sealed fact on Scion to a block of the captured article. A recapture that moves or changes a block fails here.
// @ref: @/cueverge/sealed/anthropic/scion/scion.cue
// @ref: @/cueverge/gen/web/anthropic-scion/page.gen.cue
package scion

import (
	"github.com/cyrildesch/cueverge/kinds"
	s "factory.local/kb/sealed/anthropic/scion"
	page "factory.local/kb/gen/web/anthropic-scion:web"
)

_p: {source: page.source, blocks: page.blocks}

rules: kinds.#Cover & {sealed: s, by: {
	bottleneck:          kinds.#Mentions & {page: _p, at: 7, terms: ["bottleneck", "built for human scale", "source control, builds, and CI"]}
	merges_may:          kinds.#Number & {page: _p, at: 8, re: "In May 2026, Anthropic averaged around ([0-9,]+) code changes merged per day"}
	merges_september:    kinds.#Number & {page: _p, at: 8, re: "as of September, we merged over ([0-9,]+) per day"}
	migration:           kinds.#Mentions & {page: _p, at: 10, terms: ["we built Scion", "fully migrated our monorepo from git in five months"]}
	antique_same_period: kinds.#Mentions & {page: _p, at: 10, terms: ["code review surface (called Antique)", "all in that same time period"]}
	history:             kinds.#Number & {page: _p, at: 14, re: "main branch alone is almost ([0-9]+) GB"}
	ci_checkouts:        kinds.#Number & {page: _p, at: 14, re: "on the order of ([0-9]+) million code checkouts per day for CI"}
	naive_traffic:       kinds.#Number & {page: _p, at: 14, re: "over ([0-9]+) PB of git traffic per day"}
	mirrors:             kinds.#Quote & {page: _p, at: 15, quote: "we operated several hundred internal git mirrors"}
	agent_clients:       kinds.#Quote & {page: _p, at: 17, quote: "nearly all of our clients were agents and jobs that are online by definition"}
	prior_art:           kinds.#Mentions & {page: _p, at: 19, terms: ["prior art", "Google’s Piper", "Meta’s Sapling"]}
	mononoke:            kinds.#Mentions & {page: _p, at: 62, terms: ["server component of Sapling, Mononoke", "pioneered many of the techniques we use in Scion"]}
	always_online:       kinds.#Mentions & {page: _p, at: 20, terms: ["Clients are always online", "a server that is always reachable", "fetch data when they need it"]}
	server_computes:     kinds.#Mentions & {page: _p, at: 21, terms: ["the server answers questions about file history and blame", "creates commits, performs merges and rebases", "bounded local object cache"]}
	all_in_api:          kinds.#Quote & {page: _p, at: 22, quote: "all of the source control queries the client uses are also exposed via API, so in many cases jobs don’t need a local repository at all"}
	commit_cost:         kinds.#Quote & {page: _p, at: 24, quote: "has to scale with the size of the change, not the overall size of the repo"}
	refs_discouraged:    kinds.#Mentions & {page: _p, at: 24, terms: ["discourages refs", "except for the main ref or release branches", "global state that every server has to agree on"]}
	changeset:           kinds.#Quote & {page: _p, at: 29, quote: "the unit of work is a “changeset,” an entry in a write-ahead log"}
	content_addressing:  kinds.#Quote & {page: _p, at: 35, quote: "All source control data is content-addressed, so a piece of data never changes once it’s stored, and any server can cache it without checking with the others"}
	lock_free:           kinds.#Quote & {page: _p, at: 31, quote: "no packfiles to accept, no locking or cross-server coordination, and no refs to move around"}
	ref_cas:             kinds.#Quote & {page: _p, at: 31, quote: "a compare-and-swap on a single Spanner row"}
	derived_data:        kinds.#Quote & {page: _p, at: 32, quote: "its value for a changeset is computed from its values for that changeset’s parents"}
	cache:               kinds.#Number & {page: _p, at: 41, re: "cache hit rate of over ([0-9]+)%"}
	footprint:           kinds.#Number & {page: _p, at: 41, re: "footprint is now ([0-9]+)x smaller than our previous git mirroring infrastructure in terms of CPU and memory"}
	checkout_seconds:    kinds.#Quote & {page: _p, at: 41, quote: "in seconds rather than minutes"}
	ci_cpu:              kinds.#Number & {page: _p, at: 41, re: "CI alone realized a ([0-9]+)% CPU capacity win"}
	rewritten_ingestion: kinds.#Number & {page: _p, at: 44, re: "consumed ([0-9]+)x less memory"}
	team:                kinds.#Number & {page: _p, at: 47, re: "A team of ([a-z]+) people built both Scion and Antique"}
	volume_x10:          kinds.#Number & {page: _p, at: 47, re: "volume of code merged per day increased by ([0-9]+)x"}
	intent_review:       kinds.#Quote & {page: _p, at: 48, quote: "they now examine the intent of the change as opposed to reading every line of code"}
	engineers_say_no:    kinds.#Quote & {page: _p, at: 48, quote: "the role of the engineers was to tell Claude “no.”"}
	performance_figure:  kinds.#Mentions & {page: _p, at: 50, terms: ["Observed performance improvements"]}
	semantic_approvals:  kinds.#Mentions & {page: _p, at: 51, terms: ["complex semantic constraints on approvals", "comment-only changes", "sensitive logical changes"]}
	no_queue_lock:       kinds.#Mentions & {page: _p, at: 53, terms: ["global repository lock on the merge queue", "post-merge and pre-deploy automated testing"]}
	conflicts:           kinds.#Quote & {page: _p, at: 53, quote: "Claude can typically fix these conflicts faster than humans can even identify them"}
	not_for_everyone:    kinds.#Quote & {page: _p, at: 56, quote: "Scion is by no means a suitable replacement for git for general use"}
	no_public_version:   kinds.#Mentions & {page: _p, at: 57, terms: ["difficult to offer Scion", "a public version", "wouldn’t actually be very useful"]}
}}
