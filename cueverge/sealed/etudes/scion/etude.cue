// @what: what we conclude from the Scion and review articles. Each conclusion names the facts it rests on, ours and theirs.
// @invariant: a conclusion is ours. It is anchored by the facts it rests on, never proven by them.
// @ref: @/cueverge/cogen/gen-sealed/etudes/scion/etude.cue
package etude

import "github.com/cyrildesch/cueverge/schema"

schema.#Sealed

facts: [string]: {
	rests: [_, ...]
	role:  _
	// @invariant: only a proposition may wait on a fact of ours not tested yet. Every other conclusion holds.
	if role != "proposition" {holds: true}
}

facts: {
	etat_global:     {role: "parallèle", holds: true, says: "Un état global partagé ne passe pas à l'échelle : chez nous, un seul décideur à la fois.", rests: ["scion.refs_decouragees", "system.un_seul_decideur"]}
	ci_qui_bouge:    {role: "parallèle", holds: true, says: "Quand tout fusionne pendant les tests, le juge doit aller plus vite que les agents.", rests: ["scion.pas_de_verrou_de_file", "system.cadence_du_juge"]}
	sans_verrou:     {role: "parallèle", holds: true, says: "Accepter un changement sans verrou : un changement qui perd sa place est rejoué, pas jeté.", rests: ["scion.sans_verrou", "system.rejouer_pas_jeter"]}
	copie_en_retard: {role: "parallèle", holds: true, says: "Une copie reste derrière la tête : l'agent lance le vrai juge dans sa copie avant de proposer.", rests: ["scion.miroirs", "system.tester_avant_de_proposer"]}
	historique:      {role: "parallèle", holds: true, says: "Questionner l'historique sans copie : savoir vite si un effet a déjà été refusé.", rests: ["scion.tout_en_api", "system.jamais_le_meme_mur"]}
	cout:            {role: "parallèle", holds: true, says: "Le coût suit la taille du changement, pas du dépôt : chez nous, le coût perdu reste sous un plafond.", rests: ["scion.cout_du_commit", "system.cout_perdu"]}
	conflits:        {role: "parallèle", holds: true, says: "Un conflit se corrige en avant, sans refaire toute la génération.", rests: ["scion.conflits", "system.rejouer_pas_jeter"]}

	niveau_de_risque:    {role: "proposition", holds: "inconnu", says: "Le niveau de risque, lu sur le changement, fixe le nombre de personnes qui approuvent.", rests: ["revue.classifieur", "revue.risque_bas", "revue.risque_haut", "scion.approbations_semantiques", "principles.intention_relue"]}
	relire_l_intention:  {role: "proposition", holds: "inconnu", says: "Les personnes relisent l'intention, pas chaque ligne.", rests: ["scion.revue_de_l_intention", "principles.intention_relue"]}
	approuver_un_commit: {role: "leçon", holds: true, says: "Une approbation doit couvrir un commit précis, pas seulement le texte de l'intention.", rests: ["revue.un_commit", "revue.agent_ne_compte_pas"]}
	repondre_au_refus:   {role: "leçon", holds: true, says: "Chaque refus reçoit une réponse de l'agent : corrigé, ou abandonné avec une raison.", rests: ["revue.chaque_constat", "system.jamais_le_meme_mur"]}
	plafonner_les_tours: {role: "leçon", holds: true, says: "Plafonner les tours : au-delà, l'agent revoit son approche au lieu de recommencer.", rests: ["revue.plafond_de_tours", "revue.vieux_code", "system.jamais_le_meme_mur"]}
	incidents_en_tests:  {role: "proposition", holds: "inconnu", says: "Chaque intention fausse ou vide devient un cas de test des règles d'intention.", rests: ["revue.incidents_en_eval", "principles.intention_relue"]}

	pas_de_serveur_de_code:    {role: "refus", holds: true, says: "Pas de serveur central pour le code : jj et git suffisent à notre échelle.", rests: ["scion.serveur_calcule", "scion.pas_pour_tous"]}
	pas_de_vote:               {role: "proposition", holds: "inconnu", says: "Pas de juge fait d'agents qui votent : le verdict reste à cue vet.", rests: ["revue.vote_des_agents", "principles.contrainte_executee"]}
	pas_de_chiffres_en_preuve: {role: "refus", holds: true, says: "Les chiffres d'Anthropic donnent un ordre de grandeur, pas une preuve pour nous.", rests: ["scion.fusions_septembre", "scion.empreinte"]}

	serveur_de_pointeurs: {role: "proposition", holds: "inconnu", says: "Un serveur d'orchestration porte le journal, l'état et les baux, avec des pointeurs vers jj, jamais du code.", rests: ["scion.serveur_calcule", "scion.adressage_contenu", "actions.table_d_orchestration"]}
	sceller_par_cas:      {role: "proposition", holds: "inconnu", says: "Sceller est un compare-and-swap sur le sommet scellé : notre seul point de synchronisation.", rests: ["scion.ref_cas", "principles.synchronisation_au_scellement"]}
	vues_derivees:        {role: "proposition", holds: true, says: "Les murs connus et le coût perdu se calculent comme des données dérivées du journal.", rests: ["scion.donnees_derivees", "system.jamais_le_meme_mur", "system.cout_perdu"]}
}

retired: {}
