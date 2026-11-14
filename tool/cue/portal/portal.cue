// @what: generic parts of a project portal. A project portal is a Polaris site (polaris.yaml names it).
// @ref: @/cueverge/polaris.yaml
// @why: the package does not import the Polaris site package, which needs CUE v0.18. polaris site build checks the shape.
// @ref: @/cueverge/polaris.yaml
package portal

import (
	"strings"

	"github.com/cyrildesch/cueverge/frame"
)

// @what: the slug of a key. A page path accepts [a-z0-9-] only, so "_" becomes "-".
// @why: a key with an accent fails cue vet here, instead of giving a broken URL.
#Slug: {
	#key: string
	out:  strings.Replace(#key, "_", "-", -1) & =~"^[a-z0-9][a-z0-9-]*$"
}

// @what: the frame page of a project. The problem, then the objectives, the constraints and the intents as cards.
#FramePage: {
	#frame: frame.#Frame
	#intents: [string]: frame.#Intent
	out: {
		slug:        "frame"
		title:       "Frame"
		description: #frame.problem
		footer:      "Generated from frame/ and intents/ at build time."
		// @why: an empty group is left out, since the site refuses it. Before the approval of init, the frame holds only the problem.
		blocks: [
			{
				stats: [
					{label: "objectives", value: len(#frame.objectives), tone: "info"},
					{label: "constraints", value: len(#frame.constraints), tone: "info"},
					{label: "intents", value: len(#intents), tone: "info"},
				]
			},
			if len(#frame.objectives) > 0 {group: {title: "Objectives", blocks: [{cards: [for k, o in #frame.objectives {title: k, tone: "info", md: "\(o.says)\n\n*\(o.why)*"}]}]}},
			if len(#frame.constraints) > 0 {
				group: {title: "Constraints", blocks: [{
					cards: [for k, c in #frame.constraints {
						title: k
						tone:  "medium"
						md:    "\(c.says)\n\nMeasure: \(c.measure)\n\nServes: \(strings.Join(c.serves, ", "))"
					}]
				}]}
			},
			if len(#intents) > 0 {group: {title: "Intents", blocks: [{cards: [for k, i in #intents {title: k, tone: "accepted", md: "\(i.says)\n\nServes: \(i.serves)"}]}]}},
		]
	}
}
