// Tradução no cliente.
//
// O dicionário chega pronto em `window.__SELYNT_I18N`, montado pelo PHP: a
// página já sabe o idioma quando renderiza, e buscá-lo de novo aqui só daria
// a chance de os dois discordarem.

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
