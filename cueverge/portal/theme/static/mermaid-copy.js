// @what: removes the "Copy" button that docs.js adds to a Mermaid block. Loaded after docs.js on every page (site.overrides).
// @why: Mermaid reads the button as source and fails. Its import is asynchronous, so this runs first.
(() => {
  document.querySelectorAll('pre.mermaid .pd-copy').forEach((b) => b.remove());
})();
