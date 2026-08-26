const ROOT = document.querySelector('.selynt-panel');

// Tema escolhido pelo usuário, quando houver. O painel espelha o tema do
// DirectAdmin por padrão, mas fora da skin não há DA na página para observar —
// então a escolha explícita fica guardada aqui e tem prioridade.
const THEME_KEY = 'selynt.theme';

function storedTheme() {
  try {
    const v = localStorage.getItem(THEME_KEY);
    return v === 'light' || v === 'dark' ? v : null;
  } catch (e) {
    return null;   // localStorage bloqueado (modo privado, cookies desativados)
  }
}

function storeTheme(theme) {
  try {
    if (theme) localStorage.setItem(THEME_KEY, theme);
    else localStorage.removeItem(THEME_KEY);
  } catch (e) {}
}

export function applyTheme(theme) {
  if (!ROOT) return;
  // A marca do boot fica no <html> e vale só até aqui: mantê-la significaria
  // duas fontes decidindo a mesma cor, e a do boot não muda ao alternar.
  document.documentElement.classList.remove('selynt-boot-light');
  ROOT.classList.toggle('theme-light', theme === 'light');
  // O backdrop de modais vive fora de .selynt-panel; mantém-se em sincronia.
  const backdrop = document.getElementById('selynt-modal-backdrop');
  if (backdrop) backdrop.classList.toggle('theme-light', theme === 'light');
}

export function currentTheme() {
  return ROOT && ROOT.classList.contains('theme-light') ? 'light' : 'dark';
}

export function toggleTheme() {
  const next = currentTheme() === 'light' ? 'dark' : 'light';
  storeTheme(next);
  applyTheme(next);
  return next;
}

function applyDirectAdminTheme() {
  if (!ROOT) return;

  function isProbablyLight() {
    const el = document.documentElement;
    const body = document.body;

    function normalizeThemeValue(v) {
      v = (v || '').toLowerCase().trim();
      if (!v) return null;
      if (v === 'dark' || v === 'night') return 'dark';
      if (v === 'light' || v === 'day') return 'light';
      if (v === 'auto' || v === 'system' || v === 'os' || v === 'default') return 'auto';
      return null;
    }

    function themeFromAttr() {
      const targets = [el, body].filter(Boolean);
      const attrNames = ['data-theme', 'data-color-scheme', 'data-color-mode', 'data-bs-theme'];
      for (const target of targets) {
        for (const attr of attrNames) {
          const t = normalizeThemeValue(target.getAttribute(attr));
          if (t) return t;
        }
      }
      return null;
    }

    function themeFromClasses() {
      const classes = [];
      if (el && el.classList) classes.push(...el.classList);
      if (body && body.classList) classes.push(...body.classList);
      const joined = classes.join(' ').toLowerCase();
      if (/theme-dark|dark-mode|mode-dark|is-dark|\bdark\b/.test(joined)) return 'dark';
      if (/theme-light|light-mode|mode-light|is-light|\blight\b/.test(joined)) return 'light';
      return null;
    }

    const t = themeFromAttr() || themeFromClasses();
    if (t === 'light') return true;
    if (t === 'dark') return false;

    try {
      if (window.matchMedia?.('(prefers-color-scheme: dark)').matches) return false;
    } catch (e) {}
    return true;
  }

  const chosen = storedTheme();
  applyTheme(chosen ?? (isProbablyLight() ? 'light' : 'dark'));
}

if (ROOT) {
  applyDirectAdminTheme();
  try {
    // Só faz sentido espelhar o DirectAdmin enquanto o usuário não escolheu:
    // uma escolha explícita não deve ser desfeita por mudança na skin.
    const obs = new MutationObserver(() => {
      if (!storedTheme()) applyDirectAdminTheme();
    });
    if (document.documentElement) obs.observe(document.documentElement, { attributes: true, attributeFilter: ['class', 'data-theme'] });
    if (document.body) obs.observe(document.body, { attributes: true, attributeFilter: ['class', 'data-theme'] });
  } catch (e) {}

  const themeBtn = document.getElementById('sly-theme-btn');
  if (themeBtn) themeBtn.addEventListener('click', () => toggleTheme());
}

