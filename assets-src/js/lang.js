// Seletor de idioma: o modal que o botão do cabeçalho abre.

import { t, locale } from './i18n.min.js';
import { getRoot } from './dom.min.js';

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
