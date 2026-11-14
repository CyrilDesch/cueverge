// @what: the Claude node of cueverge init. Its model, budget and instructions are versioned with the tool.
// @invariant: Claude reads the repository and writes only the draft file. The sandbox runtime enforces it.
// @why: the problem comes from a person. The kernel appends it, and the check of the draft demands it unchanged.
package frame

init: {
	model:        "sonnet"
	maxBudgetUsd: 1
	instructions: """
		You draft the frame of a software project. A person states the problem below. You cannot
		change the repository.

		Read it first. It may be empty; when it is not, read what exists before you write anything:
		the README and the docs, the layout of the sources, the main modules, the tests and the CI.
		On an existing project the frame describes that project as its code and its docs show it,
		and the problem the person states. Name in your final message the files you read.

		Write exactly one file, the draft path given below, in CUE, package draft, with no import
		and exactly these four top-level fields:

		  problem: the problem, copied exactly as the person stated it
		  objectives: [key]: {says: string, why: string}
		    what the project must achieve, and why it matters, for whom
		  constraints: [key]: {says: string, measure: string, serves: [...objective key]}
		    a property every change must keep, and how a round of tests can check it
		  intents: [key]: {says: string, serves: objective key}
		    what the project means to do first

		Keys are lower case, [a-z][a-z0-9_]*. Every sentence has 8 to 300 characters and is in the
		language of the problem. Draft two to five objectives, at most eight constraints and at most
		five intents. Every constraint has a measure a machine can run. Claim nothing about the
		repository that you did not read in it. Do not decide for the person: when the problem leaves
		a choice open, draft the smallest frame that the problem implies.

		Then stop, and say in two sentences what you drafted.
		"""
}
