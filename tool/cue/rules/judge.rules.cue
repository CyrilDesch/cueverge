// @what: from two observed answers to one verdict.
package rules

import (
	"list"
	"regexp"
	"strings"
)

// @what: the candidate is compared with the oracle, value against value, rejection against rejection.
#DifferentialJSON: {
	kind: "differential-json"
	// @what: extracts from one line of a rejection where the rejection is.
	locationKey: string
}

// @what: the places named by a rejection. Indented lines are detail, not places.
#Places: {
	key: string
	in:  string
	out: [for l in strings.Split(in, "\n")
	if l != "" && !strings.HasPrefix(l, " ") && !strings.HasPrefix(l, "\t") && l =~ key {
		regexp.FindSubmatch(key, l)[1]...
	}]
}

#Judge: {
	o:        #Answer
	c:        #Answer
	judge:    #DifferentialJSON
	budgetMs: int

	_want: (#Places & {key: judge.locationKey, in: o.err}).out
	_got:  (#Places & {key: judge.locationKey, in: c.err}).out
	_elsewhere: [for p in _got if !list.Contains(_want, p) {
		p...
	}]

	// @invariant: the first rule that applies gives the verdict. Every condition is total, because CUE evaluates them all.
	correct: [
		if c.timeout {"timeout"},
		if c.exit == 3 {"unsupported"},
		if c.exit != 0 && c.exit != 1 {"crash"},
		if o.exit != 0 && c.exit != 0 && (len(_want) == 0 || len(_got) == 0) {"error-unlocated"},
		if o.exit != 0 && c.exit != 0 && len(_elsewhere) > 0 {"error-elsewhere"},
		if o.exit != 0 && c.exit != 0 {"error-same"},
		if o.exit == 0 && c.exit != 0 {"false-reject"},
		if o.exit != 0 && c.exit == 0 {"false-accept"},
		// @what: both gave a value. An output that is not JSON is a crash.
		if o.value == "" || c.value == "" {"crash"},
		if o.text == c.text {"perfect"},
		if o.value == c.value {"acceptable"},
		"wrong",
	][0]

	// @why: time is noisy, so the fastest timing counts.
	fastest: [if len(c.ms) > 0 {list.Min(c.ms)}, 0][0]
	verdict: #Verdict & [
		if list.Contains(passing, correct) && budgetMs > 0 && fastest > budgetMs {"late"},
		correct,
	][0]
}
