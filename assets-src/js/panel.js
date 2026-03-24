const ROOT = document.querySelector('.selynt-panel');

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

  ROOT.classList.toggle('theme-light', isProbablyLight());
}

if (ROOT) {
  applyDirectAdminTheme();
  try {
    const obs = new MutationObserver(() => applyDirectAdminTheme());
    if (document.documentElement) obs.observe(document.documentElement, { attributes: true, attributeFilter: ['class', 'data-theme'] });
    if (document.body) obs.observe(document.body, { attributes: true, attributeFilter: ['class', 'data-theme'] });
  } catch (e) {}
}
