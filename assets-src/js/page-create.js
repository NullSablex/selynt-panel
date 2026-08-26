// Formulário de criação: monta o cwd e o host a partir do domínio escolhido.
//
// A página entrega os dados em `window.__SELYNT_CREATE`; o resto vive aqui.

import { t } from './script.min.js';
import { esc } from './ui.min.js';

const { user: _user, domains: _domainsData } = window.__SELYNT_CREATE ?? {};
function buildCwd() {
  const name = document.getElementById('f-name').value.trim() || 'app';
  return `/home/${_user}/apps/${name}`;
}

function syncEntry() {
  const el = document.getElementById('f-entry');
  if (el.dataset.auto !== '0') {
    el.value = document.getElementById('f-type').value === 'node' ? 'index.js' : 'app';
    el.dataset.auto = '1';
  }
}

function onFormChange() {
  document.getElementById('f-cwd').value = buildCwd();
  syncEntry();
  const nvEl = document.getElementById('fg-node-version');
  nvEl.style.display = document.getElementById('f-type').value === 'node' ? '' : 'none';
}

const nvRes = await fetch('/CMD_PLUGINS/selynt_panel/api/nodes.raw').then(r=>r.json()).catch(()=>null);
{
  const sel = document.getElementById('f-node-version');
  if (!nvRes || !nvRes.ok || !nvRes.versions || !nvRes.versions.length) {
    sel.innerHTML = '<option value="">'+esc(t('create.field.node_default'))+'</option>';
  } else {
    sel.innerHTML = nvRes.versions.map(v =>
      `<option value="${esc(v.path)}">${esc(v.label)}</option>`
    ).join('');
  }
}

document.getElementById('f-entry').addEventListener('input', function() { this.dataset.auto = '0'; });
['f-host', 'f-type'].forEach(id => document.getElementById(id).addEventListener('change', onFormChange));
document.getElementById('f-name').addEventListener('input', onFormChange);

document.getElementById('sly-form').addEventListener('submit', async function(e) {
  e.preventDefault();
  const btn = this.querySelector('button[type=submit]');
  const msg = document.getElementById('sly-msg');
  btn.disabled = true; btn.textContent = t('create.submitting'); msg.classList.add('d-none');
  const type = document.getElementById('f-type').value;
  const params = new URLSearchParams({
    name:  document.getElementById('f-name').value.trim(),
    type:  type,
    host:  document.getElementById('f-host').value,
    cwd:   document.getElementById('f-cwd').value.trim(),
    entry: document.getElementById('f-entry').value.trim(),
    env:   document.getElementById('f-env').value.trim(),
  });
  if (type === 'node') {
    params.set('node_version', document.getElementById('f-node-version').value);
  }
  const r = await fetch(`/CMD_PLUGINS/selynt_panel/api/create.raw?${params}`, {
    method: 'POST'
  }).then(r => r.json()).catch(() => ({ok:false, message:t('errors.network')}));
  if (r.ok) {
    window.location.href = '/CMD_PLUGINS/selynt_panel';
  } else {
    msg.textContent = r.message || r.error || t('errors.create_failed');
    msg.classList.remove('d-none');
    btn.disabled = false; btn.textContent = t('create.submit');
  }
});

onFormChange();
