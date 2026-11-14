// @what: the frame of a project. The problem a person states, the objectives and constraints that follow, and the intents.
// @what: cueverge init drafts it with Claude. A person approves it, so the first frame is theirs.
// @invariant: the frame holds statements only. A rule proves a constraint, never the frame.
package frame

import "strings"

// @what: a key of the frame. The portal turns it into a page path.
#Key: =~"^[a-z][a-z0-9_]*$"

#Statement: string & strings.MinRunes(8) & strings.MaxRunes(300)

#Frame: {
	// @what: the problem as the person states it, in their words.
	problem: string & strings.MinRunes(20)
	objectives: [#Key]:  #Objective
	constraints: [#Key]: #Constraint
	// @invariant: a constraint serves objectives that exist.
	served: {for k, c in constraints for o in c.serves {"\(k)/\(o)": (objectives[o] != _|_) & true}}
}

// @what: what the project must achieve.
#Objective: {
	says: #Statement
	// @what: why it matters, for whom.
	why: #Statement
}

// @what: a property every change must keep. Its measure says how a round can check it.
#Constraint: {
	says:    #Statement
	measure: #Statement
	serves:  [#Key, ...#Key]
}

// @what: what the project means to do next. A rule names the intent it serves, so a rule changes only when its intent does.
#Intents: {
	objectives: [#Key]: _
	intents: [#Key]:    #Intent
	// @invariant: an intent serves an objective that exists.
	served: {for k, i in intents {(k): (objectives[i.serves] != _|_) & true}}
}

#Intent: {
	says:   #Statement
	serves: #Key
}
