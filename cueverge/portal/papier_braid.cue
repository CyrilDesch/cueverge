package portal

// @what: a research note on Braid as the state of the factory, with a sealing step driven by tests.
// @what: a design, not a result. Its section 7 lists what to measure.
papierBraid: {
	slug:        "braid-pour-l-usine"
	title:       "Braid comme état de l'usine : sceller par le test"
	description: "Note de conception du 2026-11-12. Deux zones suffisent : « à tester » est une vue de la zone ouverte, « déployé » un repère sur la zone scellée."
	footer:      "Sources : le code et les tests du module Braid. Aucune mesure de cette note n'a encore été faite."
	blocks: [
		{hint: {style: "info", md: #"""
			**Résumé.** L'usine doit intégrer vite, tester en continu et ne jamais perdre une contrainte.
			Nous proposons de porter son état avec Braid, sans le modifier : un bloc est un lot de changements, la zone ouverte porte les candidats et la chaîne à l'essai, la zone scellée porte le tronc acquis.
			Le scellement est un fait publié par le juge quand le test continu a tenu, selon une règle écrite avant.
			Résultat principal : **trois états, mais deux zones**. « À tester » est une vue de la zone ouverte. « Déployé » est une hauteur dans la zone scellée.
			"""#}},
		{hint: {style: "warning", md: "**Statut.** Conception par raisonnement sur le code de Braid. Rien n'a tourné. La section 7 donne six prédictions, chacune avec sa mesure et son verdict."}},

		{group: {title: "1. Problème", blocks: [{md: #"""
			Le premier exemple, cue-interpreter, a montré deux manques.

			- **Sans isolation, on ne sait pas qui casse.** Une passe de corrections groupées a introduit 8 régressions, sans attribution possible.
			- **Sans test continu, on ne voit pas les interactions.** Deux changements verts séparément peuvent être rouges ensemble.

			Il faut donc deux étages : un test isolé par changement, et un test continu sur l'ensemble.
			Il reste à dire où vit l'état entre les deux : quels changements sont proposés, lesquels sont à l'essai ensemble, lesquels sont acquis.
			Cet état doit rester le même quel que soit l'ordre d'arrivée des rapports, sinon l'orchestration n'est pas reproductible.
			"""#}]}},

		{
			group: {title: "2. Braid en bref", blocks: [
				{md: "Braid est une structure à deux zones de blocs. Un bloc a une clé, un parent, une hauteur et une valeur. `Settle` est la seule étape qui déplace un bloc."},
				{
					table: {
						columns: ["Règle", "Énoncé", "Source"]
						rows: [
							["Une place par hauteur", "La zone scellée tient au plus un bloc par hauteur.", "Invariant du module"],
							["Sceller descend", "Un bloc scellé scelle ses parents ouverts.", "Étape `Settle`"],
							["Perdre sans trace", "Un bloc ouvert à une hauteur scellée, autre que le bloc scellé, quitte la zone.", "Étape `Settle`"],
							["L'enfant attend", "L'enfant d'un bloc perdu reste, jusqu'à ce que sa propre hauteur soit scellée.", "Étape `Settle`, invariant"],
							["Le manque est un niveau", "`gaps` donne les parents absents au-dessus du sommet scellé. Une demande perdue revient.", "Fonction `gaps`"],
							["La jointure est un treillis", "`join` est associative, commutative et idempotente.", "Tests du module, états aléatoires"],
							["La structure ignore les valeurs", "`Settle` et `gaps` lisent les clés, les parents et les hauteurs. Jamais une valeur.", "Interface `Merge` du module"],
						]
					}
				},
				{md: "La dernière règle compte ici : Braid ne décide pas de sceller. Il reçoit un bloc scellé et en tire les conséquences."},
			]}
		},

		{
			group: {title: "3. Correspondance", blocks: [
				{
					table: {
						columns: ["Braid", "Usine"]
						rows: [
							["Bloc", "Un **lot** : un ensemble de changements. Un candidat isolé est un lot d'un seul changement."],
							["Parent", "Le lot sur lequel celui-ci a été construit."],
							["Hauteur", "Le rang du lot dans le tronc."],
							["Valeur ouverte", "Le contenu du lot, son propriétaire, et les verdicts reçus."],
							["`Merge` de la valeur ouverte", "L'union des verdicts. Deux testeurs sur le même lot ne se gênent pas."],
							["Valeur scellée, par `Absorb`", "Le contenu et la preuve retenue. Les observations brutes restent dans le journal."],
							["Zone ouverte", "Tous les lots proposés, dont la chaîne à l'essai."],
							["Zone scellée", "Le tronc acquis."],
							["`gaps`", "Les parents qu'un lot nomme et que l'état n'a pas : le travail à demander."],
							["`freeze`", "L'oubli de l'histoire ancienne du tronc."],
						]
					}
				},
				{md: #"""
					```mermaid
					flowchart LR
					  subgraph scellee["Zone scellée : tronc acquis"]
					    lot41["lot 41"] --> lot42["lot 42"]
					  end
					  subgraph ouverte["Zone ouverte"]
					    lot43["lot 43 : a + b + c"] --> lot44["lot 44 : d"]
					    seulA["43 : a seul"]
					    seulE["43 : e seul, rouge"]
					  end
					  lot42 --> lot43
					  lot42 --> seulA
					  lot42 --> seulE
					  deploye(["repère « déployé »"]) -.-> lot41
					  essai(["tête à l'essai"]) -.-> lot44
					```

					Les lots 43 et 44 forment la chaîne à l'essai. Si le juge scelle 44, la règle « sceller descend » scelle 43, et les lots « a seul » et « e seul » sont perdus : leur hauteur est prise.
					Le changement `a` vit dans le lot scellé. Le changement `e` doit être corrigé et reproposé à la hauteur 45.
					"""#},
			]}
		},

		{
			group: {title: "4. Deux zones ou trois ?", blocks: [
				{md: #"""
					La proposition de départ a trois zones : **Ouvert**, **À tester**, **Déployé**. Les trois états sont justes. La question est de savoir si chacun demande une zone.

					Une zone de Braid se définit par ce qu'un bloc peut y subir.

					- **Zone ouverte.** Plusieurs blocs par hauteur. Un bloc peut être perdu.
					- **Zone scellée.** Un bloc par hauteur. Un bloc n'en sort jamais.

					« À tester » doit choisir entre les deux, selon ce qui arrive à un lot qui échoue.
					"""#},
				{
					table: {
						columns: ["Si un lot à l'essai échoue", "Alors « À tester » est", "Et « Déployé » est"]
						rows: [
							["On le retire", "Dans la zone ouverte : c'est une chaîne choisie parmi les lots ouverts, donc une **vue**.", "La zone scellée."],
							["On ne retire jamais, on corrige par-dessus", "Dans la zone scellée, puisque rien n'en sort.", "Une chaîne sans fourche au-dessus d'une chaîne sans fourche : un simple **repère de hauteur**."],
						]
					}
				},
				{md: #"""
					Dans les deux cas, la troisième zone se réduit à autre chose : une vue, ou un entier. Une vraie troisième zone demanderait un bloc qui n'est ni perdable ni définitif, et nous n'en avons pas trouvé.

					**Proposition.** Nous prenons la première ligne, et nous gardons le repère de la seconde.

					| État | Où il vit | Qui le fixe |
					|---|---|---|
					| Ouvert | Zone ouverte | Chaque agent, en publiant son lot |
					| À tester | Zone ouverte, la chaîne choisie | La table d'orchestration, fonction pure de l'état |
					| Acquis | Zone scellée | Le juge, par un fait de scellement |
					| Déployé | Une hauteur dans la zone scellée | La cadence de déploiement, ou un humain |

					C'est la forme d'Ethereum, pour laquelle Braid a été écrit : la tête de chaîne est un choix parmi les blocs ouverts, la finalité vient après. C'est aussi celle des phases de Mercurial : un changement « draft » se réécrit, un changement « public » ne bouge plus.

					Le retrait devient gratuit. Un lot rouge n'est jamais scellé, un autre lot prend sa hauteur, et la règle « perdre sans trace » fait le ménage.
					"""#},
			]}
		},

		{
			group: {title: "5. Le scellement", blocks: [
				{md: "Le scellement est le seul point de synchronisation. Tout le reste est publication de faits, dans n'importe quel ordre."},
				{
					steps: [
						{title: "Un agent publie un lot", blocks: [{md: "Il travaille dans une copie isolée, sur la tête courante. Son lot nomme cette tête comme parent. Les verdicts du test isolé partent avec le lot."}]},
						{title: "La table choisit la chaîne à l'essai", blocks: [{md: "Règle déterministe sur l'état : à la hauteur suivante, elle forme un lot avec tous les candidats dont le test isolé est vert. Ce lot est un bloc comme un autre."}]},
						{title: "Le test continu tourne sur la tête", blocks: [{md: "Chaque tour publie ses verdicts. Ils s'ajoutent à la valeur du lot par union. Les agents construisent déjà sur cette tête : ils n'attendent pas."}]},
						{title: "Le juge scelle", blocks: [{md: "Quand la règle de scellement est tenue, le juge publie le fait « lot k scellé ». Braid scelle les parents ouverts de k et retire les lots concurrents."}]},
						{title: "Le repère de déploiement suit", blocks: [{md: "Il monte dans la zone scellée à sa propre cadence. Les exercices planifiés, comme la reprise sur deux centres, se jouent entre le sommet scellé et ce repère."}]},
					]
				},
				{md: #"""
					**La règle de scellement est un point fixe.** Elle est écrite avant le tour, et un agent ne peut que la durcir. Forme proposée : *un lot est scellé après N tours complets consécutifs sans verdict d'échec, avec toutes les contraintes de cadence « continue » mesurées.*

					**On teste le sommet, on scelle la chaîne.** Sceller le lot 44 scelle le lot 43. On ne vérifie donc pas chaque lot intermédiaire : c'est la simplification recherchée, obtenue par la structure.

					**Le délai N règle un compromis.** Court, un défaut lent passe dans le tronc acquis. Long, plus de travail se construit sur une tête qui peut tomber.
					"""#},
			]}
		},

		{
			group: {title: "6. Quand ça casse", blocks: [
				{
					table: {
						columns: ["Cas", "Ce qui se passe", "Coût"]
						rows: [
							["La tête à l'essai passe au rouge", "La table publie deux demi-lots à la même hauteur. Le premier qui tient est prolongé puis scellé, l'autre est perdu ou recoupé.", "Un tour par coupe."],
							["Du travail reposait sur la tête rouge", "Ses lots attendent, puis sont perdus quand leur hauteur est scellée. Leurs changements sont reproposés sur la nouvelle tête.", "Le taux d'orphelins."],
							["Un défaut apparaît dans le tronc acquis", "Rien ne sort de la zone scellée. On corrige par un nouveau lot. Si une fonction est abandonnée, le lot porte une pierre tombale avec sa contrainte.", "Un lot de plus."],
							["Deux agents font le même travail", "Deux lots à la même hauteur : un seul est scellé. Les baux limitent le cas, Braid le rend sans danger.", "Le travail du perdant."],
							["L'orchestrateur tombe", "On rejoue le journal des faits. L'ordre ne compte pas.", "Le temps du rejeu."],
						]
					}
				},
			]}
		},

		{
			group: {title: "7. Ce qu'il faut mesurer", blocks: [
				{md: "Chaque ligne est une prédiction du modèle. Une seule mesure contraire la réfute."},
				{
					table: {
						columns: ["Prédiction", "Mesure", "Verdict"]
						rows: [
							["L'ordre ne compte pas", "Rejouer le journal d'une session dans 100 ordres aléatoires.", "Un état final ou une décision de la table qui diffère : réfuté."],
							["Le doublon ne coûte rien", "Rejouer le journal avec chaque fait en double.", "Un état différent : réfuté."],
							["La reprise est un rejeu", "Tuer l'orchestrateur en cours de session, rejouer.", "Un état différent de la session sans panne : réfuté."],
							["L'attribution est logarithmique", "Lot rouge de N changements avec un seul fautif : compter les tours.", "Plus de ⌈log₂ N⌉ tours : réfuté."],
							["Les orphelins restent rares", "Part des lots construits sur une tête ensuite perdue.", "Au-dessus de 20 % : sceller plus tôt, ou construire sur le tronc acquis seulement."],
							["Deux zones suffisent", "Tenir la liste des états rencontrés sur un projet.", "Un état qui n'est ni une vue ni un repère : il faut une troisième zone."],
						]
					}
				},
				{md: "Les trois premières se testent sans agent, sur un journal enregistré. C'est par là qu'il faut commencer : [porter l'état de l'orchestrateur avec Braid](\(_href.action.etat_en_braid))."},
			]}
		},

		{group: {title: "8. Limites", blocks: [{hint: {style: "warning", md: #"""
			- **Un seul parent par bloc.** Braid est une forêt. Combiner se fait donc par un lot à la même hauteur, et non par un nœud de fusion. Les candidats repris dans un lot sont « perdus » comme blocs alors que leur contenu est acquis : le journal doit garder ce lien.
			- **Le scellement vient du dehors.** Braid applique la décision, il ne la prend pas. Toute la sûreté repose sur la règle du juge et sur la stabilité des verdicts.
			- **Un verdict instable bloque tout.** Sur cue-interpreter, le verdict de temps basculait avec la charge. Avec la règle des N tours, un tel verdict empêche de sceller. La stabilité des verdicts passe avant.
			- **Un travail long se rebase souvent.** La hauteur est le rang dans le tronc : chaque scellement oblige les lots concurrents à se reproposer.
			- **Plusieurs fautifs dans un lot.** La coupe en deux n'est logarithmique que pour un seul fautif, sans interaction entre changements.
			- **Un seul langage, depuis la réécriture du noyau.** Braid et le noyau sont en Scala : le noyau peut utiliser Braid directement. Le code des lots vit dans jj, et Braid porte leurs clés, parents, hauteurs et verdicts.
			"""#}}]}},

		{
			group: {title: "9. Travaux proches", blocks: [{
				table: {
					columns: ["Système", "Ce qu'il partage", "Ce qui diffère ici"]
					rows: [
						["Ethereum, tête et finalité", "Tête choisie parmi les blocs ouverts, finalité irréversible.", "La finalité vient d'un juge de tests, pas d'un vote."],
						["Mercurial et jj, phases", "« draft » se réécrit, « public » ne bouge plus.", "Le passage de phase est gardé par une règle mesurée."],
						["File de fusion (bors)", "Tester le lot, couper en deux s'il casse.", "Les agents construisent sur la tête sans attendre le verdict."],
						["Spawn", "Pas de revue par changement, test fréquent du tronc.", "Un étage isolé pour attribuer, et un tronc acquis qui ne recule pas."],
					]
				}
			}]}
		},
	]
}
