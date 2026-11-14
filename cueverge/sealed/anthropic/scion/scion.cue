// @what: what the Anthropic article on Scion states. Every fact is attributed to Anthropic, and none is checked against the world.
// @ref: @/cueverge/cogen/gen-sealed/anthropic/scion/scion.cue
// @ref: @/cueverge/gen/web/anthropic-scion/page.gen.cue
package scion

import "github.com/cyrildesch/cueverge/schema"

schema.#Sealed

_attributedTo: "Anthropic, “Redesigning source control at Anthropic”"
facts: [string]: attributedTo: _attributedTo

facts: {
	bottleneck:          {says: "The bottleneck is no longer writing code, but the tools built for a human pace: source control, builds, CI.", holds: true}
	merges_may:          {says: "In May 2026, about 2,500 changes merged per day in the monorepo.", holds: true, value: 2500, unit: "per day"}
	merges_september:    {says: "In September 2026, more than 30,000 changes merged per day.", holds: true, value: 30000, unit: "per day"}
	migration:           {says: "Scion replaces git for the monorepo, with a complete migration in five months.", holds: true}
	antique_same_period: {says: "Antique, the review tool, was built in the same period.", holds: true}
	history:             {says: "The history of the main branch weighs almost 100 GB.", holds: true, value: 100, unit: "GB"}
	ci_checkouts:        {says: "In the order of 25 million checkouts per day for CI alone.", holds: true, value: 25, unit: "million per day"}
	naive_traffic:       {says: "With no trick, it would be more than 600 PB of git traffic per day.", holds: true, value: 600, unit: "PB per day"}
	mirrors:             {says: "At the peak, several hundred internal git mirrors.", holds: true}
	agent_clients:       {says: "Almost all the clients are agents and jobs, online by definition.", holds: true}
	prior_art:           {says: "Scion takes the lessons of Piper (Google) and Sapling (Meta).", holds: true}
	mononoke:            {says: "Mononoke, the server of Sapling, invented many of the techniques of Scion.", holds: true}
	always_online:       {says: "The server is always reachable; the client fetches the data when it needs it.", holds: true}
	server_computes:     {says: "The server computes history, blame, commits, merges and rebases; the client keeps a bounded cache.", holds: true}
	all_in_api:          {says: "Each query of the client is also an API: many jobs need no copy at all.", holds: true}
	commit_cost:         {says: "The cost of a commit follows the size of the change, not that of the repository.", holds: true}
	refs_discouraged:    {says: "Refs are discouraged, except main and the release branches: a global state does not scale.", holds: true}
	changeset:           {says: "A changeset is an entry of a write-ahead log.", holds: true}
	content_addressing:  {says: "The content is addressed by its hash: stored data never changes, and any server can cache it.", holds: true}
	lock_free:           {says: "Accepting a changeset needs no lock, no coordination between servers, and no ref to move.", holds: true}
	ref_cas:             {says: "Moving a ref is a compare-and-swap on a single Spanner row.", holds: true}
	derived_data:        {says: "Each derived datum is computed from its values for the parents of the changeset.", holds: true}
	cache:               {says: "Each cache tier has a hit rate of more than 99 %.", holds: true, value: 99, unit: "%"}
	footprint:           {says: "The infrastructure of Scion is 200 times smaller than the git mirrors, in CPU and in memory.", holds: true, value: 200, unit: "times"}
	checkout_seconds:    {says: "A CI checkout takes seconds instead of minutes.", holds: true}
	ci_cpu:              {says: "CI alone gains 25 % of CPU capacity.", holds: true, value: 25, unit: "%"}
	rewritten_ingestion: {says: "Rewritten by Claude, the ingestion pipeline uses 20 times less memory.", holds: true, value: 20, unit: "times"}
	team:                {says: "A team of seven people built Scion and Antique.", holds: true, value: 7, unit: "people"}
	volume_x10:          {says: "In that time, the volume of code merged per day was multiplied by 10.", holds: true, value: 10, unit: "times"}
	intent_review:       {says: "People review the intent of each change, not each line.", holds: true}
	engineers_say_no:    {says: "Often, the role of the engineers is to say no to Claude.", holds: true}
	performance_figure:  {says: "A figure shows the performance gains observed on the repositories native to Scion.", holds: true}
	semantic_approvals:  {says: "The approval rules tell a comment-only change apart from a sensitive logic change.", holds: true}
	no_queue_lock:       {says: "No global lock on the merge queue: tests after the merge and before the deployment.", holds: true}
	conflicts:           {says: "Claude fixes conflicts faster than a person can spot them.", holds: true}
	not_for_everyone:    {says: "Scion is not a replacement for git for general use.", holds: true}
	no_public_version:   {says: "A public version of Scion would be difficult to offer and of little use.", holds: true}
}

retired: {
	agent_checkout_7_1_min: {
		was:     "A working copy for an agent goes from 7.1 min to 5.1 s."
		why:     "Not in the text of the article. Only the caption of a figure talks about performance, and an image is not captured."
		against: "3ba5fcf6cdf1ab1bc78aeb00278d792819b87c7e1860aeb0e6f6351c0716dcbe"
	}
	source_control_34_min: {
		was:     "The source control time per change goes from 34 min to 3.7 min."
		why:     "Not in the text of the article. Only the caption of a figure talks about performance, and an image is not captured."
		against: "3ba5fcf6cdf1ab1bc78aeb00278d792819b87c7e1860aeb0e6f6351c0716dcbe"
	}
}
