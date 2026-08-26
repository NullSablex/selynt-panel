// Preferências da conta: hoje só o isolamento entre aplicações.
//
// A página entrega os dados em `window.__SELYNT_SETTINGS`; o resto vive aqui.

import { t, toast } from './script.min.js';

const { endpoint: API } = window.__SELYNT_SETTINGS ?? {};
const stateEl = document.getElementById('iso-state');
const btn = document.getElementById('iso-toggle');
const btnLabel = document.getElementById('iso-toggle-label');
let isolated = false;

let supported = true;

function render() {
  stateEl.textContent = t(isolated ? 'settings.isolation.on' : 'settings.isolation.off');
  stateEl.className = 'cfg-val ' + (isolated ? 'ok' : 'text-half');
  btnLabel.textContent = t(isolated ? 'settings.isolation.disable' : 'settings.isolation.enable');

  // Offering a switch the server cannot honour would be worse than not showing
  // one: the account would come away believing its apps are separated.
  btn.disabled = !supported && !isolated;
}

async function load() {
  const r = await fetch(`${API}?action=get`).then(x => x.json()).catch(() => null);
  if (!r || !r.ok) { stateEl.textContent = t('errors.generic'); return; }
  isolated = !!r.isolated;
  supported = r.supported !== false;
  render();

  if (!supported) {
    const note = document.getElementById('iso-unsupported');
    note.textContent = t(r.reason || 'settings.isolation.unsupported');
    note.hidden = false;
  }
}

btn.addEventListener('click', async () => {
  btn.disabled = true;
  btnLabel.textContent = t('settings.isolation.applying');

  const next = isolated ? '0' : '1';
  const r = await fetch(`${API}?action=set&isolated=${next}`, { method: 'POST' })
    .then(x => x.json()).catch(() => null);

  if (!r || !r.ok) {
    toast('error', (r && r.message) || t('errors.generic'));
    render();
    return;
  }

  isolated = !!r.isolated;
  render();

  // Applications are restarted for us, so the message says what happened
  // rather than asking the user to go and do it. Applying the mode stops each
  // app first, so one that failed to come back is down right now — reporting
  // only the successes would leave the user to discover that on their own.
  const n = (r.restarted || []).length;
  const failed = r.failed || [];
  if (failed.length) {
    toast('error', t('settings.isolation.saved_failed', {
      n: failed.length,
      apps: failed.join(', '),
    }));
  } else {
    toast('success', n
      ? t('settings.isolation.saved_restarted', { n })
      : t('settings.isolation.saved'));
  }
});

load();
