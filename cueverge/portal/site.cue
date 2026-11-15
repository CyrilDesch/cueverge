// @what: the site of the knowledge base. polaris site unifies this value with site.#Site of the Polaris module.
// @why: no import of the Polaris site package, which is not published yet. `polaris site build` checks the shape instead.
// @ref: @/cueverge/polaris.yaml
package portal

import (
	p "github.com/cyrildesch/cueverge/portal"
	"factory.local/kb/sealed/project/problem"
	"factory.local/kb/sealed/project/objectives"
	"factory.local/kb/sealed/project/constraints"
)

// @what: the problem, the objectives and the constraints of the factory, each with the state its rule computes.
projectPage: (p.#ProjectPage & {#problem: problem, #objectives: objectives, #constraints: constraints}).out

site: {
	title:     "Software factory: state of the thinking"
	overrides: "theme"
	// @what: the first page of the sidebar is the landing page, the one "/" opens.
	groups: [
		{title: "Summary", pages: [homePage, projectPage]},
		{title: "Understand", pages: [featurePage]},
		{title: "Next", pages: [actionsPage, questionsPage]},
		{title: "Evidence", pages: [experimentsPage]},
		{title: "Foundations", pages: [principlesPage, decisionsPage, constraintsPage, factoryPage]},
		{title: "Notes", pages: [braidPaper, scionStudy]},
	]
}
