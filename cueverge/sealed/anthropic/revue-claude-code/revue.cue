// @what: what the Claude Code team article on code review states. Every fact is attributed to its authors.
// @ref: @/cueverge/cogen/gen-sealed/anthropic/revue-claude-code/revue.cue
// @ref: @/cueverge/gen/web/claude-code-review/page.gen.cue
package revue

import "github.com/cyrildesch/cueverge/schema"

schema.#Sealed

_selon: "Équipe Claude Code, « How the Claude Code team does code review »"
facts: [string]: selon: _selon

facts: {
	claude_ecrit:         {says: "Claude écrit environ 90 % du code de Claude Code.", holds: true, value: 90, unit: "%"}
	reverts:              {says: "De juin à septembre, la part des PR annulées a baissé de plus de 40 %.", holds: true, value: 40, unit: "%"}
	prs_doublees:         {says: "Sur la même période, les PR fusionnées ont plus que doublé.", holds: true}
	nomme_antique:        {says: "L'article nomme Antique.", holds: false}
	un_humain_au_plus:    {says: "Le but : la plupart des PR fusionnent avec au plus une personne dans la boucle.", holds: true}
	garde_fou:            {says: "Les taux d'annulation et d'incident sont le garde-fou du temps humain gagné.", holds: true}
	montrer_la_sortie:    {says: "Claude doit montrer la sortie de sa vérification, pas dire que c'est fait.", holds: true}
	corriger_a_la_source: {says: "Un constat répété se corrige à la source : skill, règle de lint, CLAUDE.md.", holds: true}
	commentaires_avant:   {says: "Avant la revue par IA, 16 % des PR internes recevaient un commentaire de fond.", holds: true, value: 16, unit: "%"}
	commentaires_apres:   {says: "Avec la revue par IA, cette part passe à 54 %.", holds: true, value: 54, unit: "%"}
	vote_des_agents:      {says: "Plusieurs agents cherchent des bugs, puis un autre groupe vote sur chaque constat.", holds: true}
	chaque_constat:       {says: "Chaque constat reçoit une réponse : corrigé, ou fermé avec une raison.", holds: true}
	securite_bloque:      {says: "Une PR ne fusionne pas tant qu'un constat de bug ou de sécurité reste ouvert.", holds: true}
	risque_bas:           {says: "Risque bas : aucune approbation humaine une fois les contrôles automatiques verts.", holds: true}
	risque_moyen:         {says: "Risque moyen : une personne approuve.", holds: true}
	risque_haut:          {says: "Risque haut : deux personnes approuvent.", holds: true}
	classifieur:          {says: "Le changement fixe le niveau de risque, pas son auteur : un classifieur le lit.", holds: true}
	agent_ne_compte_pas:  {says: "L'approbation d'un agent ne compte jamais comme celle d'une personne.", holds: true}
	qui_demande_repond:   {says: "La personne qui dirige l'agent compte comme un des relecteurs requis.", holds: true}
	un_commit:            {says: "Une approbation couvre un commit précis.", holds: true}
	file_de_fusion:       {says: "La file de fusion rejoue chaque contrôle sur main avec le changement appliqué.", holds: true}
	pas_de_disjoncteur:   {says: "Pas encore de disjoncteur qui durcit l'approbation quand les annulations montent.", holds: true}
	incidents_en_eval:    {says: "Chaque incident passé devient un cas de l'évaluation du relecteur.", holds: true}
	bruit_agent:          {says: "Le bruit coûte plus cher quand l'auteur est un agent : il corrige chaque détail.", holds: true}
	cinquante_tours:      {says: "Une PR a fait plus de 50 tours de revue et de correction en une nuit.", holds: true, value: 50, unit: "tours"}
	vieux_code:           {says: "Environ 59 % de ce que le relecteur signalait encore existait dès son premier passage.", holds: true, value: 59, unit: "%"}
	plafond_de_tours:     {says: "Après 3 tours, le relecteur demande à l'auteur de revoir son approche.", holds: true, value: 3, unit: "tours"}
	pas_de_repetition:    {says: "Le relecteur ne répète pas un constat déjà posté.", holds: true}
}

retired: {}
