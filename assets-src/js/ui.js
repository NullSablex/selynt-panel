// Utilitários que todas as páginas usam.
//
// Estavam copiados em cada uma — `esc` em sete, `fmtBytes` e `uptime` em três.
// Cópias assim divergem sem que nada aponte para elas: basta alguém corrigir
// uma e não as outras.

import { t } from './script.min.js';

/** Escapa texto para interpolar em HTML. */
export function esc(s) {
  return String(s).replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[c]);
}

/** Nome de aplicação como id de CSS: só o que um seletor aceita. */
export function cssId(n) {
  return String(n).replace(/[^A-Za-z0-9_-]/g, '_');
}

/** Bytes em MB ou GB. `null` vira travessão. */
export function fmtBytes(b, dash = '—') {
  if (b == null) return dash;
  const mb = b / 1048576;
  return mb >= 1024 ? `${(mb / 1024).toFixed(1)} GB` : `${Math.round(mb)} MB`;
}

/** Como `fmtBytes`, mas sem casa decimal quando o valor é redondo. */
export function fmtMB(b, dash = '—') {
  if (b == null) return dash;
  const mb = Math.round(b / 1048576);
  return mb >= 1024 ? `${(mb / 1024).toFixed(mb % 1024 ? 1 : 0)} GB` : `${mb} MB`;
}

/** Tempo desde `ts` (epoch em segundos), compacto: "2d 3h", "5h 12m".
 *
 * A página de uma aplicação usa outro formato, por extenso e traduzido; são
 * dois formatos de propósito, não uma cópia que ficou para trás. */
export function uptime(ts) {
  const s = Math.max(0, Math.floor(Date.now() / 1000 - ts));
  const d = Math.floor(s / 86400);
  const h = Math.floor((s % 86400) / 3600);
  const m = Math.floor((s % 3600) / 60);
  return d ? `${d}d ${h}h` : h ? `${h}h ${m}m` : `${m}m`;
}

/** Rótulo traduzido do tipo de aplicação. */
export function typeLabel(ty) {
  if (ty === 'node') return t('type.node');
  if (ty === 'binary') return t('type.binary');
  return ty || '—';
}
