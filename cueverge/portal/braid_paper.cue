package portal

// @what: a research note on Braid as the state of the factory, with a sealing step driven by tests.
// @what: a design, not a result. Its section 7 lists what to measure.
braidPaper: {
	slug:        "braid-for-the-factory"
	title:       "Braid as the state of the factory: sealing by test"
	description: "Design note of 2026-11-12. Two zones are enough: “to test” is a view of the open zone, “deployed” a marker on the sealed zone."
	footer:      "Sources: the code and the tests of the Braid module. No measure of this note has been made yet."
	blocks: [
		{hint: {style: "info", md: #"""
			**Summary.** The factory must integrate fast, test continuously and never lose a constraint.
			We propose to carry its state with Braid, without changing it: a block is a batch of changes, the open zone carries the candidates and the chain in trial, the sealed zone carries the acquired trunk.
			Sealing is a fact that the judge publishes when the continuous test has held, by a rule written beforehand.
			Main result: **three states, but two zones**. “To test” is a view of the open zone. “Deployed” is a height in the sealed zone.
			"""#}},
		{hint: {style: "warning", md: "**Status.** A design by reasoning on the code of Braid. Nothing has run. Section 7 gives six predictions, each with its measure and its verdict."}},

		{group: {title: "1. Problem", blocks: [{md: #"""
			The first example, cue-interpreter, showed two gaps.

			- **With no isolation, we do not know who breaks things.** One pass of grouped fixes brought 8 regressions, with no possible attribution.
			- **With no continuous test, we do not see the interactions.** Two changes that are green on their own can be red together.

			So we need two stages: an isolated test per change, and a continuous test on the whole.
			It remains to say where the state lives between the two: which changes are proposed, which ones are in trial together, which ones are acquired.
			This state must stay the same whatever the order in which the reports arrive, or the orchestration is not reproducible.
			"""#}]}},

		{
			group: {title: "2. Braid in short", blocks: [
				{md: "Braid is a structure with two zones of blocks. A block has a key, a parent, a height and a value. `Settle` is the only step that moves a block."},
				{
					table: {
						columns: ["Rule", "Statement", "Source"]
						rows: [
							["One place per height", "The sealed zone holds at most one block per height.", "Invariant of the module"],
							["Sealing goes down", "A sealed block seals its open parents.", "Step `Settle`"],
							["Lost without a trace", "An open block at a sealed height, other than the sealed block, leaves the zone.", "Step `Settle`"],
							["The child waits", "The child of a lost block stays, until its own height is sealed.", "Step `Settle`, invariant"],
							["The gap is a level", "`gaps` gives the missing parents above the sealed tip. A lost request comes back.", "Function `gaps`"],
							["The join is a lattice", "`join` is associative, commutative and idempotent.", "Tests of the module, random states"],
							["The structure ignores the values", "`Settle` and `gaps` read the keys, the parents and the heights. Never a value.", "Interface `Merge` of the module"],
						]
					}
				},
				{md: "The last rule matters here: Braid does not decide to seal. It receives a sealed block and draws the consequences."},
			]}
		},

		{
			group: {title: "3. Mapping", blocks: [
				{
					table: {
						columns: ["Braid", "Factory"]
						rows: [
							["Block", "A **batch**: a set of changes. An isolated candidate is a batch of a single change."],
							["Parent", "The batch that this one was built on."],
							["Height", "The rank of the batch in the trunk."],
							["Open value", "The content of the batch, its owner, and the verdicts received."],
							["`Merge` of the open value", "The union of the verdicts. Two testers on the same batch do not get in each other's way."],
							["Sealed value, by `Absorb`", "The content and the proof kept. The raw observations stay in the journal."],
							["Open zone", "All the proposed batches, the chain in trial among them."],
							["Sealed zone", "The acquired trunk."],
							["`gaps`", "The parents that a batch names and that the state does not have: the work to ask for."],
							["`freeze`", "Forgetting the old history of the trunk."],
						]
					}
				},
				{md: #"""
					```mermaid
					flowchart LR
					  subgraph sealed["Sealed zone: acquired trunk"]
					    batch41["batch 41"] --> batch42["batch 42"]
					  end
					  subgraph open["Open zone"]
					    batch43["batch 43: a + b + c"] --> batch44["batch 44: d"]
					    aAlone["43: a alone"]
					    eAlone["43: e alone, red"]
					  end
					  batch42 --> batch43
					  batch42 --> aAlone
					  batch42 --> eAlone
					  deployed(["“deployed” marker"]) -.-> batch41
					  trial(["head in trial"]) -.-> batch44
					```

					Batches 43 and 44 form the chain in trial. If the judge seals 44, the rule “sealing goes down” seals 43, and the batches “a alone” and “e alone” are lost: their height is taken.
					The change `a` lives in the sealed batch. The change `e` must be fixed and proposed again at height 45.
					"""#},
			]}
		},

		{
			group: {title: "4. Two zones or three?", blocks: [
				{md: #"""
					The first proposal has three zones: **Open**, **To test**, **Deployed**. The three states are right. The question is whether each one needs a zone.

					A zone of Braid is defined by what a block can go through in it.

					- **Open zone.** Several blocks per height. A block can be lost.
					- **Sealed zone.** One block per height. A block never leaves it.

					“To test” must choose between the two, by what happens to a batch that fails.
					"""#},
				{
					table: {
						columns: ["If a batch in trial fails", "Then “To test” is", "And “Deployed” is"]
						rows: [
							["We remove it", "In the open zone: it is a chain chosen among the open batches, so a **view**.", "The sealed zone."],
							["We never remove, we fix on top", "In the sealed zone, since nothing leaves it.", "A chain with no fork above a chain with no fork: a simple **height marker**."],
						]
					}
				},
				{md: #"""
					In both cases, the third zone reduces to something else: a view, or an integer. A real third zone would need a block that is neither losable nor final, and we have not found one.

					**Proposal.** We take the first line, and we keep the marker of the second.

					| State | Where it lives | Who sets it |
					|---|---|---|
					| Open | Open zone | Each agent, by publishing its batch |
					| To test | Open zone, the chosen chain | The orchestration table, a pure function of the state |
					| Acquired | Sealed zone | The judge, by a sealing fact |
					| Deployed | A height in the sealed zone | The deployment cadence, or a human |

					It is the shape of Ethereum, for which Braid was written: the head of the chain is a choice among the open blocks, finality comes after. It is also that of the phases of Mercurial: a “draft” change can be rewritten, a “public” change no longer moves.

					Removal becomes free. A red batch is never sealed, another batch takes its height, and the rule “lost without a trace” cleans up.
					"""#},
			]}
		},

		{
			group: {title: "5. Sealing", blocks: [
				{md: "Sealing is the only point of synchronization. All the rest is publishing facts, in any order."},
				{
					steps: [
						{title: "An agent publishes a batch", blocks: [{md: "It works in an isolated copy, on the current head. Its batch names this head as its parent. The verdicts of the isolated test go with the batch."}]},
						{title: "The table chooses the chain in trial", blocks: [{md: "A deterministic rule on the state: at the next height, it forms a batch with all the candidates whose isolated test is green. This batch is a block like any other."}]},
						{title: "The continuous test runs on the head", blocks: [{md: "Each round publishes its verdicts. They are added to the value of the batch by union. The agents already build on this head: they do not wait."}]},
						{title: "The judge seals", blocks: [{md: "When the sealing rule holds, the judge publishes the fact “batch k sealed”. Braid seals the open parents of k and removes the competing batches."}]},
						{title: "The deployment marker follows", blocks: [{md: "It goes up in the sealed zone at its own cadence. The scheduled exercises, such as the restart on two data centers, are played between the sealed tip and this marker."}]},
					]
				},
				{md: #"""
					**The sealing rule is a fixed point.** It is written before the round, and an agent can only make it stricter. Proposed form: *a batch is sealed after N consecutive complete rounds with no failing verdict, with all the constraints of “continuous” cadence measured.*

					**We test the tip, we seal the chain.** Sealing batch 44 seals batch 43. So we do not check each intermediate batch: this is the simplification we look for, obtained from the structure.

					**The delay N sets a trade-off.** Short, a slow defect gets into the acquired trunk. Long, more work is built on a head that can fall.
					"""#},
			]}
		},

		{
			group: {title: "6. When it breaks", blocks: [
				{
					table: {
						columns: ["Case", "What happens", "Cost"]
						rows: [
							["The head in trial turns red", "The table publishes two half-batches at the same height. The first one that holds is extended then sealed, the other is lost or cut again.", "One round per cut."],
							["Work rested on the red head", "Its batches wait, then are lost when their height is sealed. Their changes are proposed again on the new head.", "The rate of orphans."],
							["A defect shows up in the acquired trunk", "Nothing leaves the sealed zone. We fix it with a new batch. If a function is dropped, the batch carries a tombstone with its constraint.", "One more batch."],
							["Two agents do the same work", "Two batches at the same height: only one is sealed. The leases limit the case, Braid makes it safe.", "The work of the loser."],
							["The orchestrator goes down", "We replay the journal of the facts. The order does not matter.", "The time of the replay."],
						]
					}
				},
			]}
		},

		{
			group: {title: "7. What to measure", blocks: [
				{md: "Each line is a prediction of the model. A single contrary measure refutes it."},
				{
					table: {
						columns: ["Prediction", "Measure", "Verdict"]
						rows: [
							["The order does not matter", "Replay the journal of a session in 100 random orders.", "A final state or a decision of the table that differs: refuted."],
							["A duplicate costs nothing", "Replay the journal with each fact twice.", "A different state: refuted."],
							["Recovery is a replay", "Kill the orchestrator during a session, replay.", "A state different from the session with no failure: refuted."],
							["Attribution is logarithmic", "A red batch of N changes with a single culprit: count the rounds.", "More than ⌈log₂ N⌉ rounds: refuted."],
							["Orphans stay rare", "Share of the batches built on a head that is lost afterwards.", "Above 20 %: seal earlier, or build on the acquired trunk only."],
							["Two zones are enough", "Keep the list of the states met on a project.", "A state that is neither a view nor a marker: a third zone is needed."],
						]
					}
				},
				{md: "The first three are tested with no agent, on a recorded journal. This is where to start: [carry the state of the orchestrator with Braid](\(_href.action.state_in_braid))."},
			]}
		},

		{group: {title: "8. Limits", blocks: [{hint: {style: "warning", md: #"""
			- **One parent per block.** Braid is a forest. So combining is done by a batch at the same height, not by a merge node. The candidates taken into a batch are “lost” as blocks while their content is acquired: the journal must keep this link.
			- **Sealing comes from outside.** Braid applies the decision, it does not make it. All the safety rests on the rule of the judge and on the stability of the verdicts.
			- **An unstable verdict blocks everything.** On cue-interpreter, the time verdict flipped with the load. With the rule of N rounds, such a verdict prevents sealing. The stability of the verdicts comes first.
			- **Long work rebases often.** The height is the rank in the trunk: each sealing forces the competing batches to be proposed again.
			- **Several culprits in a batch.** Cutting in two is logarithmic only for a single culprit, with no interaction between changes.
			- **A single language, since the rewrite of the kernel.** Braid and the kernel are in Scala: the kernel can use Braid directly. The code of the batches lives in jj, and Braid carries their keys, parents, heights and verdicts.
			"""#}}]}},

		{
			group: {title: "9. Related work", blocks: [{
				table: {
					columns: ["System", "What it shares", "What differs here"]
					rows: [
						["Ethereum, head and finality", "A head chosen among the open blocks, irreversible finality.", "Finality comes from a judge of tests, not from a vote."],
						["Mercurial and jj, phases", "“draft” can be rewritten, “public” no longer moves.", "The change of phase is guarded by a measured rule."],
						["Merge queue (bors)", "Test the batch, cut it in two if it breaks.", "The agents build on the head without waiting for the verdict."],
						["Spawn", "No review per change, frequent testing of the trunk.", "An isolated stage to attribute, and an acquired trunk that does not go back."],
					]
				}
			}]}
		},
	]
}
