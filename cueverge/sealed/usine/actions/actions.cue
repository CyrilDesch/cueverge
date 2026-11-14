// @what: what to do next, in order. Each action is a sealed fact. It holds when done, and is unknown until then.
// @invariant: the factory rule applies here too. An action with no measure does not vet.
// @ref: @/cueverge/cogen/gen-sealed/usine/actions/actions.cue
package actions

import (
	"github.com/cyrildesch/cueverge/schema"
	"factory.local/kb/sealed/usine/experiments"
	"factory.local/kb/sealed/usine/questions"
)

#ExperimentRef: or([for k, _ in experiments.experiments {"cue://experiments/experiments.\(k)"}])
#QuestionRef:   or([for k, _ in questions.questions {"cue://questions/questions.\(k)"}])
#ActionRef:     or([for k, _ in actions {"cue://actions/actions.\(k)"}])

#Action: {
	schema.#Fact...
	_humanize: title
	order:     int & >0
	title:     string
	says:      title
	// @what: what to do.
	statement: string
	// @what: what is measured to say it is done.
	measure!: string
	// @what: the result that counts as done.
	verdict!: string
	status:   "à faire" | "en cours" | "fait"
	cost:     "faible" | "moyen" | "élevé"
	runs?:    [...#ExperimentRef]
	answers?: [...#QuestionRef]
	after?:   [...#ActionRef]
	// @invariant: an action that needs a person says so.
	needsHuman?: string

	// @invariant: the polarity follows the status. Done holds, the rest is unknown until its experiments run.
	if status == "fait" {holds: true}
	if status != "fait" {holds: "inconnu"}
}

actions: [string]: #Action

// @what: every sealed fact of the package.
facts: {for k, a in actions {
	(k): a...
}}
retired: [string]: schema.#Retired
retired: {
	remettre_le_pilote_au_vert:         {was: "Corriger les régressions ouvertes du pilote, le dernier tour de cue-interpreter.", why: "cue-interpreter est abandonné le 2026-11-14. Ses régressions n'ont plus de sens."}
	brancher_les_contraintes_du_pilote: {was: "Brancher sur le pilote les contraintes du catalogue qu'il peut porter.", why: "cue-interpreter est abandonné le 2026-11-14. Remplacée par brancher_les_contraintes_du_projet."}
	trancher_le_cadre_du_pilote:        {was: "Trancher trois questions du cadre du pilote, dont le sens de sans compilation.", why: "cue-interpreter est abandonné le 2026-11-14. Remplacée par trancher_le_cadre_du_projet, sans la question de la compilation."}
}

actions: {
	monter_le_premier_projet: {
		order:      1
		title:      "Monter le premier projet avec cueverge init"
		statement:  "Le premier projet est le fork de Mistral Vibe qui remplace le shell de l'agent par Tacit. cueverge init le prépare, une personne approuve son cadre, puis le noyau capture ses exports dans gen/."
		measure:    "Un tour du noyau sur le projet, et sa capture vérifiée par cueverge capture check."
		verdict:    "Le projet vérifie avec cue vet, un tour tient, et la capture correspond à ses empreintes."
		status:     "à faire"
		cost:       "moyen"
		runs:       ["cue://experiments/experiments.boucle_differentielle", "cue://experiments/experiments.localisation_des_rejets", "cue://experiments/experiments.budget_de_temps", "cue://experiments/experiments.rejeu_deterministe"]
		needsHuman: "Écrire la problématique du projet, puis approuver son cadre."
	}
	mesurer_la_stabilite: {
		order:     2
		title:     "Mesurer la stabilité des verdicts"
		statement: "Reprendre la mesure interrompue."
		measure:   "Trois exécutions sans changement, nombre de cas dont le verdict varie."
		verdict:   "Zéro cas instable, ou la liste des cas instables et la règle qui les rend stables."
		status:    "à faire"
		cost:      "faible"
		runs:      ["cue://experiments/experiments.stabilite"]
		answers:   ["cue://questions/questions.stabilite_des_verdicts"]
		after:     ["cue://actions/actions.monter_le_premier_projet"]
	}
	juge_en_cue: {
		order:     3
		title:     "Sortir le jugement du noyau et l'écrire en CUE"
		statement: "Le noyau observe et écrit ses observations en CUE. Les règles du module de l'usine donnent les verdicts. cue vet décide si le tour tient, contre le dernier tour scellé."
		measure:   "Une régression injectée, et une règle relâchée."
		verdict:   "La régression donne ⊥, et le relâchement est constaté."
		status:    "à faire"
		cost:      "faible"
		runs:      ["cue://experiments/experiments.juge_en_cue"]
		answers:   ["cue://questions/questions.apport_de_cue"]
		after:     ["cue://actions/actions.mesurer_la_stabilite"]
	}
	trancher_le_seuil: {
		order:      4
		title:      "Trancher le seuil de temps"
		statement:  "Écrire dans les règles ce que vaut un cas dont le temps est égal au budget."
		measure:    "Dix tours de suite sans changement du candidat."
		verdict:    "Aucun tour refusé sur du bruit."
		status:     "à faire"
		cost:       "faible"
		answers:    ["cue://questions/questions.seuil_de_temps"]
		after:      ["cue://actions/actions.juge_en_cue"]
		needsHuman: "Choisir entre une marge de tolérance et une bande autour du seuil."
	}
	verrouiller_les_points_fixes: {
		order:     5
		title:     "Verrouiller les points fixes et interdire de relâcher une règle"
		statement: "Empreinte du noyau, de l'extracteur et du corpus vérifiée avant chaque tour. Porte sur les règles CUE du module de l'usine (factory/rules/*.rules.cue) avec polaris projdiff : une règle nouvelle doit être plus stricte ou égale à l'ancienne (R' ⊑ R), sinon un humain tranche."
		measure:   "Deux essais : modifier le corpus sans signature, puis relâcher une règle."
		verdict:   "Le noyau refuse les deux."
		status:    "à faire"
		cost:      "faible"
		runs:      ["cue://experiments/experiments.points_fixes"]
		answers:   ["cue://questions/questions.apport_de_cue"]
		after:     ["cue://actions/actions.trancher_le_seuil"]
	}
	table_d_orchestration: {
		order:     6
		title:     "Écrire la table d'orchestration en CUE"
		statement: "Régression : annuler. Plantage : corriger d'abord. Puis accepte à tort, rejette à tort, rejet au mauvais endroit, trop lent, pas encore construit. Trois tours sans progrès ou budget atteint : arrêter et remonter."
		measure:   "Rejouer le journal des tours déjà faits à travers la table."
		verdict:   "La table désigne à chaque tour la tâche qui avait été choisie à la main, ou l'écart est expliqué."
		status:    "à faire"
		cost:      "faible"
		after:     ["cue://actions/actions.verrouiller_les_points_fixes"]
	}
	lancer_un_agent_autonome: {
		order:      7
		title:      "Lancer un agent sans humain sur la boucle"
		statement:  "L'agent est lancé par la table, avec une règle : aucune régression n'est scellée, sauf celle qu'une personne approuve dans une intention. Sans le mode automatique, chaque génération attend une personne : un lancement sans humain demande ce mode."
		measure:    "Score atteint, nombre de tours, coût en tokens, point de blocage."
		verdict:    "Le score du projet progresse sans régression scellée, et deux lancements donnent la même suite de décisions d'orchestration."
		status:     "en cours"
		cost:       "élevé"
		runs:       ["cue://experiments/experiments.agent_autonome", "cue://experiments/experiments.agent_sonnet", "cue://experiments/experiments.agent_reproductible"]
		answers:    ["cue://questions/questions.convergence_d_un_agent", "cue://questions/questions.grain_de_l_intention"]
		after:      ["cue://actions/actions.table_d_orchestration"]
		needsHuman: "Accord sur le budget de tokens avant le lancement."
	}
	loi_sans_oracle: {
		order:     8
		title:     "Brancher la loi d'ordre"
		statement: "Réordonner les champs d'un cas ne doit pas changer la sortie."
		measure:   "Nombre de cas où la loi échoue, et combien de ces bugs la référence attrapait déjà."
		verdict:   "Un chiffre : la part des bugs connus que la loi retrouve sans oracle."
		status:    "à faire"
		cost:      "faible"
		runs:      ["cue://experiments/experiments.loi_d_ordre"]
		answers:   ["cue://questions/questions.sans_oracle"]
		after:     ["cue://actions/actions.monter_le_premier_projet"]
	}
	etat_en_braid: {
		order:     9
		title:     "Porter l'état de l'orchestrateur avec Braid"
		statement: "Le code vit dans jj : un lot est un change, le tronc est fait des changes immuables. Braid porte les clés, les parents, les hauteurs et les verdicts. gaps répartit le travail."
		measure:   "Le journal rejoué dans dix ordres mélangés, avec doublons."
		verdict:   "Dix états finaux identiques, et gaps égal au choix de la table à chaque étape."
		status:    "à faire"
		cost:      "moyen"
		runs:      ["cue://experiments/experiments.braid_comme_etat"]
		answers:   ["cue://questions/questions.autorite_de_scellement", "cue://questions/questions.identite_d_une_tache"]
		after:     ["cue://actions/actions.table_d_orchestration"]
	}
	simplifier_sous_contrainte: {
		order:     10
		title:     "Faire simplifier le candidat par un agent"
		statement: "Objectif : moins de lignes. Contrainte : aucun verdict ne régresse."
		measure:   "Lignes retirées, verdicts avant et après, et lecture de ce qui a été retiré."
		verdict:   "Une réduction nette sans régression, ou la contrainte qui manquait quand l'agent a triché."
		status:    "à faire"
		cost:      "moyen"
		runs:      ["cue://experiments/experiments.simplification_sous_contrainte"]
		after:     ["cue://actions/actions.lancer_un_agent_autonome"]
	}
	deux_variantes_en_concurrence: {
		order:      11
		title:      "Comparer deux variantes par leur coût d'évolution"
		statement:  "Version réduite d'abord : le candidat actuel contre un second construit par un agent, sur trois demandes cachées."
		measure:    "Coût par demande et régressions, pour chaque variante."
		verdict:    "Un écart net entre les deux, ou le constat qu'il n'y en a pas."
		status:     "à faire"
		cost:       "élevé"
		runs:       ["cue://experiments/experiments.deux_variantes"]
		answers:    ["cue://questions/questions.gout_mesurable"]
		after:      ["cue://actions/actions.lancer_un_agent_autonome"]
		needsHuman: "Choisir les demandes cachées."
	}
	intention_relue: {
		order:      13
		title:      "Faire déclarer son intention à l'agent, et la faire tenir"
		statement:  "Après chaque génération, l'agent déclare son but, les cas qu'il répare et les régressions qu'il assume. Le noyau extrait cette intention, les règles d'intention du module de l'usine vérifient que le tour la tient, et une personne approuve son empreinte. Le mode automatique approuve seul une intention sans régression."
		measure:    "Un lancement de l'agent sur le projet : intentions extraites, intentions tenues, approbations demandées, et le cas qui passe par accident."
		verdict:    "Aucune intention vide ou fausse n'est scellée, et le correctif qui casse le cas passé par accident est scellé après approbation."
		status:     "à faire"
		cost:       "moyen"
		runs:       ["cue://experiments/experiments.intention_sur_un_projet"]
		answers:    ["cue://questions/questions.passage_par_accident", "cue://questions/questions.grain_de_l_intention"]
		needsHuman: "Approuver les intentions, et décider du mode automatique."
	}
	noyau_en_scala: {
		order:      12
		title:      "Réécrire le noyau comme foncteur, avec une seconde initiative"
		statement:  "Trait Initiative, effets dans les types, composition de deux contraintes."
		measure:    "Les mêmes verdicts que le noyau actuel sur le premier projet, et une seconde initiative d'une autre nature qui tourne."
		verdict:    "Verdicts identiques cas par cas, et aucune ligne du noyau modifiée pour la seconde initiative."
		status:     "à faire"
		cost:       "moyen"
		runs:       ["cue://experiments/experiments.noyau_foncteur"]
		answers:    ["cue://questions/questions.abstraction_du_noyau"]
		after:      ["cue://actions/actions.etat_en_braid"]
		needsHuman: "Choisir la seconde initiative."
	}
	initiative_de_service: {
		order:      14
		title:      "Monter une seconde initiative : un service avec état et déploiement"
		statement:  "Beaucoup de contraintes du catalogue demandent un état durable, un déploiement ou un appel sortant. Un petit service déployé les rend mesurables, en continu, avec une porte humaine sur ce qui ne se rattrape pas."
		measure:    "Les contraintes du catalogue sans équivalent sur le premier projet, branchées sur le service, et le chemin d'une écriture irréversible."
		verdict:    "Chaque contrainte branchée fait échouer un tour quand elle casse, et une écriture irréversible attend une personne."
		status:     "à faire"
		cost:       "élevé"
		after:      ["cue://actions/actions.noyau_en_scala"]
		needsHuman: "Choisir le service."
	}
	brancher_les_contraintes_du_projet: {
		order:      15
		title:      "Brancher sur le premier projet les contraintes du catalogue qu'il peut porter"
		statement:  "Données anciennes, anciens clients, idempotence, secrets dans les journaux, fuite mémoire, coût par requête : chacune devient une ligne de l'initiative et un verdict."
		measure:    "Pour chaque contrainte possible sur le projet, une mesure dans l'initiative et un tour qui la casse exprès."
		verdict:    "Le tour cassé est refusé pour chaque contrainte, ou on écrit pourquoi elle ne se branche pas."
		status:     "à faire"
		cost:       "moyen"
		after:      ["cue://actions/actions.trancher_le_seuil"]
		supersedes: "brancher_les_contraintes_du_pilote"
	}
	juger_sans_mesure: {
		order:      16
		title:      "Faire juger une contrainte sans mesure par un agent qui joue l'humain"
		statement:  "Un message d'erreur ou une alerte n'a pas de mesure. Un agent qui joue l'utilisateur, ou l'astreinte, donne un jugement. On le compare à celui d'une personne."
		measure:    "L'accord entre le jugement de l'agent et celui d'une personne, sur un échantillon de messages d'erreur du projet."
		verdict:    "Un taux d'accord, et la décision de garder ou non ce jugement comme verdict."
		status:     "à faire"
		cost:       "moyen"
		answers:    ["cue://questions/questions.contraintes_non_mesurables"]
		needsHuman: "Juger l'échantillon."
	}
	trancher_le_cadre_du_projet: {
		order:      17
		title:      "Trancher deux questions du cadre du premier projet"
		statement:  "Ce que borne le budget, et si l'agent peut interroger la référence à la main. Chaque choix devient une règle du cadre de l'initiative."
		measure:    "Une règle dans le cadre pour chaque choix, vérifiée par cue vet."
		verdict:    "Les deux questions ont une règle, ou une raison écrite de ne pas en avoir."
		status:     "à faire"
		cost:       "faible"
		answers:    ["cue://questions/questions.budget_contournable", "cue://questions/questions.acces_a_l_oracle"]
		needsHuman: "Faire les deux choix."
		supersedes: "trancher_le_cadre_du_pilote"
	}
	features_derriere_un_drapeau: {
		order:      18
		title:      "Proposer une feature derrière un drapeau, et la retirer avec une trace"
		statement:  "Le système propose une feature qui ajoute sans relâcher, déclare son hypothèse, la mesure, et la retire avec un tombstone gardé par une condition."
		measure:    "Une feature proposée, son hypothèse, sa mesure sur du trafic réel, et son tombstone."
		verdict:    "La feature est gardée ou retirée sur sa mesure, et un tombstone retiré revient quand sa condition tombe."
		status:     "à faire"
		cost:       "élevé"
		after:      ["cue://actions/actions.initiative_de_service"]
		needsHuman: "Attendre des utilisateurs réels."
	}
}
