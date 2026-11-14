// @what: the intent rules on small rounds. Case a passes, b fails, c passes.
// @invariant: each field unifies what the rules compute with what they must compute.
package test

import "github.com/cyrildesch/cueverge/rules"

_sealed:  {a: "perfect", b: "wrong", c: "perfect"}
_fixB:    {declared: true, goal: "fix b", fixes: ["b"]}
_breakC:  _fixB & {regressions: c: "c passed by accident"}
_all:     {a: "perfect", b: "perfect", c: "perfect"}
_cBroken: {a: "perfect", b: "perfect", c: "wrong"}

#Case: rules.#IntentReview & {sealed: _sealed, approval: string | *"", policy: auto: bool | *false}

// @what: b is fixed, nothing breaks, no person approved. The round waits.
waits: (#Case & {intent: _fixB, verdicts: _all, regressed: []}).status & "awaiting"
// @what: the same round in auto-mode. Routine, approved without a person.
autoRoutine: (#Case & {policy: auto: true, intent: _fixB, verdicts: _all, regressed: []}).status & "held"
// @what: the intent claims b and b still fails. Outside the intent, even in auto-mode.
claimNotTrue: (#Case & {policy: auto: true, intent: _fixB, verdicts: {a: "perfect", b: "wrong", c: "perfect"}, regressed: []}).status & "outside"
// @what: a fix of a case that already passed is not a fix.
claimVacuous: (#Case & {policy: auto: true, intent: {declared: true, goal: "fix a", fixes: ["a"]}, verdicts: _all, regressed: []}).status & "outside"
// @what: c breaks and the intent does not say so.
unannounced: (#Case & {policy: auto: true, intent: _fixB, verdicts: _cBroken, regressed: ["c"]}).status & "outside"
// @what: c breaks and the intent announces it. The auto-mode never approves a regression.
announcedAuto: (#Case & {policy: auto: true, intent: _breakC, verdicts: _cBroken, regressed: ["c"]}).status & "awaiting"
// @what: a person approves the hash of that intent. It holds, and c is excused from the seal.
_approved: #Case & {intent: _breakC, verdicts: _cBroken, regressed: ["c"]}
_approved: approval: _approved.hash
approved: _approved.status & "held"
excused:  _approved.excused & ["c"]
seal:     (rules.#NoRegression & {verdicts: _cBroken, sealed: _sealed, excused: _approved.excused}).kept & {a: "perfect"}
// @what: an approval of another claim opens nothing.
_stale:        #Case & {approval: "000000000000", intent: _breakC, verdicts: _cBroken, regressed: ["c"]}
staleApproval: _stale.status & "awaiting"
staleExcused:  _stale.excused & []
// @what: the agent said nothing usable.
malformed: (#Case & {intent: declared: true, verdicts: _all, regressed: []}).status & "malformed"
// @what: no generation and no claim. The seal alone decides.
none: (#Case & {verdicts: _all, regressed: []}).status & "none"

// @what: the extractor keeps the last intent block, strings only, with fixes sorted and unique.
extracted: (rules.#IntentOf & {result: """
	Done.
	```intent
	{"goal": "old", "fixes": []}
	```
	Then:
	```intent
	{"goal": "fix b", "fixes": ["c", "b", "c", 3], "regressions": {"d": "by accident", "e": 1}}
	```
	"""}).out & {declared: true, goal: "fix b", fixes: ["b", "c"], regressions: {d: "by accident"}}
noBlock:    (rules.#IntentOf & {result: "I changed two lines."}).out & {declared: true, goal: "", fixes: [], regressions: {}}
brokenJSON: (rules.#IntentOf & {result: "```intent\n{goal: oops\n```"}).out & {declared: true, goal: "", fixes: [], regressions: {}}
