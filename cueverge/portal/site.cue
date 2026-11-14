// @what: the site of the knowledge base. polaris site unifies this value with site.#Site of the Polaris module.
// @why: no import of the Polaris site package, which is not published yet. `polaris site build` checks the shape instead.
// @ref: @/cueverge/polaris.yaml
package portal

site: {
	title:     "Usine logicielle : état de la réflexion"
	overrides: "theme"
	// @what: the first page of the sidebar is the landing page, the one "/" opens.
	groups: [
		{title: "Bilan", pages: [accueil]},
		{title: "Comprendre", pages: [featurePage]},
		{title: "Suite", pages: [actionsPage, questionsPage]},
		{title: "Preuves", pages: [experiencesPage]},
		{title: "Cadre", pages: [principesPage, decisionsPage, contraintesPage, usinePage]},
		{title: "Notes", pages: [papierBraid, etudeScion]},
	]
}
