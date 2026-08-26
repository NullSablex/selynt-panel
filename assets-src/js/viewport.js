// Altura disponível para o painel.
//
// O painel é servido dentro de um iframe do DirectAdmin, então `100vh` mede a
// janela toda e não o espaço que sobrou. Esta medida vira a variável CSS que o
// layout usa.

import { getRoot } from './dom.min.js';

export function setAvailableHeight() {
  try {
    const root = getRoot();
    if (!root) return;
    const rect = root.getBoundingClientRect();
    const available = Math.max(320, (window.innerHeight || 0) - (rect.top || 0));
    root.style.setProperty('--selynt-available-height', available + 'px');
  } catch (e) {}
}

// A medida vale no primeiro paint e a cada mudança de janela; sem o listener
// o painel encolhe ou sobra quando o usuário redimensiona.
function init() {
  setAvailableHeight();
  window.addEventListener('resize', setAvailableHeight);
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
