// @what: what the Anthropic article on Scion states. Every fact is attributed to Anthropic, and none is checked against the world.
// @ref: @/cueverge/cogen/gen-sealed/anthropic/scion/scion.cue
// @ref: @/cueverge/gen/web/anthropic-scion/page.gen.cue
package scion

import "github.com/cyrildesch/cueverge/schema"

schema.#Sealed

_selon: "Anthropic, « Redesigning source control at Anthropic »"
facts: [string]: selon: _selon

facts: {
	goulot:                   {says: "Le goulot n'est plus d'écrire du code, mais les outils faits pour un rythme humain : gestion de source, builds, CI.", holds: true}
	fusions_mai:              {says: "En mai 2026, environ 2 500 changements fusionnés par jour dans le monorepo.", holds: true, value: 2500, unit: "par jour"}
	fusions_septembre:        {says: "En septembre 2026, plus de 30 000 changements fusionnés par jour.", holds: true, value: 30000, unit: "par jour"}
	migration:                {says: "Scion remplace git pour le monorepo, migration complète en cinq mois.", holds: true}
	antique_en_meme_temps:    {says: "Antique, l'outil de revue, est construit dans la même période.", holds: true}
	historique:               {says: "L'historique de la branche principale pèse presque 100 Go.", holds: true, value: 100, unit: "Go"}
	checkouts_ci:             {says: "De l'ordre de 25 millions de checkouts par jour pour la CI seule.", holds: true, value: 25, unit: "millions par jour"}
	trafic_naif:              {says: "Sans astuce, ce serait plus de 600 Po de trafic git par jour.", holds: true, value: 600, unit: "Po par jour"}
	miroirs:                  {says: "Au pic, plusieurs centaines de miroirs git internes.", holds: true}
	clients_agents:           {says: "Presque tous les clients sont des agents et des tâches, en ligne par définition.", holds: true}
	travaux_anterieurs:       {says: "Scion reprend les leçons de Piper (Google) et Sapling (Meta).", holds: true}
	mononoke:                 {says: "Mononoke, le serveur de Sapling, a inventé beaucoup des techniques de Scion.", holds: true}
	toujours_en_ligne:        {says: "Le serveur est toujours joignable ; le client va chercher les données quand il en a besoin.", holds: true}
	serveur_calcule:          {says: "Le serveur calcule historique, blame, commits, fusions et rebases ; le client garde un cache borné.", holds: true}
	tout_en_api:              {says: "Chaque requête du client est aussi une API : beaucoup de tâches n'ont besoin d'aucune copie.", holds: true}
	cout_du_commit:           {says: "Le coût d'un commit suit la taille du changement, pas celle du dépôt.", holds: true}
	refs_decouragees:         {says: "Les refs sont découragées, sauf main et les branches de version : un état global ne passe pas à l'échelle.", holds: true}
	changeset:                {says: "Un changeset est une entrée d'un journal d'écriture anticipée.", holds: true}
	adressage_contenu:        {says: "Le contenu est adressé par son hash : une donnée stockée ne change jamais, tout serveur peut la cacher.", holds: true}
	sans_verrou:              {says: "Accepter un changeset ne demande ni verrou, ni coordination entre serveurs, ni ref à déplacer.", holds: true}
	ref_cas:                  {says: "Déplacer une ref est un compare-and-swap sur une seule ligne Spanner.", holds: true}
	donnees_derivees:         {says: "Chaque donnée dérivée se calcule à partir de ses valeurs pour les parents du changeset.", holds: true}
	cache:                    {says: "Chaque tier de cache a un taux de succès de plus de 99 %.", holds: true, value: 99, unit: "%"}
	empreinte:                {says: "L'infrastructure de Scion est 200 fois plus petite que les miroirs git, en CPU et en mémoire.", holds: true, value: 200, unit: "fois"}
	checkout_secondes:        {says: "Un checkout de CI prend des secondes au lieu de minutes.", holds: true}
	ci_cpu:                   {says: "La CI seule gagne 25 % de capacité CPU.", holds: true, value: 25, unit: "%"}
	ingestion_reecrite:       {says: "Réécrit par Claude, le pipeline d'ingestion consomme 20 fois moins de mémoire.", holds: true, value: 20, unit: "fois"}
	equipe:                   {says: "Une équipe de sept personnes a construit Scion et Antique.", holds: true, value: 7, unit: "personnes"}
	volume_x10:               {says: "Pendant ce temps, le volume de code fusionné par jour a été multiplié par 10.", holds: true, value: 10, unit: "fois"}
	revue_de_l_intention:     {says: "Les personnes relisent l'intention de chaque changement, pas chaque ligne.", holds: true}
	ingenieurs_disent_non:    {says: "Souvent, le rôle des ingénieurs est de dire non à Claude.", holds: true}
	figure_performances:      {says: "Une figure montre les gains de performance observés sur les dépôts natifs Scion.", holds: true}
	approbations_semantiques: {says: "Les règles d'approbation séparent un changement de commentaire d'un changement de logique sensible.", holds: true}
	pas_de_verrou_de_file:    {says: "Pas de verrou global sur la file de fusion : des tests après la fusion et avant le déploiement.", holds: true}
	conflits:                 {says: "Claude corrige les conflits plus vite qu'une personne ne les repère.", holds: true}
	pas_pour_tous:            {says: "Scion n'est pas un remplaçant de git pour un usage général.", holds: true}
	pas_de_version_publique:  {says: "Une version publique de Scion serait difficile à offrir et peu utile.", holds: true}
}

retired: {
	checkout_agent_7_1_min: {
		was:     "Une copie de travail pour un agent passe de 7,1 min à 5,1 s."
		why:     "Absent du texte de l'article. Seule la légende d'une figure parle de performances, et une image n'est pas capturée."
		against: "3ba5fcf6cdf1ab1bc78aeb00278d792819b87c7e1860aeb0e6f6351c0716dcbe"
	}
	gestion_de_source_34_min: {
		was:     "Le temps de gestion de source par changement passe de 34 min à 3,7 min."
		why:     "Absent du texte de l'article. Seule la légende d'une figure parle de performances, et une image n'est pas capturée."
		against: "3ba5fcf6cdf1ab1bc78aeb00278d792819b87c7e1860aeb0e6f6351c0716dcbe"
	}
}
