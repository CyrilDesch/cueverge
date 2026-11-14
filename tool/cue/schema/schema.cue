// @what: the shape of a sealed fact. A fact is short and structured. Its proof is a rule in the gen-sealed cogen module.
// @invariant: a sealed package holds facts and tombstones only. No prose beyond the one sentence that a fact says.
// @ref: @/tool/cue/kinds/kinds.cue
package schema

import "strings"

#Fact: {
	// @what: the fact in one French sentence. The portal shows it. It is the claim, never the proof.
	says: string & strings.MinRunes(8) & strings.MaxRunes(200)
	// @what: false when the sentence is false, inconnu when no measure exists yet. A rule proves each of the three.
	// @why: no default. A default lets a rule pick the polarity in place of the fact.
	holds: bool | "inconnu"
	// @what: the number the fact states, when it states one. A number needs a number rule or a computed rule.
	value?: number
	unit?:  string
	// @what: who states the fact, for a fact about another system. Our knowledge of it is attributed, never adopted.
	selon?: string
	// @what: the key of a retired fact that this fact replaces.
	supersedes?: string
	// @what: for a conclusion of ours, the facts it rests on, as package.key. A derived rule resolves each one.
	rests?: [string, ...string]
	// @what: the part of a study a conclusion belongs to.
	role?: "parallèle" | "leçon" | "refus" | "proposition"
}

// @what: a tombstone. The key stays reserved, so a retired fact cannot come back unnoticed.
#Retired: {
	was: string & strings.MinRunes(8)
	why: string & strings.MinRunes(8)
	// @what: the hash of the captured page that the fact failed against, when there is one.
	against?: string
}

#Sealed: {
	facts: [string]:   #Fact
	retired: [string]: #Retired
}
