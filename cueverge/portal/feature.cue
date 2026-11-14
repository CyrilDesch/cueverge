package portal

import (
	"factory.local/kb/sealed/factory/actions"
)

// @what: Whether a step works today, read from the action that builds it.
#Today: {
	#action: string
	out: [
		if actions.actions[#action].status == "done" {"**Today: in place**"},
		"**Today: not yet.** It is the action “\(actions.actions[#action].title)”",
	][0]
}

// @what: A typical feature, step by step, in plain words.
featurePage: {
	slug:        "new-feature"
	title:       "A new feature, step by step"
	description: "What happens when we ask the factory for a feature. The example: let the agent of the first project read the files of the repository without being able to write them."
	footer:      "Each step says whether it works today. This mention comes from the status of the actions, not from a text written by hand."
	blocks: [
		{hint: {style: "info", md: #"""
			**In short.** A person says what they want and how to check it. An agent writes the code. A judge compares the result with a reference and with the version before. The agent says what it meant to do, and a person approves these few lines, not the code. If nothing breaks and the change does what it announces, it is kept. If not, it is refused. Everything is recorded.
			"""#}},

		{
			steps: [
				{title: "1. A person writes the request", blocks: [{md: #"""
					They say what they want: “the agent can read the files of the repository, never write them”.
					They add examples: an input, and the expected result.
					These examples become the measure. The request is done when they pass.
					"""#}]},

				{title: "2. They set the limits", blocks: [{md: #"""
					What already works must keep working.
					Each answer must arrive within the time budget that the initiative sets.
					These limits are written before the work. The machine checks them, not a review.
					"""#}]},

				{title: "3. We check that the request loosens nothing", blocks: [{md: #"""
					Adding examples makes the requirement stricter: this is allowed.
					Relaxing an existing limit needs the agreement of a person.
					\#((#Today & {#action: "lock_the_fixed_points"}).out).
					"""#}]},

				{title: "4. An agent gets a short task", blocks: [{md: #"""
					It does not get “do your best”. It gets a precise task: make these examples pass.
					A written rule chooses the task, not the agent.
					\#((#Today & {#action: "orchestration_table"}).out).
					"""#}]},

				{title: "5. The agent works in its own copy", blocks: [{md: #"""
					It does not touch the shared version.
					In its copy, it tries as much as it wants and runs the real check. It sees at once whether it breaks something.
					\#((#Today & {#action: "state_in_braid"}).out).
					"""#}]},

				{title: "6. The judge compares", blocks: [{md: #"""
					Each example goes through the new code and through the reference. The two answers are compared.
					The judge also compares with the version before: an example that passed must still pass.
					Last, it checks the intent of the agent: what it says it fixes is fixed, and what it breaks is announced.
					\#((#Today & {#action: "judge_in_cue"}).out).
					"""#}]},

				{title: "7. Nothing breaks: the change is kept", blocks: [{md: #"""
					It becomes the new reference. The next changes will be compared with it.
					Once kept, it does not go back. An error is fixed by a new change.
					"""#}]},

				{title: "8. Something breaks: the change is refused", blocks: [{md: #"""
					The shared version does not move.
					The refusal is recorded with its reason: the broken example, and the answer obtained.
					A change already refused must not come back as it is. \#((#Today & {#action: "state_in_braid"}).out).
					"""#}]},

				{title: "9. A doubtful case goes up to a person", blocks: [{md: #"""
					Sometimes an example “passed” by luck: the right error, for a wrong reason.
					The right fix breaks it. The machine does not decide alone: the agent announces the regression in its intent, with its reason.
					A person reads these few lines and approves. Without their agreement, nothing is kept.
					\#((#Today & {#action: "reviewed_intent"}).out).
					"""#}]},

				{title: "10. Everything is recorded, and the base updates itself", blocks: [{md: #"""
					For each attempt: what was asked, what the agent did, what it cost, the decision.
					The figures of the recent measures are computed from these traces. No one copies them.
					A text that talks about what just changed is flagged. It must be read again before the next publication.
					"""#}]},
			]
		},

		{
			group: {title: "Who does what", blocks: [{
				table: {
					columns: ["Who", "Role"]
					rows: [
						["A person", "Says what they want, how to check it, and what must never break. Approves the intents of the agents and decides the doubtful cases."],
						["An agent", "Writes the code, in its copy, on a precise task."],
						["The judge", "Compares, and keeps or refuses. It does not guess: it applies rules written beforehand."],
						["The base", "Records everything. Computes its figures from the traces. Flags what is no longer true."],
					]
				}
			}]}
		},
	]
}
