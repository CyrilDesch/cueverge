// @what: what is not known yet. An open question is unknown. A resolved one rests on the experiment that answered it.
// @invariant: an open question names an experiment or an action that will answer it, not done yet. Its rule checks it.
// @ref: @/cueverge/cogen/gen-sealed/usine/questions/questions.cue
package questions

import (
	"github.com/cyrildesch/cueverge/schema"
	"factory.local/kb/sealed/usine/experiments"
)

#ExperimentRef: or([for k, _ in experiments.experiments {"cue://experiments/experiments.\(k)"}])

#Question: {
	schema.#Fact...
	_humanize:    question
	question:     string
	says:         question
	whyItMatters: string
	answeredBy?:  [...#ExperimentRef]
	weight:       "décide de tout" | "important" | "secondaire"
	status:       "ouverte" | "résolue"

	// @invariant: open is unknown. Resolved holds, and names the experiments that answered it.
	if status == "ouverte" {holds: "inconnu"}
	if status == "résolue" {
		holds:       true
		answeredBy!: [_, ...]
	}
}

questions: [string]: #Question

// @what: every sealed fact of the package.
facts: {for k, q in questions {
	(k): q...
}}
retired: [string]: schema.#Retired
retired: {
	sans_compilation: {was: "Que veut dire exactement sans compilation pour l'interpréteur ?", why: "Propre à cue-interpreter, abandonné le 2026-11-14."}
}

questions: {
	convergence_d_un_agent: {
		question:     "Un agent seul converge-t-il sur la boucle, de façon reproductible ?"
		whyItMatters: "C'est l'hypothèse centrale de l'usine. Elle demande aussi la reproductibilité, l'orchestration par une table, et le cas sans oracle."
		answeredBy:   ["cue://experiments/experiments.agent_autonome"]
		weight:       "décide de tout"
		status:       "ouverte"
	}
	sans_oracle: {
		question:     "Que valent les oracles partiels quand il n'y a pas de référence ?"
		whyItMatters: "Un oracle complet est rare. Si les lois et la version précédente n'attrapent qu'une faible part des bugs, l'usine ne tient pas sans relecture."
		answeredBy:   ["cue://experiments/experiments.loi_d_ordre"]
		weight:       "décide de tout"
		status:       "ouverte"
	}
	apport_de_cue: {
		question:     "Où CUE apporte-t-il plus qu'un format de configuration ?"
		whyItMatters: "C'est l'ambition de départ : la cogénération. La génération est stochastique, l'extraction et la rencontre des contraintes sont déterministes. Le juge est conçu comme une rencontre de contraintes, où une régression est un conflit d'unification. La base vérifie aussi ses propres faits : un fait est déclaré, généré, ou refusé. Restent la porte contre le relâchement d'une règle, et les contraintes qui affirment une absence."
		answeredBy:   ["cue://experiments/experiments.juge_en_cue", "cue://experiments/experiments.points_fixes"]
		weight:       "décide de tout"
		status:       "ouverte"
	}

	autorite_de_scellement: {
		question:     "Qui scelle une version ?"
		whyItMatters: "Braid consomme la décision, il ne la prend pas. Le juge seul, ou le juge plus un humain pour ce qui relâche une règle ?"
		answeredBy:   ["cue://experiments/experiments.braid_comme_etat"]
		weight:       "important"
		status:       "ouverte"
	}
	grain_de_l_intention: {
		question:     "À quel grain l'humain approuve-t-il une intention ?"
		whyItMatters: "Par tour, l'humain devient le goulot : Scion, le gestionnaire de sources d'Anthropic, passe plus de 30 000 fusions par jour, et ses ingénieurs relisent l'intention, pas chaque ligne. Par initiative, une intention large couvre des tours que l'humain n'a pas vus. Piste : par initiative en mode automatique, par tour dès qu'une régression est annoncée ou qu'une règle est touchée."
		weight:       "important"
		status:       "ouverte"
	}
	identite_d_une_tache: {
		question:     "Comment donner à une tâche une identité stable, calculée depuis l'état ?"
		whyItMatters: "Trop fine, deux agents corrigent le même bug sous deux noms. Une étude antérieure montre qu'un regroupement déterministe par cause profonde ne tient pas."
		weight:       "important"
		status:       "ouverte"
	}
	abstraction_du_noyau: {
		question:     "Le noyau sert-il une initiative d'une autre nature, comme des mathématiques ?"
		whyItMatters: "Seul le juge différentiel JSON existe."
		answeredBy:   ["cue://experiments/experiments.noyau_foncteur"]
		weight:       "important"
		status:       "ouverte"
	}
	gout_mesurable: {
		question:     "Le coût d'évolution distingue-t-il vraiment deux solutions correctes ?"
		whyItMatters: "Si l'écart est nul, le critère de goût automatique ne sert à rien."
		answeredBy:   ["cue://experiments/experiments.deux_variantes"]
		weight:       "important"
		status:       "ouverte"
	}
	stabilite_des_verdicts: {
		question:     "Les verdicts d'un projet sont-ils stables d'une exécution à l'autre ?"
		whyItMatters: "Un verdict instable rend impossible la définition de terminé comme point fixe."
		answeredBy:   ["cue://experiments/experiments.stabilite"]
		weight:       "important"
		status:       "ouverte"
	}
	contraintes_non_mesurables: {
		question:     "Que fait-on des contraintes qu'on ne sait pas mesurer ?"
		whyItMatters: "Un message d'erreur qui permet de corriger seul, une alerte comprise à trois heures du matin : un jugement, pas une mesure."
		weight:       "secondaire"
		status:       "ouverte"
	}
	passage_par_accident: {
		question:     "Un cas qui passe par accident doit-il bloquer un correctif juste ?"
		whyItMatters: "Un correctif juste peut casser un cas qui passait pour une mauvaise raison. La règle aucune régression protège alors une erreur. Il faut une voie d'amendement, tranchée par une personne : une régression annoncée dans une intention approuvée."
		answeredBy:   ["cue://experiments/experiments.intention_sur_un_projet"]
		weight:       "important"
		status:       "ouverte"
	}
	budget_contournable: {
		question:     "Qu'est-ce que le budget doit borner : les tours, ou l'évaluation totale ?"
		whyItMatters: "Les tours filtrés ne comptent pas et peuvent couvrir presque tout le corpus. Un agent pourrait s'en servir sans le dire."
		weight:       "secondaire"
		status:       "ouverte"
	}
	seuil_de_temps: {
		question:     "Que fait le juge d'un cas dont le temps est égal au budget ?"
		whyItMatters: "Un cas dont le temps réel est égal au budget bascule d'une exécution à l'autre. Une seule bascule se lit comme une régression et fait refuser le tour. Choix possibles : une marge de tolérance, ou garder le verdict précédent dans une bande autour du seuil."
		weight:       "important"
		status:       "ouverte"
	}
	acces_a_l_oracle: {
		question:     "L'agent a-t-il le droit d'interroger l'oracle à la main ?"
		whyItMatters: "Une règle peut interdire au candidat d'appeler la référence sans interdire à l'agent de s'en servir pour apprendre. Sans oracle, cette aide disparaît, et le résultat en dépend peut-être."
		weight:       "important"
		status:       "ouverte"
	}
}
