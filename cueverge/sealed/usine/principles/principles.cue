// @what: the ideas the factory rests on. Each one says whether a project tested it, or what will test it.
// @invariant: a principle is intent. Its rule checks that it is consistent with the experiments and actions, never a source.
// @ref: @/cueverge/cogen/gen-sealed/usine/principles/principles.cue
package principles

import (
	"github.com/cyrildesch/cueverge/schema"
	"factory.local/kb/sealed/usine/actions"
	"factory.local/kb/sealed/usine/experiments"
)

#ExperimentRef: or([for k, _ in experiments.experiments {"cue://experiments/experiments.\(k)"}])
#ActionRef:     or([for k, _ in actions.actions {"cue://actions/actions.\(k)"}])

#Principle: {
	schema.#Fact...
	_humanize: title
	title:     string
	says:      title
	statement: string
	status:    "testé sur un projet" | "posé, non testé"
	evidence?: [...#ExperimentRef]
	// @what: the experiment or the action that will test an untested principle.
	testedBy?: #ExperimentRef | #ActionRef
	limits?:   [...string]

	// @invariant: the status follows from the evidence. It is never declared alone.
	if evidence != _|_ if len(evidence) > 0 {status: "testé sur un projet"}
	if evidence == _|_ {status: "posé, non testé"}

	// @invariant: tested holds, untested is unknown and names what will test it.
	if status == "testé sur un projet" {holds: true}
	if status == "posé, non testé" {
		holds:     "inconnu"
		testedBy!: _
	}
}

principles: [string]: #Principle

// @what: every sealed fact of the package.
facts: {for k, p in principles {
	(k): p...
}}
retired: [string]: schema.#Retired
retired: {}

principles: {
	enveloppe: {
		title:     "L'humain écrit le cadre, les agents écrivent le code"
		statement: "L'humain pose la problématique, les contraintes et ce qu'on tolère. Personne ne relit le code produit. On relit le cadre, les intentions et ce qui relâche le cadre."
		status:    "posé, non testé"
		testedBy:  "cue://actions/actions.lancer_un_agent_autonome"
	}
	problematique_et_contraintes: {
		title:     "Une problématique et des contraintes"
		statement: "Des contraintes seules n'attirent vers rien : un programme vide en respecte beaucoup. Il faut un objectif mesurable qui tire, et des contraintes qui bornent. L'innovation est alors une optimisation sous contraintes."
		status:    "posé, non testé"
		testedBy:  "cue://experiments/experiments.simplification_sous_contrainte"
		limits:    ["Une problématique qu'on ne sait pas mesurer ne donne aucune direction à l'agent."]
	}
	frontieres: {
		title:     "Observer aux frontières, jamais l'intérieur"
		statement: "On ne vérifie pas chaque fonction. Ce qui n'est pas observé peut être réécrit ou supprimé sans toucher à une vérification : c'est ce qui rend le système simplifiable."
		status:    "posé, non testé"
		testedBy:  "cue://experiments/experiments.simplification_sous_contrainte"
	}
	la_regle_avant_l_observation: {
		title:     "On n'observe que ce qu'une règle lit"
		statement: "Trois niveaux : le verdict, l'endroit, le détail interne. Le dernier ne s'ouvre que sur un cas qui échoue. Un niveau ne s'ajoute que s'il attrape des bugs que le précédent laissait passer."
		status:    "posé, non testé"
		testedBy:  "cue://experiments/experiments.localisation_des_rejets"
	}
	observations_adressees: {
		title:     "Un journal d'observations à adresse stable"
		statement: "La vision par effets, généralisée. Pour un service, l'adresse est l'appel sortant. Pour un interpréteur, le chemin dans l'arbre. Pour une preuve, l'étape. On écrit les règles de comparaison avant d'exécuter."
		status:    "posé, non testé"
		testedBy:  "cue://experiments/experiments.localisation_des_rejets"
		limits:    ["Le journal d'un candidat n'est pas encore comparé d'une itération à l'autre."]
	}
	la_version_precedente_comme_oracle: {
		title:     "La version précédente est l'oracle"
		statement: "Un oracle complet est rare. Dès la deuxième version, la précédente dit ce qui a changé. Une feature est un écart déclaré ; tout autre écart est une régression."
		status:    "posé, non testé"
		testedBy:  "cue://experiments/experiments.boucle_differentielle"
		limits:    ["Elle dit différent, pas juste. La première version n'a pas de base."]
	}
	contrainte_executee: {
		title:     "Une contrainte non exécutée sera oubliée"
		statement: "Une contrainte existe si elle a un énoncé, une mesure que la boucle sait prendre et un verdict qui fait échouer le tour. L'agent n'a pas à s'en souvenir : la boucle s'en souvient. Sans mesure, c'est une dette à rendre visible."
		status:    "posé, non testé"
		testedBy:  "cue://experiments/experiments.budget_de_temps"
	}
	test_continu: {
		title:     "Le test est continu, pas attaché à la PR"
		statement: "Trois cadences : un sous-ensemble rapide à chaque changement, les contraintes peu chères en continu sur le système déployé, les exercices coûteux planifiés. En échange il faut savoir quel changement a cassé et annuler sans humain."
		status:    "posé, non testé"
		testedBy:  "cue://actions/actions.initiative_de_service"
		limits:    ["Le premier projet n'a pas encore de déploiement ni d'exécution continue."]
	}
	intention_relue: {
		title:     "L'humain relit l'intention, la boucle vérifie qu'elle est tenue"
		testedBy:  "cue://experiments/experiments.intention_sur_un_projet"
		statement: "Avant un tour, l'agent déclare son intention : le but, le périmètre qu'il touche, l'effet attendu sur les cas, et les régressions annoncées avec leur raison. L'humain relit ces quelques lignes, jamais le diff. Le juge refuse un tour qui sort de l'intention approuvée, même si toutes les autres règles passent. Un mode automatique approuve seul une intention de routine : aucune régression annoncée, un périmètre dans celui de l'initiative, aucune règle ni point fixe touché. Activer ce mode retire un regard humain : c'est un relâchement, et seul l'humain l'active."
		limits: [
			"Le juge vérifie le périmètre et le sens des effets, pas qu'une raison donnée est vraie.",
			"Une intention vague passe toute vérification : le format doit exiger l'effet attendu.",
		]
	}
	semi_lights_off: {
		title:     "Semi : une porte humaine sur l'irréversible"
		statement: "Ce qui se rattrape est détecté après coup et annulé. Ce qui ne se rattrape pas (migration destructive, envoi à un tiers, écriture en production) passe par une validation humaine avant exécution."
		status:    "posé, non testé"
		testedBy:  "cue://actions/actions.initiative_de_service"
	}
	trois_couches: {
		title:     "Un déterminisme qui grandit autour de points fixes"
		statement: "Points fixes : invariants, juge, sens d'un verdict, modifiés par l'humain seul. Règles évolutives : les agents en ajoutent tant que ça resserre. Code produit : libre. Relâcher une règle est une demande à l'humain."
		status:    "posé, non testé"
		testedBy:  "cue://experiments/experiments.points_fixes"
		limits:    ["Un point fixe doit être une impossibilité matérielle, pas une consigne."]
	}
	orchestration_deterministe: {
		title:     "L'orchestrateur est un programme, pas un agent"
		statement: "Une table de règles : tel état, telle action. Le modèle est appelé comme une fonction sur une tâche bornée. Quand aucune ligne ne correspond, la décision remonte à un humain et devient une ligne."
		status:    "posé, non testé"
		testedBy:  "cue://actions/actions.table_d_orchestration"
	}
	etat_convergent: {
		title:     "L'état est le join du journal"
		statement: "L'état d'une initiative est un Braid : candidats ouverts, tronc scellé. Les rapports arrivent dans n'importe quel ordre. Le travail à lancer est gaps de l'état. Après une panne, on rejoue le journal."
		status:    "posé, non testé"
		testedBy:  "cue://experiments/experiments.braid_comme_etat"
		limits: [
			"L'autorité qui scelle reste à définir.",
			"Un nœud a un seul parent : les candidats se rebasent, ils ne se fusionnent pas.",
		]
	}
	propriete_exclusive: {
		title:     "Des travailleurs propriétaires, sans messagerie"
		statement: "Un travailleur possède son bac à sable, ses fichiers et son budget. Les travailleurs ne se parlent pas : ils lisent et écrivent un état partagé. Aucun fait privé."
		status:    "posé, non testé"
		testedBy:  "cue://experiments/experiments.braid_comme_etat"
	}
	synchronisation_au_scellement: {
		title:     "Un seul point de synchronisation : le scellement"
		statement: "Lire la tête, travailler seul, publier, sceller, se rebaser. Les doublons de travail se limitent par revendication datée, départage déterministe, attribution par propriété et annulation par l'état."
		status:    "posé, non testé"
		testedBy:  "cue://experiments/experiments.braid_comme_etat"
		limits:    ["Deux tâches distinctes de même cause profonde ne sont pas reconnues comme doublons."]
	}
	gout_par_le_cout_du_changement: {
		title:     "Le goût se mesure au coût du prochain changement"
		statement: "On teste plusieurs solutions sous une suite de demandes et on garde celle qui les absorbe au moindre coût."
		status:    "posé, non testé"
		testedBy:  "cue://experiments/experiments.deux_variantes"
		limits:    ["Le goût sur le produit demande des utilisateurs réels."]
	}
	features_et_tombstones: {
		title:     "Le système propose, mesure, et retire avec une trace"
		statement: "Une feature proposée ajoute sans relâcher, naît derrière un drapeau et déclare son hypothèse avant l'expérience. Retirée, elle laisse un tombstone gardé par une condition lue sur des observations. Quand la condition tombe, la feature peut revenir."
		status:    "posé, non testé"
		testedBy:  "cue://actions/actions.features_derriere_un_drapeau"
		limits:    ["Un logiciel neuf a peu de trafic : la plupart des tests A/B ne concluront pas."]
	}
	noyau_abstrait: {
		title:     "Un noyau abstrait autour de n'importe quelle initiative"
		statement: "Le noyau est un foncteur : une initiative entre, une boucle sort. Il compose sur la validation (resserrer, conjoindre), pas sur la génération."
		status:    "posé, non testé"
		testedBy:  "cue://experiments/experiments.noyau_foncteur"
		limits:    ["Une seule initiative et un seul type de juge existent."]
	}
}
