// @what: the constraints of the factory itself, and the measures that say whether each one holds.
// @invariant: this package computes nothing. It states each value, and the system cogen rules recompute it from a capture of a project.
// @ref: @/cueverge/cogen/gen-sealed/usine/system/system.cue
package system

import (
	"github.com/cyrildesch/cueverge/schema"
	"factory.local/kb/sealed/usine/actions"
)

#ActionRef: or([for k, _ in actions.actions {
	k...
}])

// @what: a constraint we set, or a measure that a constraint shows.
#Entry: {
	schema.#Fact...
	kind: "contrainte" | "mesure"
	if kind == "contrainte" {
		title:   string
		why:     string
		family:  "organisation" | "verdict" | "juge" | "coût"
		measure: string
	}
	title?:   string
	why?:     string
	family?:  string
	measure?: string
	// @what: the measures shown with the constraint.
	with?: [...string]
	// @what: the action that builds what the constraint needs.
	action?: #ActionRef
}

facts: [string]:   #Entry
retired: [string]: schema.#Retired
retired: {}

facts: {
	refus:            {kind: "mesure", says: "Tours complets refusés", holds: "inconnu", action: "monter_le_premier_projet"}
	argent_perdu:     {kind: "mesure", says: "Argent des générations perdu", holds: "inconnu", action: "monter_le_premier_projet"}
	argent_depense:   {kind: "mesure", says: "Argent dépensé en générations", holds: "inconnu", action: "monter_le_premier_projet"}
	duree_generation: {kind: "mesure", says: "Durée médiane d'une génération", holds: "inconnu", action: "monter_le_premier_projet"}

	une_tache_un_agent: {
		kind:    "contrainte"
		title:   "Jamais deux agents sur la même tâche"
		says:    "Une tâche est réservée par l'agent qui la prend. Un autre agent ne peut pas la prendre en même temps."
		holds:   "inconnu"
		why:     "Deux agents sur la même tâche, c'est un des deux qui travaille pour rien."
		family:  "organisation"
		measure: "Les tâches prises deux fois en même temps, dans le journal."
		action:  "table_d_orchestration"
	}

	rejouer_pas_jeter: {
		kind:    "contrainte"
		title:   "Un changement qui perd sa place est rejoué, pas jeté"
		says:    "Si un autre changement est entré avant lui, il est rejoué sur la nouvelle base : un test de plus, pas une nouvelle génération."
		holds:   "inconnu"
		why:     "Le test coûte presque rien, la génération coûte cher."
		family:  "organisation"
		measure: "Les changements perdus par concurrence et jamais rejoués."
		action:  "etat_en_braid"
	}

	deplacer_pas_jeter: {
		kind:    "contrainte"
		title:   "Ce qui était construit sur un essai raté est déplacé, pas jeté"
		says:    "Le travail construit sur un changement qui échoue est rejoué sur ce qui tient."
		holds:   "inconnu"
		why:     "Le travail n'était pas faux : sa base l'était."
		family:  "organisation"
		measure: "Les changements construits sur un essai raté et jamais rejoués."
		action:  "etat_en_braid"
	}

	jamais_le_meme_mur: {
		kind:    "contrainte"
		title:   "Jamais deux fois le même mur"
		says:    "Un essai dont l'effet a déjà été refusé n'est pas relancé. La tâche suivante dit ce qu'il ne faut pas casser."
		holds:   "inconnu"
		with:    ["refus"]
		why:     "Le 12 novembre, trois générations ont cassé le même cas, l'une après l'autre."
		family:  "organisation"
		measure: "Les tours refusés qui cassent exactement les mêmes cas qu'un refus précédent."
		action:  "table_d_orchestration"
	}

	un_seul_decideur: {
		kind:    "contrainte"
		title:   "Un seul décideur à la fois"
		says:    "Une seule table choisit ce qui passe en essai. Elle écrit sa décision, et tout le monde la lit."
		holds:   "inconnu"
		why:     "Deux décisions contradictoires font perdre le travail lancé sur l'une d'elles."
		family:  "organisation"
		measure: "Les décisions d'essai écrites par deux décideurs en même temps."
		action:  "table_d_orchestration"
	}

	coherence_avant_generation: {
		kind:    "contrainte"
		title:   "La cohérence des règles est vérifiée avant de générer"
		says:    "Une demande incompatible avec une autre est détectée avant qu'un agent soit payé pour l'écrire."
		holds:   "inconnu"
		why:     "Vérifier des règles coûte presque rien ; écrire du code qui ne pourra jamais passer coûte une génération."
		family:  "verdict"
		measure: "Les générations lancées sur des règles dont la rencontre est vide."
		action:  "verrouiller_les_points_fixes"
	}

	tester_avant_de_proposer: {
		kind:    "contrainte"
		title:   "L'agent lance le vrai test avant de proposer"
		says:    "Dans sa copie, l'agent lance le même juge que l'essai. Il voit ses régressions avant de proposer."
		holds:   "inconnu"
		why:     "Le 12 novembre, l'agent n'avait droit qu'à un test réduit : 4 refus sur 4, sans les voir venir."
		family:  "verdict"
		measure: "Les changements proposés sans un tour complet du juge dans la copie de l'agent."
		action:  "etat_en_braid"
	}

	evolution_sans_perte: {
		kind:    "contrainte"
		title:   "Faire évoluer la demande ne jette que ce qui la contredit"
		says:    "Quand une personne change l'objectif ou les contraintes, le travail en cours qui reste compatible est gardé."
		holds:   "inconnu"
		why:     "Une personne peut faire évoluer la demande à tout moment."
		family:  "verdict"
		measure: "Le travail écarté après une évolution alors qu'il restait compatible."
		action:  "table_d_orchestration"
	}

	cout_perdu: {
		kind:    "contrainte"
		title:   "Le coût perdu reste sous un plafond"
		says:    "La part de l'argent dépensé en générations qui n'arrive jamais dans l'acquis reste sous 20 %."
		holds:   "inconnu"
		action:  "monter_le_premier_projet"
		with:    ["argent_perdu", "argent_depense"]
		why:     "Une génération coûte cher ; le reste de la boucle presque rien. C'est la mesure qui résume toutes les autres."
		family:  "coût"
		measure: "Le coût des générations dont le tour suivant n'a rien gardé, sur le coût de toutes les générations."
	}

	cadence_du_juge: {
		kind:    "contrainte"
		title:   "Le juge va dix fois plus vite que les agents"
		says:    "Un tour du juge dure au plus le dixième d'une génération. Sinon, les agents construisent sur ce qui n'est pas encore jugé."
		holds:   "inconnu"
		action:  "monter_le_premier_projet"
		with:    ["duree_generation"]
		why:     "Comme dans une chaîne de blocs : quand les validateurs traînent, les réorganisations arrivent."
		family:  "juge"
		measure: "La durée médiane d'un tour complet, et celle d'une génération."
	}

	juge_stable: {
		kind:    "contrainte"
		title:   "Le juge est stable"
		says:    "Sans changement du code, aucun verdict ne bascule d'un tour à l'autre."
		holds:   "inconnu"
		why:     "Un verdict instable est un validateur défaillant : il défait du travail sans aucune faute."
		family:  "juge"
		measure: "Les verdicts qui changent entre deux tours sans changement du candidat."
		action:  "trancher_le_seuil"
	}

	reorganisations_rares: {
		kind:    "contrainte"
		title:   "Les réorganisations restent rares"
		says:    "La part du travail construit sur un essai qui échoue reste sous 20 %."
		holds:   "inconnu"
		why:     "Chaque réorganisation rejoue du travail, et parfois le perd."
		family:  "juge"
		measure: "Les changements construits sur une tête à l'essai qui a échoué, sur tous les changements."
		action:  "etat_en_braid"
	}
}
