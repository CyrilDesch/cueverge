// @what: what a change claims to do, and who approved the claim. A person reads it, never the diff.
// @invariant: a claimed fix failed in the sealed round and passes now. Every regression is announced.
// @invariant: only a person who approves the hash of the intent excuses a regression.
package rules

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"list"
	"regexp"
	"strings"
)

// @what: how an initiative approves intents. Part of the generator.
#IntentPolicy: {
	// @what: when true, a routine intent is approved without a person.
	// @why: turning the auto-mode on is a loosening, so a person sets it in the initiative.
	auto: bool | *false
	// @what: what the agent is told, after the instructions of the initiative.
	ask: string | *"""
		When you are done, end your last message with your intent, in this exact form:

		```intent
		{"goal": "<one sentence>", "fixes": ["<path of a case you make pass>", ...], "regressions": {"<path of a case that passed and now fails>": "<why this is right>"}}
		```

		"fixes" lists only cases that fail now and pass after your change. "regressions" is {} unless
		you break a case on purpose: a person must then approve the intent before the round is sealed.
		A round that does not hold its intent is refused.
		"""
}

// @what: what the kernel extracts from the last message of the agent.
// @invariant: never bottom. A missing or broken intent is a status, not a failure of the round.
#Intent: {
	// @what: false when no generation preceded this round, so there is nothing to declare.
	declared:    bool | *false
	goal:        string | *""
	fixes:       [...string] | *[]
	regressions: {[string]: string} | *{}
}

#IntentStatus: "none" | "malformed" | "outside" | "awaiting" | "held"

#IntentReview: {
	policy:   #IntentPolicy
	intent:   #Intent
	approval: string // the hash a person approved, or ""
	verdicts: [string]: #Verdict
	sealed: [string]:   #Verdict
	regressed: [...string]

	// @what: what a person approves. The claim, nothing else.
	hash: strings.SliceRunes(hex.Encode(sha256.Sum256(json.Marshal({
		goal:        intent.goal
		fixes:       intent.fixes
		regressions: intent.regressions
	}))), 0, 12)

	_passedBefore: [for k, v in sealed if list.Contains(passing, v) {
		k...
	}]
	_passesNow: [for k, v in verdicts if list.Contains(passing, v) {
		k...
	}]
	// @what: claimed and not true. A fix that did not fail before or does not pass now.
	notFixed: [for p in intent.fixes if list.Contains(_passedBefore, p) || !list.Contains(_passesNow, p) {
		p...
	}]
	unannounced: [for k in regressed if intent.regressions[k] == _|_ {
		k...
	}]
	routine: len(intent.regressions) == 0

	approvedBy: [
		if approval == hash {"human"},
		if policy.auto && routine {"auto"},
		"none",
	][0]

	status: #IntentStatus & [
		if !intent.declared {"none"},
		if strings.TrimSpace(intent.goal) == "" || len(intent.fixes) == 0 {"malformed"},
		if len([for _, r in intent.regressions if strings.TrimSpace(r) == "" {
			r...
		}]) > 0 {"malformed"},
		if len(notFixed) > 0 || len(unannounced) > 0 {"outside"},
		if approvedBy == "none" {"awaiting"},
		"held",
	][0]

	// @what: the regressions a person accepted. Empty unless a person approved this hash.
	excused: [if approvedBy == "human" for k, _ in intent.regressions {
		k...
	}]
}

// @what: the decision. A declared intent must be held, and with no intent there is no claim.
#HoldsIntent: {
	review: #IntentReview
	held:   review.status & ("none" | "held")
}

// @what: the intent in the last message of an agent, as the kernel must extract it. Strings only.
// @invariant: no block, or a broken one, gives an empty claim. The backing checks that both extractions agree.
// @ref: @/tool/cue/rules/seal.rules.cue
#IntentOf: {
	result: string
	let re = "(?s)```intent\\s*\\n(.*?)```"
	_blocks: [if regexp.Match(re, result) for m in regexp.FindAllSubmatch(re, result, -1) {
		m[1]...
	}]
	_x: [if len(_blocks) > 0 if json.Valid(_blocks[len(_blocks)-1]) {json.Unmarshal(_blocks[len(_blocks)-1])}, {}][0]
	_o: [if (_x & {...}) != _|_ {
		_x...
	}, {}][0]
	_fixes: list.SortStrings([if _o.fixes != _|_ if (_o.fixes & [...]) != _|_ for f in _o.fixes if (f & string) != _|_ {
		f...
	}])
	out: {
		declared: true
		goal: [if _o.goal != _|_ if (_o.goal & string) != _|_ {
			_o.goal...
		}, ""][0]
		fixes: [for i, f in _fixes if !list.Contains(list.Take(_fixes, i), f) {
			f...
		}]
		regressions: {
			if _o.regressions != _|_ if (_o.regressions & {...}) != _|_
			for k, v in _o.regressions if (v & string) != _|_ {
				(k): v...
			}
		}
	}
}
