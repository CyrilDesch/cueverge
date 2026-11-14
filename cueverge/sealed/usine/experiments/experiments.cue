// @what: what was run, or is to be run, and what it showed. Every number is a measure that the experiments cogen recomputes.
// @invariant: this package computes nothing. A number in a result is the value of a measure of the same experiment.
// @ref: @/cueverge/cogen/gen-sealed/usine/experiments/experiments.cue
package experiments

import "github.com/cyrildesch/cueverge/schema"

#Experiment: {
	schema.#Fact...
	kind:      "expérience"
	_humanize: title
	title:     string
	says:      title
	question:  string
	method:    string
	status:    "fait" | "prévu" | "interrompu" | "écarté"
	cost:      "faible" | "moyen" | "élevé"
	result?:   string
	learned?:  [...string]
	limits?:   [...string]

	// @invariant: the polarity follows the status. Done holds, planned is unknown, stopped or discarded does not hold.
	if status == "fait" {holds: true}
	if status == "prévu" {holds: "inconnu"}
	if status == "interrompu" || status == "écarté" {holds: false}

	// @invariant: a finished experiment states its result and what it does not show.
	if status == "fait" {
		result!: string
		limits!: [string, ...string]
	}

	// @invariant: an experiment that did not run says why.
	if status == "interrompu" || status == "écarté" {
		result!: string
	}
}

// @what: one number an experiment measured. The experiments cogen recomputes it from the runs or the journal.
#Measure: {
	schema.#Fact...
	kind: "mesure"
	experiment: or([for k, _ in experiments {
		k...
	}])
	holds: true
	value: number
}

experiments: [string]: #Experiment
measures: [string]:    #Measure

// @what: every sealed fact of the package. An experiment and a measure never share a key.
facts: {
	for k, e in experiments {
		(k): e...
	}
	for k, m in measures {
		(k): m...
	}
}

experiments: {
	boucle_differentielle: {
		title:    "Boucle différentielle contre une référence"
		question: "Un test e2e contre un oracle vivant se monte-t-il vite, et dirige-t-il les corrections ?"
		method:   "Sur le premier projet, le fork de Mistral Vibe avec Tacit. Le noyau envoie chaque cas du corpus à la référence, la version de Vibe figée au départ, et au candidat, compare les sorties et enregistre le tour."
		status:   "prévu"
		cost:     "faible"
	}

	localisation_des_rejets: {
		title:    "Comparer l'endroit du rejet, pas seulement le rejet"
		question: "Quand les deux parties rejettent une entrée, est-ce au même endroit ?"
		method:   "Une règle de l'initiative extrait l'endroit que nomme chaque rejet. Le noyau compare les endroits, pas seulement le fait de rejeter."
		status:   "prévu"
		cost:     "faible"
	}

	budget_de_temps: {
		title:    "Une contrainte de temps de réponse portée par la boucle"
		question: "Une contrainte non fonctionnelle déclarée dans l'initiative est-elle appliquée sans que l'agent ait à s'en souvenir ?"
		method:   "Une ligne dans l'initiative déclare un budget de temps. Une réponse juste mais hors budget reçoit le verdict late et fait échouer le tour."
		status:   "prévu"
		cost:     "faible"
	}

	stabilite: {
		title:    "Trois exécutions sans changement donnent-elles les mêmes verdicts ?"
		question: "Le projet est-il déterministe ?"
		method:   "Lancer le noyau trois fois sans rien modifier et compter les cas dont le verdict change. Refaire la mesure avec la règle de reprise du temps, puis sous forte charge."
		status:   "prévu"
		cost:     "faible"
	}

	programme_a_effets: {
		title:    "Un programme à trois effets et cinq mutations"
		question: "Combien de bugs la comparaison des effets attrape-t-elle en plus de la comparaison des résultats ?"
		method:   "Un petit programme (appel HTTP sortant, magasin clé-valeur, horloge), un journal d'effets, des règles écrites d'abord, cinq mutations injectées."
		status:   "écarté"
		cost:     "moyen"
		result:   "Écarté : l'interpréteur CUE reste le bon exercice. L'idée des effets a été généralisée en observations à adresse stable."
	}

	agent_autonome: {
		title:    "Un agent sans humain sur la boucle"
		question: "Un agent seul converge-t-il, et de façon reproductible ?"
		method:   "Lancer un agent seul depuis un candidat scellé, sans personne dans la boucle. Un seul périmètre modifiable, aucune régression tolérée, un budget de tours. L'empreinte des points fixes est prise avant et recalculée après, et le résultat est remesuré sans le rapport de l'agent."
		status:   "prévu"
		cost:     "élevé"
	}

	agent_reproductible: {
		title:    "Deux lancements, les mêmes décisions"
		question: "Deux lancements d'un agent depuis le même départ donnent-ils la même suite de décisions d'orchestration ?"
		method:   "Lancer deux fois l'agent par la table d'orchestration, depuis le même candidat scellé et avec le même budget. Comparer tour par tour la tâche choisie et la décision du juge."
		status:   "prévu"
		cost:     "élevé"
	}

	simplification_sous_contrainte: {
		title:    "Réduire le candidat sans rien casser"
		question: "Un agent peut-il simplifier l'intérieur sans relecture humaine ?"
		method:   "Objectif : réduire la taille du candidat. Contrainte : aucun verdict ne régresse. Regarder s'il simplifie vraiment ou s'il supprime du code que le corpus ne couvre pas."
		status:   "prévu"
		cost:     "moyen"
	}

	deux_variantes: {
		title:    "Deux variantes face à une suite de demandes cachées"
		question: "Deux solutions correctes au même instant se distinguent-elles par leur coût d'évolution ?"
		method:   "Deux agents construisent chacun un candidat sous les mêmes contraintes. La même suite de demandes cachées leur est appliquée. Mesurer le coût par demande et les régressions."
		status:   "prévu"
		cost:     "élevé"
	}

	loi_d_ordre: {
		title:    "Réordonner les champs ne change pas le résultat"
		question: "Une loi vérifiée sans oracle attrape-t-elle des bugs ?"
		method:   "Pour chaque cas, produire une variante aux champs réordonnés et exiger la même sortie du candidat."
		status:   "prévu"
		cost:     "faible"
	}

	braid_comme_etat: {
		title:    "L'état de l'orchestrateur comme un Braid"
		question: "gaps peut-il servir de répartiteur du travail ?"
		method:   "Écrire l'état comme un Braid sur les changes jj (un lot est un change) avec le module existant. Rejouer les exports du journal réel du projet dans des ordres mélangés et avec des doublons. Vérifier que l'état final est identique et que gaps désigne le travail choisi à la main."
		status:   "prévu"
		cost:     "moyen"
	}

	juge_en_cue: {
		title:    "Le juge écrit en contraintes CUE, décidé par cue vet"
		question: "Le jugement d'un tour peut-il sortir du code du noyau et devenir une rencontre de contraintes ?"
		method:   "Le noyau n'est qu'un exécutant : il écrit ses observations en CUE, les règles du module de l'usine donnent les verdicts, et cue vet décide contre le dernier tour scellé. Contrôles : une régression injectée, une règle relâchée."
		status:   "prévu"
		cost:     "faible"
	}

	points_fixes: {
		title:    "Points fixes par empreinte et règles qui ne se relâchent pas"
		question: "Peut-on empêcher matériellement un agent de déplacer un point fixe ou de relâcher une règle ?"
		method:   "Vérifier l'empreinte du noyau, de l'extracteur et du corpus avant chaque tour. Refuser, avec polaris projdiff, un changement des règles CUE qui n'est pas plus strict que l'ancien : la règle nouvelle R' doit être subsumée par l'ancienne R (R' ⊑ R), sauf accord d'un humain."
		status:   "prévu"
		cost:     "faible"
	}

	noyau_foncteur: {
		title:    "Le noyau comme foncteur en Scala"
		question: "L'abstraction tient-elle sur du code réel et sur deux initiatives ?"
		method:   "Donner au noyau Scala la forme d'un foncteur : un trait Initiative à types membres abstraits. Première instance : le premier projet. Seconde : une initiative d'une autre nature. Composer deux contraintes et vérifier que le verdict est leur conjonction."
		status:   "prévu"
		cost:     "moyen"
	}

	agent_sonnet: {
		title:    "Des boucles Sonnet sur le noyau Kyo"
		question: "Un petit modèle, lancé par le noyau entre deux tours, fait-il avancer le tronc ?"
		method:   "Des boucles de générations. Chaque génération lance Claude Code sans interface (claude -p, modèle sonnet) dans le bac à sable, avec un seul périmètre modifiable. Un tour refusé restaure le candidat scellé."
		status:   "prévu"
		cost:     "faible"
	}

	intention_sur_un_projet: {
		title:      "Une intention déclarée, tenue, puis approuvée"
		question:   "Une intention déclarée par l'agent et approuvée par une personne débloque-t-elle un correctif qu'un cas passé par accident bloquait ?"
		method:     "Une boucle Sonnet sur le noyau Kyo. Après chaque génération, l'agent termine par son intention : but, cas réparés, régressions assumées avec leur raison. Les règles d'intention du module de l'usine jugent le tour, et une personne approuve l'empreinte d'une intention qui excuse une régression."
		status:     "prévu"
		cost:       "faible"
		supersedes: "intention_sur_le_pilote"
	}
	rejeu_deterministe: {
		title:    "Rejouer un tour depuis son journal"
		question: "Les décisions d'un tour sont-elles une fonction de ce qu'il a enregistré ?"
		method:   "Rejouer un tour enregistré : un nouveau tour reçoit les champs du premier jusqu'à la décision, et décide à nouveau, sans relancer le candidat. Un tour qui a tenu, et un tour refusé."
		status:   "prévu"
		cost:     "faible"
	}
}

measures: {}

retired: [string]: schema.#Retired
retired: {
	"boucle_differentielle.cas":                {was: "Cas du corpus : 339 cas.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"boucle_differentielle.acceptes":           {was: "Cas acceptés par la référence : 154 cas.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"boucle_differentielle.vide":               {was: "Candidat vide, entrées valides correctes : 0 sur 154.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"boucle_differentielle.premier_jet":        {was: "Premier jet, entrées valides correctes : 94 sur 154.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"boucle_differentielle.apres_une_passe":    {was: "Après une passe, entrées valides correctes : 114 sur 154.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"boucle_differentielle.regressions":        {was: "Régressions au second tour : 8 cas.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"localisation_des_rejets.meme_chemin":      {was: "Les deux rejettent au même chemin : 109 cas.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"localisation_des_rejets.chemin_different": {was: "Les deux rejettent à un chemin différent : 32 cas.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"localisation_des_rejets.sans_chemin":      {was: "Une partie ne donne pas de chemin : 26 cas.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"localisation_des_rejets.deux_rejettent":   {was: "Les deux rejettent : 167 cas.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"budget_de_temps.hors_budget":              {was: "Cas justes mais hors budget : 4 cas.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"budget_de_temps.mediane":                  {was: "Temps médian d'un cas : 53 ms.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"budget_de_temps.p99":                      {was: "99e centile : 306 ms.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"budget_de_temps.pire":                     {was: "Pire cas juste mais hors budget : 1490 ms.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"stabilite.cas":                            {was: "Cas du corpus : 339 cas.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"stabilite.instables":                      {was: "Sans règle, cas instables sur trois exécutions : 15 cas.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"stabilite.instables_hors_temps":           {was: "Sans règle, cas instables sans verdict trop lent : 0 cas.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"stabilite.lents_1":                        {was: "Sans règle, trop lents à la première exécution : 21 cas.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"stabilite.lents_2":                        {was: "Sans règle, trop lents à la deuxième exécution : 7 cas.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"stabilite.lents_3":                        {was: "Sans règle, trop lents à la troisième exécution : 6 cas.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"stabilite.avec_regle":                     {was: "Avec la règle, exécutions mesurées : 9 exécutions.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"stabilite.avec_regle_min":                 {was: "Avec la règle, le moins de trop lents par exécution : 2 cas.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"stabilite.avec_regle_max":                 {was: "Avec la règle, le plus de trop lents par exécution : 4 cas.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"stabilite.sous_charge":                    {was: "Sous charge, trop lents avec reprise immédiate : 303 cas.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"stabilite.mediane_min":                    {was: "Temps médian d'un cas, la plus basse des exécutions sans charge : 49 ms.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"stabilite.mediane_max":                    {was: "Temps médian d'un cas, la plus haute des exécutions sans charge : 61 ms.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"agent_autonome.valides":                   {was: "Entrées valides du corpus : 154 entrées.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"agent_autonome.depart":                    {was: "Départ, entrées valides correctes : 111 sur 154.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"agent_autonome.depart_reussis":            {was: "Départ, cas réussis : 243 sur 339.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"agent_autonome.fin":                       {was: "Agent Opus, fin, entrées valides correctes : 144 sur 154.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"agent_autonome.fin_reussis":               {was: "Agent Opus, fin, cas réussis : 319 sur 339.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"agent_autonome.premier_agent":             {was: "Premier agent, à la coupure : 133 sur 154.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"agent_autonome.gagnes":                    {was: "Cas gagnés par l'agent Opus : 76 cas.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"agent_autonome.perdus":                    {was: "Cas perdus par rapport au départ : 0 cas.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"agent_autonome.plantages_fin":             {was: "À la fin, plantages, dépassements de délai et cas non construits : 0 cas.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"juge_en_cue.tours_decides":                {was: "Tours complets du journal décidés par cue vet : 23 tours.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"agent_sonnet.generations":                 {was: "Générations Sonnet : 6 générations.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"agent_sonnet.cout":                        {was: "Coût des générations : 1.66 USD.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"agent_sonnet.refus":                       {was: "Tours refusés pour régression : 4 tours.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"agent_sonnet.meme_cas":                    {was: "Refus qui cassent le même cas que le premier : 3 tours.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"intention_sur_le_pilote.generations":      {was: "Générations Sonnet : 2 générations.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"intention_sur_le_pilote.cout":             {was: "Coût des générations : 0.89 USD.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"intention_sur_le_pilote.avant":            {was: "Avant, entrées valides correctes : 146 sur 154.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"intention_sur_le_pilote.apres":            {was: "Après, entrées valides correctes : 149 sur 154.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"intention_sur_le_pilote.valides":          {was: "Entrées valides du corpus : 154 entrées.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"intention_sur_le_pilote.repares":          {was: "Cas réparés : 4 cas.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"intention_sur_le_pilote.excuses":          {was: "Régressions excusées par une personne : 1 cas.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	"rejeu_deterministe.rejeux":                {was: "Tours rejoués depuis leur journal : 2 tours.", why: "Mesuré sur cue-interpreter, abandonné le 2026-11-14. L'expérience est à refaire sur le premier projet."}
	intention_sur_le_pilote:                    {was: "Une intention déclarée, tenue, puis approuvée, mesurée sur cue-interpreter.", why: "Le mot pilote ne désigne plus rien, et l'expérience est à refaire. Remplacée par intention_sur_un_projet."}
	"boucle_differentielle.duree_d_un_tour":    {was: "Durée d'un tour : environ 12 s, dont 10 s pour un cas qui dépasse le délai.", why: "Les exécutions du noyau Go ne gardent pas la durée d'un tour."}
	"budget_de_temps.trois_disjonctions":       {was: "Trois des cas trop lents sont des cas à disjonctions.", why: "Seuls 2 des 4 chemins nomment une disjonction. Le contenu des cas n'est pas exporté."}
	"stabilite.avec_regle_par_execution":       {was: "Avec la règle, 2 trop lents sur neuf exécutions sur dix, 3 sur une.", why: "Les exécutions donnent 9 exécutions avec la règle : 8 à 2 trop lents, 1 à 4."}
	"stabilite.zero_instable_quatre":           {was: "Avec la règle, zéro cas instable sur quatre exécutions, charge comprise.", why: "Rien ne dit quelles quatre exécutions. Les 9 exécutions avec la règle varient de 2 à 4 trop lents."}
	"stabilite.reprise_apres_phase":            {was: "Sous charge -j 32, 2 trop lents avec reprise après la phase parallèle.", why: "Aucune exécution exportée ne dit qu'elle tourne sous charge avec cette reprise."}
	"stabilite.mediane_56_60":                  {was: "Temps médian d'un cas : 56 à 60 ms.", why: "Les exécutions sans charge donnent des médianes de 49 à 61 ms."}
	"agent_autonome.treize_tours":              {was: "L'agent Opus a fait 13 tours complets sur 15 autorisés.", why: "Les exécutions exportées ne disent pas quel tour appartient à quel agent."}
	"agent_autonome.duree_d_un_tour":           {was: "Durée d'un tour : de 12 s à environ 4 s.", why: "Les exécutions du noyau Go ne gardent pas la durée d'un tour."}
	"agent_autonome.empreinte":                 {was: "Empreinte des points fixes identique.", why: "L'empreinte était imprimée par le noyau Go, jamais exportée."}
	"juge_en_cue.parite":                       {was: "Parité : 337 verdicts sur 339 identiques à l'ancien juge.", why: "Les observations de l'époque sont gardées sans verdict : il faudrait rejouer l'ancien juge."}
	"juge_en_cue.premier_tour_scelle":          {was: "Premier tour scellé : 145 sur 154 entrées valides correctes.", why: "Ce tour précède le journal Kyo. Aucune exécution exportée ne le porte."}
	"juge_en_cue.duree_d_un_tour":              {was: "Durée d'un tour : environ 4 s, dont l'évaluation CUE.", why: "Ce tour précède le journal Kyo. Aucune exécution exportée ne le porte."}
}
