// @what: the site of the knowledge base. polaris site unifies this value with site.#Site of the Polaris module.
// @why: no import of the Polaris site package, which is not published yet. `polaris site build` checks the shape instead.
// @ref: @/cueverge/polaris.yaml
package portal

site: {
	title:     "Software factory: state of the thinking"
	overrides: "theme"
	// @what: the first page of the sidebar is the landing page, the one "/" opens.
	groups: [
		{title: "Summary", pages: [homePage]},
		{title: "Understand", pages: [featurePage]},
		{title: "Next", pages: [actionsPage, questionsPage]},
		{title: "Evidence", pages: [experimentsPage]},
		{title: "Frame", pages: [principlesPage, decisionsPage, constraintsPage, factoryPage]},
		{title: "Notes", pages: [braidPaper, scionStudy]},
	]
}
