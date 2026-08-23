export function t(key, vars) {
  const bundle = (typeof window !== 'undefined' && window.__SELYNT_I18N) || null;
  const dict = (bundle && bundle.dict) || {};
  let s = dict[key];
  if (s === undefined) s = key;
  if (vars) {
    for (const k in vars) {
      if (Object.prototype.hasOwnProperty.call(vars, k)) {
        s = s.split('{' + k + '}').join(String(vars[k]));
      }
    }
  }
  return s;
}

export function locale() {
  const bundle = (typeof window !== 'undefined' && window.__SELYNT_I18N) || null;
  return (bundle && bundle.locale) || 'en';
}

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

  const el = document.createElement('div');
  el.className = 'selynt-toast selynt-toast-' + (type || 'info');
  el.setAttribute('role', 'status');
  el.innerHTML =
    '<div class="selynt-toast-body"></div>' +
    '<button type="button" class="selynt-toast-close" aria-label="' + t('common.close').replace(/"/g, '&quot;') + '">×</button>';

  el.querySelector('.selynt-toast-body').textContent = message;
  const closeBtn = el.querySelector('.selynt-toast-close');

  function close() {
    if (!el.parentNode) return;
    el.classList.add('is-hiding');
    setTimeout(() => { try { el.remove(); } catch (e) {} }, 180);
  }

  closeBtn.addEventListener('click', close);
  container.appendChild(el);

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
        '<button type="button" class="btn-outline" id="selyntModalCancel"></button>' +
        '<button type="button" class="btn-outline" id="selyntModalOk"></button>' +
      '</div>' +
    '</div>';
  // Append ao body para evitar clipping por overflow:hidden em containers pai
  document.body.appendChild(wrap);
  return wrap;
}

export function confirm(opts) {
  opts = opts || {};
  const title = String(opts.title || t('common.confirm'));
  const text = String(opts.text || '');
  const okText = String(opts.okText || t('common.yes'));
  const cancelText = String(opts.cancelText || t('common.cancel'));

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
  const title = String(opts.title || t('common.warn'));
  const text = String(opts.text || '');
  const okText = String(opts.okText || t('common.ok'));

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

// ── Language picker modal ──────────────────────────────────────────────────
//
// Wires a header button to a modal listing the available languages. `apiBase`
// is the plugin API root; `endpoint` is the .raw that exposes `get`/`save`
// (config.raw for admin, locale.raw for the user). Selecting a language POSTs
// it and reloads so the server re-renders every string in the new locale.

function escAttr(s) {
  return String(s).replace(/[&<>"']/g, function (c) {
    return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
  });
}

// Splits a display name like "Português (Brasil)" into name + variant.
function splitLangName(full) {
  const m = /^(.*?)\s*\(([^)]*)\)\s*$/.exec(String(full || ''));
  if (m) return { name: m[1], variant: m[2] };
  return { name: String(full || ''), variant: '' };
}

export function langModal(opts) {
  opts = opts || {};
  const apiBase = opts.apiBase || '';
  const endpoint = opts.endpoint || 'locale.raw';
  const getAction = opts.getAction || 'get';
  const saveAction = opts.saveAction || 'save';
  const btn = opts.button || document.getElementById('sly-lang-btn');
  if (!btn) return;

  const url = apiBase.replace(/\/$/, '') + '/' + endpoint;

  function buildModal(data) {
    const active = (data.pref || data.global || data.active || locale());
    const backdrop = document.createElement('div');
    backdrop.className = 'lang-modal-backdrop';
    const items = (data.options || []).map(function (o) {
      const parts = splitLangName(o.name);
      const isActive = o.code === active ? ' active' : '';
      return (
        '<button type="button" class="lang-item' + isActive + '" data-code="' + escAttr(o.code) + '">' +
          '<i class="fa-solid fa-globe lang-flag-icon"></i>' +
          '<span class="lang-text">' +
            '<span class="lang-name">' + escAttr(parts.name) + '</span>' +
            (parts.variant ? '<span class="lang-variant">' + escAttr(parts.variant) + '</span>' : '') +
          '</span>' +
          (isActive ? '<i class="fa-solid fa-check lang-check"></i>' : '') +
        '</button>'
      );
    }).join('');
    backdrop.innerHTML =
      '<div class="lang-modal" role="dialog" aria-modal="true">' +
        '<div class="lang-modal-header">' +
          '<div class="lang-modal-title">' + escAttr(t('locale.modal_title')) + '</div>' +
          '<button type="button" class="lang-modal-close" aria-label="' + escAttr(t('common.close')) + '">' +
            '<i class="fa-solid fa-xmark"></i></button>' +
        '</div>' +
        '<div class="lang-modal-subtitle">' + escAttr(t('locale.modal_subtitle')) + '</div>' +
        '<div class="lang-modal-grid">' + items + '</div>' +
      '</div>';
    return backdrop;
  }

  function open(data) {
    const backdrop = buildModal(data);
    getRoot().appendChild(backdrop);
    requestAnimationFrame(function () { backdrop.classList.add('open'); });

    function close() {
      backdrop.classList.remove('open');
      setTimeout(function () { backdrop.remove(); }, 150);
    }
    backdrop.addEventListener('click', function (e) {
      if (e.target === backdrop) close();
      const closeBtn = e.target.closest('.lang-modal-close');
      if (closeBtn) close();
      const item = e.target.closest('.lang-item');
      if (item) save(item.getAttribute('data-code'), backdrop);
    });
    document.addEventListener('keydown', function onKey(e) {
      if (e.key === 'Escape') { close(); document.removeEventListener('keydown', onKey); }
    });
  }

  function save(code, backdrop) {
    const items = backdrop.querySelectorAll('.lang-item');
    items.forEach(function (el) { el.disabled = true; });

    function fail(msg) {
      // Close first: a toast behind an open backdrop is easy to miss, and the
      // modal would otherwise stay up with every option disabled.
      backdrop.classList.remove('open');
      setTimeout(function () { backdrop.remove(); }, 150);
      toast('error', msg || t('errors.invalid_locale'));
    }

    // Query string, not a JSON body: under DirectAdmin's CGI the .raw scripts
    // read the body with fread(STDIN) against CONTENT_LENGTH, which stalls
    // until the plugin timeout when the two disagree — the request then dies
    // with no response at all. Every other endpoint here posts this way.
    const qs = 'action=' + encodeURIComponent(saveAction) +
               '&locale=' + encodeURIComponent(code);
    fetch(url + '?' + qs, { method: 'POST' }).then(function (r) {
      return r.json();
    }).then(function (d) {
      if (d && d.ok) { location.reload(); return; }
      fail(d && d.message);
    }).catch(function () {
      fail('');
    });
  }

  btn.addEventListener('click', function () {
    btn.disabled = true;
    fetch(url + '?action=' + getAction).then(function (r) { return r.json(); }).then(function (d) {
      btn.disabled = false;
      if (d && d.ok) open(d);
      else toast('error', t('errors.invalid_locale'));
    }).catch(function () {
      btn.disabled = false;
      toast('error', t('errors.invalid_locale'));
    });
  });
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
