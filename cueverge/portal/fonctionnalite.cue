package portal

import (
	"factory.local/kb/sealed/usine/actions"
)

// @what: Whether a step works today, read from the action that builds it.
#Today: {
	#action: string
	out: [
		if actions.actions[#action].status == "fait" {"**Aujourd'hui : en place**"},
		"**Aujourd'hui : pas encore.** C'est l'action « \(actions.actions[#action].title) »",
	][0]
}

// @what: A typical feature, step by step, in plain words.
featurePage: {
	slug:        "nouvelle-fonctionnalite"
	title:       "Une nouvelle fonctionnalité, étape par étape"
	description: "Ce qui se passe quand on demande une fonctionnalité à l'usine. L'exemple : laisser l'agent du premier projet lire les fichiers du dépôt sans pouvoir les écrire."
	footer:      "Chaque étape dit si elle marche aujourd'hui. Cette mention vient de l'état des actions, pas d'un texte écrit à la main."
	blocks: [
		{hint: {style: "info", md: #"""
			**En bref.** Une personne dit ce qu'elle veut et comment le vérifier. Un agent écrit le code. Un juge compare le résultat à une référence et à la version d'avant. L'agent dit ce qu'il a voulu faire, et une personne approuve ces quelques lignes, pas le code. Si rien ne casse et que le changement fait ce qu'il annonce, il est gardé. Sinon, il est refusé. Tout est noté.
			"""#}},

		{
			steps: [
				{title: "1. Une personne écrit la demande", blocks: [{md: #"""
					Elle dit ce qu'elle veut : « l'agent peut lire les fichiers du dépôt, jamais les écrire ».
					Elle ajoute des exemples : une entrée, et le résultat attendu.
					Ces exemples deviennent la mesure. La demande est faite quand ils passent.
					"""#}]},

				{title: "2. Elle fixe les limites", blocks: [{md: #"""
					Ce qui marche déjà doit continuer à marcher.
					Chaque réponse doit arriver dans le budget de temps que fixe l'initiative.
					Ces limites sont écrites avant le travail. Elles sont vérifiées par la machine, pas par une relecture.
					"""#}]},

				{title: "3. On vérifie que la demande ne relâche rien", blocks: [{md: #"""
					Ajouter des exemples rend l'exigence plus stricte : c'est permis.
					Assouplir une limite existante demande l'accord d'une personne.
					\#((#Today & {#action: "verrouiller_les_points_fixes"}).out).
					"""#}]},

				{title: "4. Un agent reçoit une tâche courte", blocks: [{md: #"""
					Il ne reçoit pas « fais au mieux ». Il reçoit une tâche précise : faire passer ces exemples.
					La tâche est choisie par une règle écrite, pas par l'agent.
					\#((#Today & {#action: "table_d_orchestration"}).out).
					"""#}]},

				{title: "5. L'agent travaille dans sa propre copie", blocks: [{md: #"""
					Il ne touche pas à la version partagée.
					Dans sa copie, il essaie autant qu'il veut et lance le vrai contrôle. Il voit tout de suite s'il casse quelque chose.
					\#((#Today & {#action: "etat_en_braid"}).out).
					"""#}]},

				{title: "6. Le juge compare", blocks: [{md: #"""
					Chaque exemple passe dans le nouveau code et dans la référence. Les deux réponses sont comparées.
					Le juge compare aussi avec la version d'avant : un exemple qui passait doit encore passer.
					Il vérifie enfin l'intention de l'agent : ce qu'il dit réparer est réparé, et ce qu'il casse est annoncé.
					\#((#Today & {#action: "juge_en_cue"}).out).
					"""#}]},

				{title: "7. Rien ne casse : le changement est gardé", blocks: [{md: #"""
					Il devient la nouvelle référence. Les changements suivants seront comparés à lui.
					Une fois gardé, il ne recule plus. Une erreur se corrige par un nouveau changement.
					"""#}]},

				{title: "8. Quelque chose casse : le changement est refusé", blocks: [{md: #"""
					La version partagée ne bouge pas.
					Le refus est noté avec sa raison : l'exemple cassé, et la réponse obtenue.
					Un changement déjà refusé ne doit pas revenir tel quel. \#((#Today & {#action: "etat_en_braid"}).out).
					"""#}]},

				{title: "9. Un cas douteux remonte à une personne", blocks: [{md: #"""
					Parfois un exemple « passait » par chance : la bonne erreur, pour une mauvaise raison.
					Le bon correctif le casse. La machine ne tranche pas seule : l'agent annonce la régression dans son intention, avec sa raison.
					Une personne lit ces quelques lignes et approuve. Sans son accord, rien n'est gardé.
					\#((#Today & {#action: "intention_relue"}).out).
					"""#}]},

				{title: "10. Tout est noté, et la base se met à jour", blocks: [{md: #"""
					Pour chaque essai : ce qui a été demandé, ce que l'agent a fait, ce que ça a coûté, la décision.
					Les chiffres des mesures récentes sont calculés à partir de ces traces. Personne ne les recopie.
					Un texte qui parle de ce qui vient de changer est signalé. Il doit être relu avant la publication suivante.
					"""#}]},
			]
		},

		{
			group: {title: "Qui fait quoi", blocks: [{
				table: {
					columns: ["Qui", "Rôle"]
					rows: [
						["Une personne", "Dit ce qu'elle veut, comment le vérifier, et ce qui ne doit jamais casser. Approuve les intentions des agents et tranche les cas douteux."],
						["Un agent", "Écrit le code, dans sa copie, sur une tâche précise."],
						["Le juge", "Compare, et garde ou refuse. Il ne devine pas : il applique des règles écrites avant."],
						["La base", "Note tout. Calcule ses chiffres à partir des traces. Signale ce qui n'est plus vrai."],
					]
				}
			}]}
		},
	]
}
