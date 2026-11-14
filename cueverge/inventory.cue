@extern(embed)

// @what: the inventory of the base, read by CUE itself. The cue files of each module, embedded as text.
// @why: CUE cannot list folders. Fixed-depth globs reach every package, since the module layout fixes the depths.
// @why: allowEmptyGlob, so that a project with no fact yet vets.
// @ref: @/cueverge/cogen/kb/modules.cue
package inventory

import "strings"

_sealed2: _ @embed(glob=sealed/*/*.cue, type=text, allowEmptyGlob)
_sealed3: _ @embed(glob=sealed/*/*/*.cue, type=text, allowEmptyGlob)
_rules4:  _ @embed(glob=cogen/gen-sealed/*/*/*.cue, type=text, allowEmptyGlob)
_gen3:    _ @embed(glob=gen/*/*/*.cue, type=text, allowEmptyGlob)

// @what: every cue file of the modules, outside the generated quote folders.
files: {
	for f, _ in _sealed2 if !strings.Contains(f, "/_meta/") {(f): true}
	for f, _ in _sealed3 if !strings.Contains(f, "/_meta/") {(f): true}
	for f, _ in _rules4 if !strings.Contains(f, "/_meta/") {(f): true}
	for f, _ in _gen3 if !strings.Contains(f, "/_meta/") {(f): true}
}
