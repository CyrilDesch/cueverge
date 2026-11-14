// @what: the theme labels in French, since the base is in French. Loaded after docs.js on every page (site.overrides).
// @why: the main "Copy" button is left alone. docs.js writes "Copy" back into it after each click.
(() => {
  document.documentElement.lang = 'fr';
  // @why: docs.js adds a "Copy" button to every <pre>, also to a Mermaid one, and Mermaid then reads the button as source and fails.
  // @what: so the button goes before Mermaid loads. Its import is asynchronous, so this runs first.
  document.querySelectorAll('pre.mermaid .pd-copy').forEach((b) => b.remove());
  const set = (sel, text) => document.querySelectorAll(sel).forEach((el) => (el.textContent = text));
  set('.pd-search-btn > span:nth-child(2)', 'Rechercher…');
  set('.pd-toc-title', 'Sur cette page');
  set('.pd-prev > span', 'Précédent');
  set('.pd-next > span', 'Suivant');
  set('.pd-filter option[value=""]', 'Tous');
  set('.pd-menu-item[data-pd-copy-page] strong', 'Copier la page');
  set('.pd-menu-item[data-pd-copy-page] small', 'Copier la page en Markdown, pour un LLM');
  set('.pd-menu-item[data-pd-view-md] small', 'Voir la page en texte brut');
  const md = document.querySelector('.pd-menu-item[data-pd-view-md] strong');
  if (md && md.firstChild) md.firstChild.textContent = 'Voir en Markdown ';
  const input = document.querySelector('[data-pd-search-input]');
  if (input) input.placeholder = 'Rechercher dans le site…';
  const hint = document.querySelector('.pd-search-hint');
  if (hint) hint.innerHTML = '<kbd>↑</kbd> <kbd>↓</kbd> pour choisir, <kbd>Entrée</kbd> pour ouvrir, <kbd>Échap</kbd> pour fermer';
})();
