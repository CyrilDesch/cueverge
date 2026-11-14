package portal

// @what: the Scion study page, sealed facts of theirs and ours.
// @invariant: a sentence here is the sentence of a sealed fact. Only titles and column names are written here.
// @ref: @/cueverge/sealed/anthropic/scion/scion.cue
// @ref: @/cueverge/sealed/anthropic/claude-code-review/review.cue
// @ref: @/cueverge/sealed/studies/scion/study.cue

import (
	"list"
	"strings"

	"factory.local/kb/sealed/anthropic/scion"
	review "factory.local/kb/sealed/anthropic/claude-code-review:review"
	study "factory.local/kb/sealed/studies/scion:study"
	rscion "factory.local/kb/cogen/gen-sealed/anthropic/scion"
	rreview "factory.local/kb/cogen/gen-sealed/anthropic/claude-code-review:review"
	pscion "factory.local/kb/gen/web/anthropic-scion:web"
	preview "factory.local/kb/gen/web/claude-code-review:web"
	"factory.local/kb/sealed/factory/principles"
	"factory.local/kb/sealed/factory/actions"
)

_proof: {mentions: "words", quote: "quote", number: "number", absent: "absence"}

// @what: one row per fact of an article, in the order of the article. The proof names its rule and links its block.
#ArticleRows: {
	#facts: _
	#rules: _
	#url:   string
	_rows: list.Sort([for k, f in #facts {
		let R = #rules.by[k]
		at: [if R.at != _|_ {
			R.at...
		}, 100000][0]
		row: [
			f.says,
			[if f.value != _|_ if f.unit != _|_ {"\(f.value) \(f.unit)"}, if f.value != _|_ {"\(f.value)"}, if !f.holds {"false"}, "—"][0],
			[if R.at != _|_ {"[\(_proof[R.kind]), block \(R.at)](\(#url))"}, "\(_proof[R.kind]) on the whole page"][0],
		]
	}], {x: _, y: _, less: x.at < y.at})
	out: [for r in _rows {
		r.row...
	}]
}

// @what: the sentence of a fact that a conclusion rests on, and for a constraint of ours, its measured status.
_anchor: {
	for k, f in scion.facts {
		"scion.\(k)": f.says...
	}
	for k, f in review.facts {
		"review.\(k)": f.says...
	}
	for k, c in _constraint {"system.\(k)": "**\(c.fact.title)**: \(c.status)" + [if c.shown != _|_ {" (\(c.shown))"}, ""][0]}
	for k, p in principles.principles {"principles.\(k)": "**\(p.title)**: \(p.status)"}
	for k, a in actions.actions {"actions.\(k)": "**\(a.title)**: \(a.status)"}
}

_theirs: {for k, f in study.facts {
	(k): strings.Join([for r in f.rests if strings.HasPrefix(r, "scion.") || strings.HasPrefix(r, "review.") {
		_anchor[r]...
	}], "<br>")
}}
_ours: {for k, f in study.facts {
	(k): strings.Join([for r in f.rests if !strings.HasPrefix(r, "scion.") && !strings.HasPrefix(r, "review.") {
		_anchor[r]...
	}], "<br>")
}}

#StudyRows: {
	#role: string
	out: [for k, f in study.facts if f.role == #role {[f.says, _theirs[k], [if _ours[k] != "" {
		_ours[k]...
	}, "—"][0]]}]
}

#Retired: {
	#retired: _
	out:      [for _, r in #retired {[r.was, r.why]}]
}

_source: {
	#page:  _
	#title: string
	out:    "[\(#title)](\(#page.source.url)), captured on \(strings.SplitN(#page.source.fetched, "T", 2)[0]), hash `\(strings.SliceRunes(#page.source.sha256, 0, 12))`"
}

scionStudy: {
	slug:        "scion-study"
	title:       "Scion and Antique at Anthropic: the same constraints as ours"
	description: "An aggregate of facts: what two Anthropic articles say, each fact linked to a block of the captured text, and what we conclude from them, anchored on our factory."
	footer:      "Sources: " + (_source & {#page: pscion, #title: "Redesigning source control at Anthropic"}).out + "; " + (_source & {#page: preview, #title: "How the Claude Code team does code review"}).out + "."
	blocks: [
		{hint: {style: "info", md: "\(len(scion.facts)) facts from the article on Scion, \(len(review.facts)) from the article on review, \(len(study.facts)) conclusions. `cue vet` links each fact to its captured block, and each conclusion to the facts that carry it. \(len(scion.retired)) claims of the old study are retired."}},

		{
			group: {title: "1. What Anthropic says about Scion", blocks: [{
				table: {
					columns: ["Fact", "Value", "Proof"]
					rows:    (#ArticleRows & {#facts: scion.facts, #rules: rscion.rules, #url: pscion.source.url}).out
				}
			}]}
		},

		{
			group: {title: "2. What the Claude Code team says about review", blocks: [{
				table: {
					columns: ["Fact", "Value", "Proof"]
					rows:    (#ArticleRows & {#facts: review.facts, #rules: rreview.rules, #url: preview.source.url}).out
				}
			}]}
		},

		{
			group: {title: "3. The same constraints in our factory", blocks: [{
				table: {
					columns: ["Parallel", "At Anthropic", "In our factory, measured"]
					rows:    (#StudyRows & {#role: "parallel"}).out
				}
			}]}
		},

		{
			group: {title: "4. What we keep", blocks: [{
				table: {
					columns: ["Lesson", "At Anthropic", "In our factory"]
					rows:    (#StudyRows & {#role: "lesson"}).out
				}
			}]}
		},

		{
			group: {title: "5. What we propose", blocks: [{
				table: {
					columns: ["Proposal", "At Anthropic", "In our factory"]
					rows:    (#StudyRows & {#role: "proposal"}).out
				}
			}]}
		},

		{
			group: {title: "6. What we do not take", blocks: [{
				table: {
					columns: ["Refusal", "At Anthropic", "In our factory"]
					rows:    (#StudyRows & {#role: "refusal"}).out
				}
			}]}
		},

		{
			group: {title: "7. Retired", blocks: [{
				table: {
					columns: ["Retired claim", "Why"]
					rows:    list.Concat([(#Retired & {#retired: scion.retired}).out, (#Retired & {#retired: review.retired}).out])
				}
			}]}
		},
	]
}
