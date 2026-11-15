// @what: the kinds of cogen rule between a sealed fact and a generated export. Each kind fails in cue vet when its export disagrees.
// @invariant: a rule only reads exports. It never holds a value of its own that the fact could copy.
// @ref: @/tool/cue/schema/schema.cue
package kinds

import (
	"list"
	"strconv"
	"strings"
	"regexp"
)

#Block: {tag: string, text: string}
#Page: {
	source: {url: string, fetched: string, sha256: string}
	blocks: [...#Block]
}

// @what: the block at that index names every term. Case is ignored. The weakest rule, for a sentence with no number.
#Mentions: {
	page:  #Page
	at:    int & >=0
	in:    page.blocks[at]
	kind:  "mentions"
	fact:  {holds: true, ...}
	terms: [string, ...string]
	found: {for t in terms {(t): strings.Contains(strings.ToLower(in.text), strings.ToLower(t)) & true}}
}

// @what: the block holds this exact text.
#Quote: {
	page:  #Page
	at:    int & >=0
	in:    page.blocks[at]
	kind:  "quote"
	fact:  {holds: true, ...}
	quote: string & strings.MinRunes(12)
	found: strings.Contains(in.text, quote) & true
}

_words: {one: 1, two: 2, three: 3, four: 4, five: 5, six: 6, seven: 7, eight: 8, nine: 9, ten: 10, twelve: 12, fifty: 50}

// @what: a pattern with one group reads a number in the block, and the number equals the value of the fact.
// @why: a number in words is read too, so the article cannot say seven where the fact says 8.
#Number: {
	page:  #Page
	at:    int & >=0
	in:    page.blocks[at]
	kind:  "number"
	fact:  {holds: true, value: number, ...}
	re:    string
	match: regexp.FindSubmatch(re, in.text)
	_raw:  strings.Replace(match[1], ",", "", -1)
	read: [if _words[strings.ToLower(_raw)] != _|_ {
		_words[strings.ToLower(_raw)]...
	}, strconv.ParseFloat(_raw, 64)][0]
	equal: (read == fact.value) & true
}

// @what: no block of the whole page names the term. The closed world is the captured page, never the world.
#Absent: {
	kind: "absent"
	fact: {holds: false, ...}
	page: #Page
	term: string
	hits: [for i, b in page.blocks if strings.Contains(strings.ToLower(b.text), strings.ToLower(term)) {
		i...
	}]
	none: len(hits) & 0
}

// @what: the fact states a value or a polarity, and the rule computes both from exports. They must agree.
// @why: the fact writes its value. When the exports move, the fact fails and is sealed again.
#Computed: {
	kind:   "computed"
	fact:   {...}
	of?:    number
	holds?: bool
	if of != _|_ {equal: (of == fact.value) & true}

	// @why: a let, because inside fact the name holds would mean the field of the fact itself.
	let H = holds
	if holds != _|_ {fact: holds: H}
}

// @what: no measure exists yet. The fact names the action that builds it, and that action is not done.
#Pending: {
	kind:   "pending"
	fact:   {holds: "unknown", ...}
	action: {status: !="done", ...}
}

// @what: a fact of ours rests on facts that hold. An analogy cannot be proven, only anchored.
#Derived: {
	kind: "derived"
	fact: {holds: true, ...}
	from: [{holds: true, ...}, ...{holds: true, ...}]
}

// @what: a discarded item. It does not hold, and nothing cites it as evidence or plans to run it.
#Discarded: {
	kind:    "discarded"
	fact:    {holds: false, ...}
	citedBy: []
}

// @what: a statement of a person. It holds because a person approved this exact text, in a journaled approval.
#Approved: {
	kind:     "approved"
	fact:     {holds: true, says: string, ...}
	approved: [...string]
	found:    list.Contains(approved, fact.says) & true
}

// @what: a measure that no round gives yet. The fact is unknown, and the verdicts of the rounds hold none for it.
#Unmeasured: {
	kind: "unmeasured"
	fact: {holds: "unknown", ...}
	measured: [string]: bool
	key:  string
	none: (measured[key] == _|_) & true
}

// @what: a fact that waits on others. It is unknown while one of the facts it rests on is unknown, and none is false.
#Open: {
	kind:  "open"
	fact:  {holds: "unknown", ...}
	from!: [...{holds: bool | "unknown", ...}]
	open:  (len([for f in from if f.holds == "unknown" {f}]) > 0) & true
	sound: len([for f in from if f.holds == false {f}]) & 0
}

#Rule: #Mentions | #Quote | #Number | #Absent | #Computed | #Derived | #Pending | #Discarded | #Approved | #Unmeasured | #Open

// @what: the rules of one sealed package. Every fact has exactly one rule, a number has a strong rule, a tombstone stays dead.
#Cover: {
	sealed: {facts: [string]: {...}, retired: [string]: {...}, ...}
	by: [string]~(K,_): {fact: sealed.facts[K], ...}
	covered: {for k, _ in sealed.facts {
		(k): by[k].kind...
	}}
	strong: {for k, f in sealed.facts if f.value != _|_ {
		(k): (by[k].kind & ("number" | "computed"))...
	}}
	// @invariant: a computed rule computes a value, a polarity, or both.
	computes: {for k, r in by if r.kind == "computed" {(k): (r.of != _|_ || r.holds != _|_) & true}}
	dead:     {for k, _ in sealed.retired {(k): (sealed.facts[k] == _|_) & true}}
	replaces: {for k, f in sealed.facts if f.supersedes != _|_ {(k): (sealed.retired[f.supersedes] != _|_) & true}}
}
