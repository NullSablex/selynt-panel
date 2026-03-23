function getRoot() {
  return document.querySelector('.selynt-panel') || document.body;
}

function ensureToastContainer() {
  const root = getRoot();
  if (!root) return null;
  let el = document.getElementById('selynt-toast-container');
  if (el) return el;
  el = document.createElement('div');
  el.id = 'selynt-toast-container';
  el.className = 'selynt-toast-container';
  root.appendChild(el);
  return el;
}

export function toast(type, message, opts) {
  message = (message === undefined || message === null) ? '' : String(message);
  if (!message.trim()) return Promise.resolve();
  opts = opts || {};

  const container = ensureToastContainer();
  if (!container) return Promise.resolve();

  const t = document.createElement('div');
  t.className = 'selynt-toast selynt-toast-' + (type || 'info');
  t.setAttribute('role', 'status');
  t.innerHTML =
    '<div class="selynt-toast-body"></div>' +
    '<button type="button" class="selynt-toast-close" aria-label="Fechar">×</button>';

  t.querySelector('.selynt-toast-body').textContent = message;
  const closeBtn = t.querySelector('.selynt-toast-close');

  function close() {
    if (!t.parentNode) return;
    t.classList.add('is-hiding');
    setTimeout(() => { try { t.remove(); } catch (e) {} }, 180);
  }

  closeBtn.addEventListener('click', close);
  container.appendChild(t);

  const ttl = typeof opts.ttlMs === 'number' ? opts.ttlMs : 4200;
  if (ttl > 0) setTimeout(close, ttl);
  return Promise.resolve();
}

function ensureModal() {
  let wrap = document.getElementById('selynt-modal-backdrop');
  if (wrap) return wrap;
  wrap = document.createElement('div');
  wrap.id = 'selynt-modal-backdrop';
  wrap.className = 'selynt-modal-backdrop';
  // Copiar classe de tema do painel
  const panel = document.querySelector('.selynt-panel');
  if (panel && panel.classList.contains('theme-light')) wrap.classList.add('theme-light');
  wrap.style.display = 'none';
  wrap.innerHTML =
    '<div class="selynt-modal" role="dialog" aria-modal="true">' +
      '<div class="selynt-modal-title" id="selyntModalTitle"></div>' +
      '<div class="selynt-modal-text" id="selyntModalText"></div>' +
      '<div class="selynt-modal-actions">' +
        '<button type="button" class="btn-outline" id="selyntModalCancel">Cancelar</button>' +
        '<button type="button" class="btn-outline" id="selyntModalOk">OK</button>' +
      '</div>' +
    '</div>';
  // Append ao body para evitar clipping por overflow:hidden em containers pai
  document.body.appendChild(wrap);
  return wrap;
}

export function confirm(opts) {
  opts = opts || {};
  const title = String(opts.title || 'Confirmar');
  const text = String(opts.text || '');
  const okText = String(opts.okText || 'Sim');
  const cancelText = String(opts.cancelText || 'Cancelar');

  const backdrop = ensureModal();
  const titleEl = backdrop.querySelector('#selyntModalTitle');
  const textEl = backdrop.querySelector('#selyntModalText');
  const okBtn = backdrop.querySelector('#selyntModalOk');
  const cancelBtn = backdrop.querySelector('#selyntModalCancel');

  titleEl.textContent = title;
  textEl.textContent = text;
  okBtn.textContent = okText;
  cancelBtn.textContent = cancelText;
  cancelBtn.style.display = '';

  backdrop.style.display = 'flex';
  try { document.body.classList.add('selynt-modal-open'); } catch (e) {}

  return new Promise((resolve) => {
    function cleanup(result) {
      okBtn.removeEventListener('click', onOk);
      cancelBtn.removeEventListener('click', onCancel);
      backdrop.removeEventListener('click', onBackdrop);
      document.removeEventListener('keydown', onKey);
      backdrop.style.display = 'none';
      try { document.body.classList.remove('selynt-modal-open'); } catch (e) {}
      resolve(result);
    }
    function onOk() { cleanup(true); }
    function onCancel() { cleanup(false); }
    function onBackdrop(e) { if (e.target === backdrop) cleanup(false); }
    function onKey(e) {
      if (e.key === 'Escape') cleanup(false);
      if (e.key === 'Enter') cleanup(true);
    }

    okBtn.addEventListener('click', onOk);
    cancelBtn.addEventListener('click', onCancel);
    backdrop.addEventListener('click', onBackdrop);
    document.addEventListener('keydown', onKey);
    try { okBtn.focus(); } catch (e) {}
  });
}

export function alert(opts) {
  opts = opts || {};
  const title = String(opts.title || 'Aviso');
  const text = String(opts.text || '');
  const okText = String(opts.okText || 'OK');

  const backdrop = ensureModal();
  const titleEl = backdrop.querySelector('#selyntModalTitle');
  const textEl = backdrop.querySelector('#selyntModalText');
  const okBtn = backdrop.querySelector('#selyntModalOk');
  const cancelBtn = backdrop.querySelector('#selyntModalCancel');

  titleEl.textContent = title;
  textEl.textContent = text;
  okBtn.textContent = okText;
  cancelBtn.style.display = 'none';

  backdrop.style.display = 'flex';
  try { document.body.classList.add('selynt-modal-open'); } catch (e) {}

  return new Promise((resolve) => {
    function cleanup() {
      okBtn.removeEventListener('click', onOk);
      backdrop.removeEventListener('click', onBackdrop);
      document.removeEventListener('keydown', onKey);
      backdrop.style.display = 'none';
      try { document.body.classList.remove('selynt-modal-open'); } catch (e) {}
      resolve();
    }
    function onOk() { cleanup(); }
    function onBackdrop(e) { if (e.target === backdrop) cleanup(); }
    function onKey(e) { if (e.key === 'Escape' || e.key === 'Enter') cleanup(); }

    okBtn.addEventListener('click', onOk);
    backdrop.addEventListener('click', onBackdrop);
    document.addEventListener('keydown', onKey);
    try { okBtn.focus(); } catch (e) {}
  });
}

export function setAvailableHeight() {
  try {
    const root = document.querySelector('.selynt-panel');
    if (!root) return;
    const rect = root.getBoundingClientRect();
    const available = Math.max(320, (window.innerHeight || 0) - (rect.top || 0));
    root.style.setProperty('--selynt-available-height', available + 'px');
  } catch (e) {}
}

// Auto-init
function init() {
  setAvailableHeight();
  window.addEventListener('resize', setAvailableHeight);
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
