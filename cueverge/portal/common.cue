package portal

import (
	"strings"

	"factory.local/kb/sealed/usine/actions"
	"factory.local/kb/sealed/usine/decisions"
	"factory.local/kb/sealed/usine/experiments"
	"factory.local/kb/sealed/usine/principles"
	"factory.local/kb/sealed/usine/questions"
)

// @what: the color of each value of an enumerated field, for a badge or the left edge of a card.
_tone: {
	"fait":                "accepted"
	"prévu":               "info"
	"interrompu":          "high"
	"écarté":              "muted"
	"testé sur un projet": "accepted"
	"posé, non testé":     "info"
	"acté":                "accepted"
	"à confirmer":         "info"
	"reporté":             "muted"
	"décide de tout":      "high"
	"important":           "info"
	"secondaire":          "muted"
	"à faire":             "info"
	"en cours":            "medium"
	"faible":              "low"
	"moyen":               "medium"
	"élevé":               "high"
	"branché":             "accepted"
	"possible":            "info"
	"sans équivalent":     "muted"
}

// @what: A badge for an enumerated value, colored by _tone.
#Badge: {
	#v:  string
	out: {badge: #v, tone: _tone[#v]}
}

// @what: the slug of a key of the base. A page path accepts [a-z0-9-] only, so "_" becomes "-".
// @why: the pattern of site.#DocPage.slug, so a key with an accent fails `cue vet` here instead of giving a broken URL.
#Slug: {
	#key: string
	out:  strings.Replace(#key, "_", "-", -1) & =~"^[a-z0-9][a-z0-9-]*$"
}

// @what: The site path of each entry page, keyed by KB key.
_href: {
	action: {for k, _ in actions.actions {
		(k): "/actions/\((#Slug & {#key: k...
		}).out)/"
	}}
	question: {for k, _ in questions.questions {
		(k): "/questions/\((#Slug & {#key: k...
		}).out)/"
	}}
	experiment: {for k, _ in experiments.experiments {
		(k): "/experiences/\((#Slug & {#key: k...
		}).out)/"
	}}
	principle: {for k, _ in principles.principles {
		(k): "/principes/\((#Slug & {#key: k...
		}).out)/"
	}}
	decision: {for k, _ in decisions.decisions {
		(k): "/decisions/\((#Slug & {#key: k...
		}).out)/"
	}}
}

// @what: The KB key that a cue:// reference of the KB names.
_prefix: {
	action:     "cue://actions/actions."
	question:   "cue://questions/questions."
	experiment: "cue://experiments/experiments."
	principle:  "cue://principles/principles."
}

// @what: A Markdown list of links to the entries that a list of cue:// references names.
#Links: {
	#kind: "action" | "question" | "experiment" | "principle"
	#refs: [...string]
	#title: [string]: string
	out: strings.Join([for r in #refs {
		let K = strings.TrimPrefix(r, _prefix[#kind])
		"- [\(#title[K])](\(_href[#kind][K]))"
	}], "\n")
}

// @what: The title of each entry, keyed by KB key.
_title: {
	action: {for k, a in actions.actions {
		(k): a.title...
	}}
	question: {for k, q in questions.questions {
		(k): q.question...
	}}
	experiment: {for k, e in experiments.experiments {
		(k): e.title...
	}}
	principle: {for k, p in principles.principles {
		(k): p.title...
	}}
	decision: {for k, d in decisions.decisions {
		(k): d.title...
	}}
}

// @what: A Markdown bullet list.
#Bullets: {
	#items: [...string]
	out:    strings.Join([for i in #items {"- \(i)"}], "\n")
}

// @what: the status of a constraint of the factory, computed and never declared.
_tone: {
	"tenue":       "accepted"
	"non tenue":   "high"
	"pas mesurée": "muted"
}
