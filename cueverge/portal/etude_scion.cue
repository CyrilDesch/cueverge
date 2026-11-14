package portal

// @what: the Scion study page, sealed facts of theirs and ours.
// @invariant: a sentence here is the sentence of a sealed fact. Only titles and column names are written here.
// @ref: @/cueverge/sealed/anthropic/scion/scion.cue
// @ref: @/cueverge/sealed/anthropic/revue-claude-code/revue.cue
// @ref: @/cueverge/sealed/etudes/scion/etude.cue

import (
	"list"
	"strings"

	"factory.local/kb/sealed/anthropic/scion"
	revue "factory.local/kb/sealed/anthropic/revue-claude-code:revue"
	etude "factory.local/kb/sealed/etudes/scion:etude"
	rscion "factory.local/kb/cogen/gen-sealed/anthropic/scion"
	rrevue "factory.local/kb/cogen/gen-sealed/anthropic/revue-claude-code:revue"
	pscion "factory.local/kb/gen/web/anthropic-scion:web"
	prevue "factory.local/kb/gen/web/claude-code-review:web"
	"factory.local/kb/sealed/usine/principles"
	"factory.local/kb/sealed/usine/actions"
)

_proof: {mentions: "mots", quote: "citation", number: "nombre", absent: "absence"}

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
			[if f.value != _|_ if f.unit != _|_ {"\(f.value) \(f.unit)"}, if f.value != _|_ {"\(f.value)"}, if !f.holds {"faux"}, "—"][0],
			[if R.at != _|_ {"[\(_proof[R.kind]), bloc \(R.at)](\(#url))"}, "\(_proof[R.kind]) sur toute la page"][0],
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
	for k, f in revue.facts {
		"revue.\(k)": f.says...
	}
	for k, c in _constraint {"system.\(k)": "**\(c.fact.title)** : \(c.status)" + [if c.shown != _|_ {" (\(c.shown))"}, ""][0]}
	for k, p in principles.principles {"principles.\(k)": "**\(p.title)** : \(p.status)"}
	for k, a in actions.actions {"actions.\(k)": "**\(a.title)** : \(a.status)"}
}

_theirs: {for k, f in etude.facts {
	(k): strings.Join([for r in f.rests if strings.HasPrefix(r, "scion.") || strings.HasPrefix(r, "revue.") {
		_anchor[r]...
	}], "<br>")
}}
_ours: {for k, f in etude.facts {
	(k): strings.Join([for r in f.rests if !strings.HasPrefix(r, "scion.") && !strings.HasPrefix(r, "revue.") {
		_anchor[r]...
	}], "<br>")
}}

#StudyRows: {
	#role: string
	out: [for k, f in etude.facts if f.role == #role {[f.says, _theirs[k], [if _ours[k] != "" {
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
	out:    "[\(#title)](\(#page.source.url)), capturé le \(strings.SplitN(#page.source.fetched, "T", 2)[0]), empreinte `\(strings.SliceRunes(#page.source.sha256, 0, 12))`"
}

etudeScion: {
	slug:        "etude-scion"
	title:       "Scion et Antique d'Anthropic : les mêmes contraintes que nous"
	description: "Un agrégat de faits : ce que disent deux articles d'Anthropic, chaque fait lié à un bloc du texte capturé, et ce que nous en concluons, ancré sur notre usine."
	footer:      "Sources : " + (_source & {#page: pscion, #title: "Redesigning source control at Anthropic"}).out + " ; " + (_source & {#page: prevue, #title: "How the Claude Code team does code review"}).out + "."
	blocks: [
		{hint: {style: "info", md: "\(len(scion.facts)) faits de l'article sur Scion, \(len(revue.facts)) de l'article sur la revue, \(len(etude.facts)) conclusions. `cue vet` relie chaque fait à son bloc capturé, et chaque conclusion aux faits qui la portent. \(len(scion.retired)) affirmations de l'ancienne étude sont retirées."}},

		{
			group: {title: "1. Ce que dit Anthropic sur Scion", blocks: [{
				table: {
					columns: ["Fait", "Valeur", "Preuve"]
					rows:    (#ArticleRows & {#facts: scion.facts, #rules: rscion.rules, #url: pscion.source.url}).out
				}
			}]}
		},

		{
			group: {title: "2. Ce que dit l'équipe Claude Code sur la revue", blocks: [{
				table: {
					columns: ["Fait", "Valeur", "Preuve"]
					rows:    (#ArticleRows & {#facts: revue.facts, #rules: rrevue.rules, #url: prevue.source.url}).out
				}
			}]}
		},

		{
			group: {title: "3. Les mêmes contraintes chez nous", blocks: [{
				table: {
					columns: ["Parallèle", "Chez Anthropic", "Chez nous, mesuré"]
					rows:    (#StudyRows & {#role: "parallèle"}).out
				}
			}]}
		},

		{
			group: {title: "4. Ce que nous retenons", blocks: [{
				table: {
					columns: ["Leçon", "Chez Anthropic", "Chez nous"]
					rows:    (#StudyRows & {#role: "leçon"}).out
				}
			}]}
		},

		{
			group: {title: "5. Ce que nous proposons", blocks: [{
				table: {
					columns: ["Proposition", "Chez Anthropic", "Chez nous"]
					rows:    (#StudyRows & {#role: "proposition"}).out
				}
			}]}
		},

		{
			group: {title: "6. Ce que nous ne prenons pas", blocks: [{
				table: {
					columns: ["Refus", "Chez Anthropic", "Chez nous"]
					rows:    (#StudyRows & {#role: "refus"}).out
				}
			}]}
		},

		{
			group: {title: "7. Retiré", blocks: [{
				table: {
					columns: ["Affirmation retirée", "Pourquoi"]
					rows:    list.Concat([(#Retired & {#retired: scion.retired}).out, (#Retired & {#retired: revue.retired}).out])
				}
			}]}
		},
	]
}
