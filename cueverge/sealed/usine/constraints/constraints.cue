// @what: a catalog of constraints an agent forgets.
// @invariant: a constraint has a statement, a measure and a cadence, or it says that no measure is known.
// @invariant: a wired constraint holds as its measure says. Any other is unknown and names an action not done.
// @ref: @/cueverge/cogen/gen-sealed/usine/constraints/constraints.cue
package constraints

import (
	"github.com/cyrildesch/cueverge/schema"
	"factory.local/kb/sealed/usine/actions"
)

#ActionRef: or([for k, _ in actions.actions {
	k...
}])

#Constraint: {
	schema.#Fact...
	says:      statement
	statement: string
	// @what: the action that builds the measure of a constraint not wired on the project.
	action?:   #ActionRef
	family:    "casser quelque chose" | "plusieurs versions" | "entrelacement rare" | "absence" | "temps et échelle" | "simple" | "sans mesure connue"
	measure:   string
	cadence:   "chaque tour" | "à chaque déploiement" | "nocturne" | "hebdomadaire" | "aucune"
	onProject: "branché" | "possible" | "sans équivalent"

	// @why: a constraint with no known measure is a visible debt, not an assumed property.
	if family == "sans mesure connue" {
		cadence: "aucune"
	}
	if family != "sans mesure connue" {
		cadence: !="aucune"
	}
	if onProject == "branché" {holds: bool}
	if onProject != "branché" {
		holds:   "inconnu"
		action!: _
	}
}

constraints: [string]: #Constraint

// @what: every sealed fact of the package.
facts: {for k, c in constraints {
	(k): c...
}}
retired: [string]: schema.#Retired
retired: {}

constraints: {
	reponse_rapide: {statement: "Un endpoint répond sous 100 ms", family: "simple", measure: "Chronométrer chaque réponse", cadence: "chaque tour", onProject: "possible", action: "brancher_les_contraintes_du_projet"}

	reprise_deux_dc:   {statement: "Redémarrage sur 2 DC sans sauvegarde en moins de 10 minutes", family: "casser quelque chose", measure: "Tout détruire, chronométrer jusqu'à la première réponse correcte", cadence: "hebdomadaire", onProject: "sans équivalent", action: "initiative_de_service"}
	annulation:        {statement: "Tout déploiement est annulable en moins de 5 minutes", family: "casser quelque chose", measure: "Déployer, annuler, comparer l'état avant et après", cadence: "à chaque déploiement", onProject: "sans équivalent", action: "initiative_de_service"}
	dependance_perdue: {statement: "La perte d'une dépendance dégrade le service sans l'arrêter", family: "casser quelque chose", measure: "Couper la dépendance, vérifier quelles routes répondent encore", cadence: "nocturne", onProject: "sans équivalent", action: "initiative_de_service"}

	donnees_anciennes: {statement: "Une donnée écrite par la version 1 reste lisible par la version N", family: "plusieurs versions", measure: "Garder un jeu de données par version, le relire", cadence: "chaque tour", onProject: "possible", action: "brancher_les_contraintes_du_projet"}
	deux_versions:     {statement: "Deux versions tournent côte à côte pendant une mise à jour", family: "plusieurs versions", measure: "Faire tourner N et N+1 sur le même état, comparer", cadence: "à chaque déploiement", onProject: "sans équivalent", action: "initiative_de_service"}
	anciens_clients:   {statement: "Un client d'il y a six mois fonctionne encore", family: "plusieurs versions", measure: "Rejouer les requêtes enregistrées des anciens clients", cadence: "chaque tour", onProject: "possible", action: "brancher_les_contraintes_du_projet"}

	idempotence:           {statement: "Rejouer une requête ne change rien", family: "entrelacement rare", measure: "Envoyer chaque écriture deux fois, comparer l'état", cadence: "chaque tour", onProject: "possible", action: "brancher_les_contraintes_du_projet"}
	ecritures_simultanees: {statement: "Deux écritures simultanées n'en perdent aucune", family: "entrelacement rare", measure: "N écritures concurrentes, compter ce qui reste", cadence: "nocturne", onProject: "sans équivalent", action: "initiative_de_service"}
	une_seule_fois:        {statement: "Un message est traité une fois, même après un crash", family: "entrelacement rare", measure: "Tuer le processus à des points aléatoires, vérifier le compte", cadence: "nocturne", onProject: "sans équivalent", action: "initiative_de_service"}

	pas_de_secret:    {statement: "Aucun secret dans les journaux", family: "absence", measure: "Injecter un secret marqué, le chercher dans toutes les sorties", cadence: "chaque tour", onProject: "possible", action: "brancher_les_contraintes_du_projet"}
	controle_d_acces: {statement: "Aucune route sans contrôle d'accès", family: "absence", measure: "Lister les routes, appeler chacune sans identité", cadence: "chaque tour", onProject: "sans équivalent", action: "initiative_de_service"}
	region:           {statement: "Aucune donnée ne quitte la région", family: "absence", measure: "Enregistrer les appels sortants, vérifier les destinations", cadence: "chaque tour", onProject: "sans équivalent", action: "initiative_de_service"}

	fuite_memoire:    {statement: "Pas de fuite mémoire", family: "temps et échelle", measure: "Mémoire après 10 000 requêtes contre mémoire après 100", cadence: "nocturne", onProject: "possible", action: "brancher_les_contraintes_du_projet"}
	charge:           {statement: "Tient dix fois la charge actuelle", family: "temps et échelle", measure: "Tir de charge, vérifier les autres contraintes pendant", cadence: "hebdomadaire", onProject: "sans équivalent", action: "initiative_de_service"}
	suppression:      {statement: "Une donnée supprimée l'est partout sous 30 jours", family: "temps et échelle", measure: "Créer, supprimer, chercher dans tous les stockages, horloge accélérée", cadence: "nocturne", onProject: "sans équivalent", action: "initiative_de_service"}
	cout_par_requete: {statement: "Le coût par requête reste sous un plafond", family: "temps et échelle", measure: "Ressources consommées divisées par requêtes servies", cadence: "chaque tour", onProject: "possible", action: "brancher_les_contraintes_du_projet"}

	ordre_des_champs: {statement: "Réordonner les champs d'une entrée ne change pas le résultat", family: "simple", measure: "Évaluer une variante réordonnée de chaque cas", cadence: "chaque tour", onProject: "possible", action: "loi_sans_oracle"}

	message_d_erreur: {statement: "Un message d'erreur permet à l'utilisateur de corriger seul", family: "sans mesure connue", measure: "Un jugement, humain ou d'un agent jouant l'humain", cadence: "aucune", onProject: "sans équivalent", action: "juger_sans_mesure"}
	alerte_comprise:  {statement: "L'astreinte comprend l'alerte à trois heures du matin", family: "sans mesure connue", measure: "Un jugement humain", cadence: "aucune", onProject: "sans équivalent", action: "juger_sans_mesure"}
}
