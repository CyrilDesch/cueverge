// @what: the layout of a project module, judged on the inventory CUE reads from its files.
// @invariant: there is no exception list. A sealed package without rules fails, whatever it holds.
// @what: a project wires its inventory (an @embed of its own files) to #Layout, in the kb package of its cogen module.
// @ref: @/cueverge/cogen/kb
package layout

import (
	"list"
	"path"
	"strings"
)

#Layout: {
	// @what: every cue file of the modules, outside the generated quote folders.
	files: [string]: true
	// @what: the folders that hold a package.
	packages: [for d, _ in {for f, _ in files {(path.Dir(f, path.Unix)): true}} {
		d...
	}]

	let Sealed = [for d in packages if strings.HasPrefix(d, "sealed/") {
		d...
	}]

	// @invariant: a sealed package has its rules at the same path under the gen-sealed cogen module.
	mirrored: {for d in Sealed {(d): list.Contains(packages, "cogen/gen-sealed/" + strings.TrimPrefix(d, "sealed/")) & true}}

	// @invariant: a rule package judges a sealed package that exists.
	orphans: {for d in packages if strings.HasPrefix(d, "cogen/gen-sealed/") {(d): list.Contains(packages, "sealed/" + strings.TrimPrefix(d, "cogen/gen-sealed/")) & true}}

	// @invariant: a cue file under gen is written by a mechanism. Its name says which, never a hand-written name.
	generatedOnly: {for f, _ in files if strings.HasPrefix(f, "gen/") {(f): (strings.HasSuffix(f, ".gen.cue") || strings.HasSuffix(f, ".export.cue")) & true}}
}
