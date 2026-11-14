// @what: the part of the kernel that decides. An initiative imports it and fills in its own values.
// @what: the shapes. What an initiative declares, what the extractor keeps of an answer, and the verdicts.
package rules

import "strings"

// @what: what an initiative declares. The kernel reads it to know what to run, the rules to know what to demand.
#Initiative: {
	name: string
	// @what: the cases, one file per case.
	cases: glob: string
	// @what: the reference. It is pinned and deterministic, so its answers are cached.
	oracle: #Command
	// @what: the thing under construction. Exit 0 is a value, 1 a rejected input, 3 an unsupported feature, else a crash.
	candidate: #Command & {
		// @invariant: every answer arrives within budgetMs. Zero means no budget.
		budgetMs: int & >=0 | *0
		// @what: a case the rules find late is timed again, one at a time after the parallel phase, up to this many times.
		timing: retries: int & >=0 | *0
	}
	judge: #DifferentialJSON
	// @what: the stochastic side. What generates the candidate, and within what frame.
	generator?: #Generator
}

// @what: Claude Code, run headless between two rounds.
#Generator: {
	model: string | *"sonnet"
	// @what: the spend limit of one generation, in USD.
	maxBudgetUsd: number & >0 | *1
	// @what: the generations in one run of the loop.
	maxRounds: int & >0 | *3
	// @invariant: the one file the generator may edit. Everything else is a fixed point.
	source: string
	// @what: what the generator may do besides editing source, as Claude Code permission rules.
	allow: [...string]
	// @what: what the generator is told every time. The kernel adds the failing cases, then the intent request.
	instructions: string
	// @what: how an intent is approved.
	intent: #IntentPolicy
	// @what: the walls of a generation. The kernel runs claude -p in the sandbox runtime with them, never without it.
	sandbox: #Sandbox
	// @invariant: every folder the generator may write holds its source. No other part of the repository is writable.
	sandboxed: {for w in sandbox.write {(w): strings.HasPrefix(source, w + "/") & true}}
}

// @what: what the operating system lets a generation write and reach. Everything else is refused, its scratch folder aside.
#Sandbox: {
	// @what: the folders the generator may write.
	write: [string, ...string]
	// @what: the files a filtered round writes in the initiative. A real round rewrites them before it decides.
	files: [...(string & =~"/observed\\.gen\\.cue$")]
	// @what: the domains the generator may reach.
	domains: [string, ...string]
}

#Command: {
	// @what: the case placeholder is replaced by the path of the case.
	cmd:       [string, ...string]
	timeoutMs: int & >0 | *10000
	...
}

// @what: what the extractor keeps of one answer. Two hashes, of the text as given and of the value.
// @why: field order counts in the text hash and not in the value hash.
#Answer: {
	exit:    int
	timeout: bool | *false
	// @what: on exit 0 only, the hashes of the output. Empty when the output is not JSON.
	text:  string | *""
	value: string | *""
	// @what: what the command wrote on stderr. A rejection names its places there.
	err: string | *""
	// @what: each timing taken, in ms.
	ms: [...int]
}

#Observed: [string]: {
	oracle:    #Answer
	candidate: #Answer
}

// @what: the verdicts, best first. A false accept is the worst, a value where the oracle rejects the input.
verdictOrder: [
	"perfect",         // same value, same field order
	"acceptable",      // same value, different field order
	"error-same",      // both reject the input, at the same place
	"error-unlocated", // both reject the input, one side gives no place
	"error-elsewhere", // both reject the input, at different places
	"wrong",           // both give a value, the values differ
	"false-reject",    // the candidate rejects a valid input
	"false-accept",    // the candidate accepts an invalid input
	"unsupported",     // the candidate says: not built yet
	"crash",           // the candidate failed internally
	"timeout",
	"late",            // the answer is right, and it breaks the time budget
]
#Verdict: or(verdictOrder)

// @what: a verdict that counts as done.
passing: ["perfect", "acceptable", "error-same", "error-unlocated"]
#Passes: or(passing)
