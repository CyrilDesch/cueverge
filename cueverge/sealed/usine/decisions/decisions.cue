// @what: what the conversation settled, and what it only leaned towards.
// @invariant: a decision is intent. Its rule checks it against the principles and actions, never against a source.
// @ref: @/cueverge/cogen/gen-sealed/usine/decisions/decisions.cue
package decisions

import (
	"github.com/cyrildesch/cueverge/schema"
	"factory.local/kb/sealed/usine/actions"
	"factory.local/kb/sealed/usine/experiments"
	"factory.local/kb/sealed/usine/principles"
)

#PrincipleRef:  or([for k, _ in principles.principles {"cue://principles/principles.\(k)"}])
#ActionRef:     or([for k, _ in actions.actions {"cue://actions/actions.\(k)"}])
#ExperimentRef: or([for k, _ in experiments.experiments {"cue://experiments/experiments.\(k)"}])

#Decision: {
	schema.#Fact...
	_humanize: title
	title:     string
	says:      title
	decision:  string
	why:       string
	status:    "acté" | "à confirmer" | "reporté"
	rejected?: string
	restsOn?:  [...#PrincipleRef]
	// @what: the action or the experiment that will settle a decision not settled yet.
	settledBy?: #ActionRef | #ExperimentRef

	// @invariant: a settled decision holds and rests on tested principles. The others are unknown and name what settles them.
	if status == "acté" {
		holds:    true
		restsOn!: [_, ...]
	}
	if status != "acté" {
		holds:      "inconnu"
		settledBy!: _
	}
}

decisions: [string]: #Decision

// @what: every sealed fact of the package.
facts: {for k, d in decisions {
	(k): d...
}}
retired: [string]: schema.#Retired
retired: {
	pilote_interpreteur_cue: {was: "Le pilote est un interpréteur CUE sans compilation.", why: "cue-interpreter est abandonné le 2026-11-14. Remplacée par premier_projet_vibe_tacit."}
}

decisions: {
	partir_de_zero: {
		title:     "Du logiciel neuf, pas le code existant"
		decision:  "L'usine construit des logiciels depuis zéro. Les études faites sur le code existant servent d'acquis, pas de terrain."
		why:       "Sans existant, la pile et le processus sont libres, et c'est la pile qui décide de la durée d'une itération."
		status:    "à confirmer"
		settledBy: "cue://actions/actions.lancer_un_agent_autonome"
		restsOn:   ["cue://principles/principles.enveloppe"]
	}
	premier_projet_vibe_tacit: {
		title:      "Le premier projet est Mistral Vibe avec Tacit"
		decision:   "Le premier projet construit par l'usine est un fork de Mistral Vibe qui remplace le shell de l'agent par Tacit : du code Scala aux capacités typées, que le compilateur vérifie."
		why:        "Le contrôle des commandes shell de Vibe a des failles ouvertes. Le projet a ses propres tests et scénarios pour juger, et il sert un besoin européen."
		status:     "à confirmer"
		settledBy:  "cue://actions/actions.monter_le_premier_projet"
		restsOn:    ["cue://principles/principles.noyau_abstrait"]
		supersedes: "pilote_interpreteur_cue"
	}
	e2e_reel_d_abord: {
		title:     "Du test e2e réel avant tout design"
		decision:  "Chaque idée passe par une mesure sur un projet réel avant d'être développée."
		why:       "La conversation dérivait vers un outil imaginaire."
		status:    "à confirmer"
		settledBy: "cue://experiments/experiments.budget_de_temps"
		restsOn:   ["cue://principles/principles.contrainte_executee"]
	}
	pas_de_verification_par_fonction: {
		title:     "Pas de vérification fonction par fonction"
		decision:  "Le journal complet de l'intérieur du candidat est abandonné."
		why:       "Le tout doit rester simplifiable."
		rejected:  "Émettre chemin et valeur pour tout l'arbre à chaque tour."
		status:    "à confirmer"
		settledBy: "cue://experiments/experiments.simplification_sous_contrainte"
		restsOn:   ["cue://principles/principles.frontieres", "cue://principles/principles.la_regle_avant_l_observation"]
	}
	test_continu_plutot_que_pr: {
		title:     "Les contraintes vivent en test continu"
		decision:  "La PR ne garde qu'un sous-ensemble rapide. Le reste est vérifié sur le système qui tourne."
		why:       "Beaucoup de contraintes n'ont pas de sens sur un diff, et tout vérifier avant fusion allonge la boucle."
		status:    "à confirmer"
		settledBy: "cue://actions/actions.initiative_de_service"
		restsOn:   ["cue://principles/principles.test_continu", "cue://principles/principles.semi_lights_off"]
	}
	pas_de_flink: {
		title:     "Pas de Flink ni de Fluss pour l'instant"
		decision:  "L'orchestrateur est une fonction pure sur un journal. Le moteur est une décision de déploiement, reportée."
		why:       "Un run d'agent est long, coûteux et à effets : un moteur de flux le rejouerait après une panne. Le débit visé ne justifie pas un cluster."
		status:    "à confirmer"
		settledBy: "cue://actions/actions.table_d_orchestration"
		restsOn:   ["cue://principles/principles.orchestration_deterministe", "cue://principles/principles.etat_convergent"]
	}
	propriete_plutot_qu_acteurs: {
		title:     "Propriété exclusive et état partagé, pas des acteurs"
		decision:  "On garde des acteurs la propriété des ressources, l'isolation des pannes et le traitement en série. On écarte la messagerie directe et l'état privé."
		why:       "Spawn a vu le volume de messages quadrupler en doublant le nombre d'agents, et a supprimé ce canal."
		status:    "à confirmer"
		settledBy: "cue://experiments/experiments.braid_comme_etat"
		restsOn:   ["cue://principles/principles.propriete_exclusive"]
	}
	jj_comme_gestionnaire_de_versions: {
		title:     "jj, sur le modèle de Mercurial"
		decision:  "Les candidats sont portés par jj : identité stable du changement, rebasage automatique, conflits comme données, têtes immuables, un espace de travail par agent."
		why:       "Les phases et les marqueurs d'obsolescence de Mercurial correspondent aux zones ouverte et scellée. jj les donne en gardant Git comme stockage."
		rejected:  "Git nu : un rebasage y casse l'identité du changement."
		status:    "à confirmer"
		settledBy: "cue://experiments/experiments.braid_comme_etat"
		restsOn:   ["cue://principles/principles.synchronisation_au_scellement"]
	}
	braid_pour_l_orchestrateur: {
		title:     "Braid porte l'état de l'orchestrateur"
		decision:  "Réutiliser le module Braid : zone ouverte pour les candidats, zone scellée pour le tronc, gaps comme répartiteur."
		why:       "Le join ne dépend pas de l'ordre et ses lois sont déjà vérifiées."
		status:    "à confirmer"
		settledBy: "cue://actions/actions.etat_en_braid"
		restsOn:   ["cue://principles/principles.etat_convergent"]
	}
	noyau_en_scala: {
		title:     "Le noyau en Scala avec Kyo"
		decision:  "Le noyau est écrit en Scala 3 avec Kyo. La forme de foncteur (trait Initiative, effets dans les types) reste à écrire."
		why:       "Le typage garantit qu'un candidat ne touche pas le monde sans le dire. Le noyau est un point fixe, compilé rarement. Braid est en Scala."
		status:    "à confirmer"
		settledBy: "cue://experiments/experiments.noyau_foncteur"
		restsOn:   ["cue://principles/principles.noyau_abstrait"]
	}
	features_autonomes: {
		title:     "Features proposées par le système, A/B et tombstones"
		decision:  "Voulu, mais construit après la boucle de base et l'arrivée d'utilisateurs réels."
		why:       "Un registre de features n'a de sens qu'avec du trafic à mesurer."
		status:    "reporté"
		settledBy: "cue://actions/actions.features_derriere_un_drapeau"
		restsOn:   ["cue://principles/principles.features_et_tombstones"]
	}
	base_source_de_verite: {
		title:     "La base porte le savoir de l'usine et les captures de ses projets"
		decision:  "Le savoir de l'usine, ses règles et les captures des exports de ses projets vivent dans cette base. Chaque projet garde son cadre, son sceau, son journal et son code, et importe l'outil."
		why:       "Une contrainte, une problématique ou une trace hors d'une base n'est pas vérifiable par elle. Importer un projet depuis l'outil qu'il importe ferait une boucle."
		status:    "à confirmer"
		settledBy: "cue://actions/actions.monter_le_premier_projet"
		restsOn:   ["cue://principles/principles.contrainte_executee"]
	}
	tout_fait_soutenu: {
		title:     "Tout fait est soutenu, sinon la base ne passe pas"
		decision:  "Un fait est déclaré par un change jj décrit, ou généré par un mécanisme que la base vérifie. Une affirmation dit de quoi elle parle ; elle est périmée dès que son sujet change après elle. Une observation se calcule, elle ne se recopie pas."
		why:       "Un texte resté vrai par habitude est la dette la plus difficile à voir : quatre textes décrivaient encore un noyau réécrit."
		status:    "à confirmer"
		settledBy: "cue://experiments/experiments.budget_de_temps"
		restsOn:   ["cue://principles/principles.contrainte_executee"]
	}
	tour_en_kyo_flow: {
		title:     "Un tour est un Kyo Flow, journalisé en CUE"
		decision:  "Chaque nœud d'un tour est enregistré avant le suivant. Le journal brut est le stockage de Kyo ; ce qu'on garde en est l'export, vérifié contre lui."
		why:       "Les décisions deviennent une fonction du journal : un tour se rejoue sans relancer le candidat."
		status:    "à confirmer"
		settledBy: "cue://experiments/experiments.braid_comme_etat"
		restsOn:   ["cue://principles/principles.etat_convergent"]
	}
	generateur_claude_code: {
		title:     "Le générateur est Claude Code, sans interface"
		decision:  "Une génération lance claude -p avec le modèle, le budget et les permissions déclarés dans le cadre de l'exemple, et journalise sa trace."
		why:       "Faire exactement ce que fait Claude Code, avec un petit modèle tant qu'on teste."
		status:    "à confirmer"
		settledBy: "cue://actions/actions.lancer_un_agent_autonome"
		restsOn:   ["cue://principles/principles.enveloppe"]
	}
}
