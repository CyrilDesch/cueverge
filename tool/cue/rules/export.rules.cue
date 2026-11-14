// @what: what we keep of the journal. An export is the versioned projection that a person or the base reads.
// @why: the raw journal is the Kyo Flow store. It repeats every observation and is not versioned.
// @invariant: an export that the raw journal does not give is bottom, so an export is backed by its journal.
package rules

import (
	"encoding/json"
	"strings"
)

// @what: from the raw journal of a package to its exports.
#Exports: {
	executions: [string]: _
	traces: [string]:     _

	// @why: inside out, the names executions and traces are fields of out, hence the aliases.
	let ex = executions
	let tr = traces
	out: {
		executions: {
			for id, e in ex if e.flow == "round" if e.fields.decision != _|_ {
				(id): (#RoundExport & {
					raw: e...
				}).out...
			}
			for id, e in ex if e.flow == "generate" if e.fields.fixedAfter != _|_ {
				(id): (#GenerateExport & {
					raw: e...
				}).out...
			}

			// @why: an init is exported once its draft vets. It then waits for a person, and its approval is another execution.
			for id, e in ex if e.flow == "init" if e.fields.vet != _|_ {
				(id): (#InitExport & {
					raw: e...
				}).out...
			}
		}
		traces: {
			// @why: a session is exported once it is over. A live session still grows, and an export is written once.
			for session, t in tr if len([for _, m in t if m.type == "result" {
				m...
			}]) > 0 {
				(session): (#TraceExport & {
					raw: t...
				}).out...
			}
		}
	}
}

// @what: the time of the first event of a kind, or the empty string.
#When: {
	events: _
	kind:   string
	out: [for _, e in events if e[kind] != _|_ {
		e[kind].timestamp...
	}, ""][0]
}

// @what: at most n runes, then an ellipsis.
#Clip: {
	s:   string
	n:   int
	out: [if len(strings.Runes(s)) > n {strings.SliceRunes(s, 0, n) + "…"}, s][0]
}

#RoundExport: {
	raw: _
	let f = raw.fields
	let s = f.retime.value.summary
	out: {
		flow:       "round"
		started:    (#When & {events: raw.events, kind: "Created"}).out
		completed:  (#When & {events: raw.events, kind: "Completed"}).out
		initiative: f.initiative.value.name
		summary: {
			cases:        s.cases
			valid:        s.valid
			validCorrect: s.validCorrect
			count: {for c in s.count if c.n > 0 {
				(c.verdict): c.n...
			}}
			failing:   s.failing
			late:      s.late
			regressed: s.regressed
		}
		verdicts: f.retime.value.verdicts
		// @why: rounds before the intent rules have no intent.
		if f.intent != _|_ {intent: f.intent.value}
		decision: f.decision.value
	}
}

#GenerateExport: {
	raw: _
	let f = raw.fields
	let c = f.claude.value
	out: {
		flow:      "generate"
		started:   (#When & {events: raw.events, kind: "Created"}).out
		completed: (#When & {events: raw.events, kind: "Completed"}).out
		brief:     f.brief.value
		claude: {
			model:   c.model
			outcome: c.outcome
			isError: c.isError
			costUsd: c.costUsd
			turns:   c.turns
			seconds: c.seconds
			session: c.session
			result:  c.result
			denied: [for d in c.denied {
				let x = json.Unmarshal(d)
				tool:  x.tool_name
				input: (#Clip & {s: json.Marshal(x.tool_input), n: 300}).out
			}]
		}
		patch:      f.patch.value
		fixedMoved: f.fixedBefore.value != f.fixedAfter.value
	}
}

// @what: an init. The problem of a person, the files the scaffold created, the draft of Claude, its hash, and the approval.
#InitExport: {
	raw: _
	let f = raw.fields
	let c = f.draft.value.generation
	out: {
		flow:      "init"
		started:   (#When & {events: raw.events, kind: "Created"}).out
		completed: (#When & {events: raw.events, kind: "Completed"}).out
		problem:   f.problem.value
		scaffold:  f.scaffold.value.created
		draft: {
			model:   c.model
			outcome: c.outcome
			isError: c.isError
			costUsd: c.costUsd
			turns:   c.turns
			seconds: c.seconds
			session: c.session
			result:  c.result
			text:    f.draft.value.text
		}
		hash: f.vet.value.hash
		if f.approval != _|_ {approval: f.approval.value}
		if f.adopted != _|_ {adopted: f.adopted.value.files}
	}
}

// @what: a Claude Code session, as the sequence of what it did.
#TraceExport: {
	raw: _
	out: {
		steps: [
			for _, m in raw if m.type == "assistant"
			for c in m.message.content if c.type == "tool_use" {
				tool:  c.name
				input: (#Clip & {s: json.Marshal(c.input), n: 300}).out
			},
		]
		said: [
			for _, m in raw if m.type == "assistant"
			for c in m.message.content if c.type == "text" {
				c.text...
			},
		]
		errors: [
			// @why: successive guards, because `&&` evaluates both sides.
			for _, m in raw if m.type == "user"
			if (m.message.content & [...]) != _|_
			for c in m.message.content
			if c.is_error != _|_
			if c.is_error {
				(#Clip & {
					s: [if (c.content & string) != _|_ {
						c.content...
					}, json.Marshal(c.content)][0]...
					n: 300
				}).out...
			},
		]
		result: [for _, m in raw if m.type == "result" {
			outcome: m.subtype
			turns:   m.num_turns
			costUsd: m.total_cost_usd
		}, {}][0]
	}
}
