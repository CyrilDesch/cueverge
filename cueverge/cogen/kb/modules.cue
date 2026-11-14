// @what: the layout rule of the tool, judged on the inventory of this base.
// @ref: @/cueverge/inventory.cue
// @ref: @/tool/cue/layout/layout.cue
package kb

import (
	"github.com/cyrildesch/cueverge/layout"

	inv "factory.local/kb:inventory"
)

(layout.#Layout & {files: inv.files})...
