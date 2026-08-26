<?php
declare(strict_types=1);

/**
 * Selynt Panel — i18n
 *
 * Locale resolution chain (first non-empty match wins):
 *   1. SELYNT_LOCALE env var (debug/override)
 *   2. The current user's own panel-language preference
 *   3. The plugin-wide default chosen by the admin
 *   4. 'en' (default — en-US)
 *
 * The plugin manages its own language entirely — DirectAdmin does NOT expose
 * the user's chosen interface language to plugin CGI scripts, and its
 * `language=` codes (e.g. `en`, `nl`) don't match our locale identifiers
 * (e.g. `pt-br`), so we never relied on it.
 *
 * Available locales are the `*.json` files under `lib/i18n/`. Strings are
 * loaded once per request and the en.json dictionary is layered as a fallback
 * so missing keys in non-default locales don't break the UI.
 */

const SELYNT_I18N_DEFAULT = 'en';

/**
 * Persistent state dir. Holds the plugin-wide default at `<dir>/locale` and
 * each user's own preference at `<dir>/<username>/locale`. Lives outside the
 * plugin tree so it survives plugin updates (etc/ would be overwritten).
 */
const SELYNT_I18N_STATE_DIR = '/var/lib/selynt_panel';

/** Path to the plugin-wide default locale file. */
function selynt_i18n_global_file(): string {
    return SELYNT_I18N_STATE_DIR . '/locale';
}

/** Path to the per-user preference file for $username (empty if no user). */
function selynt_i18n_user_file(string $username): string {
    if ($username === '') return '';
    return SELYNT_I18N_STATE_DIR . '/' . $username . '/locale';
}

/** Reads a stored locale code from $path, normalized; '' if unset/invalid. */
function selynt_i18n_read_file(string $path): string {
    if ($path === '' || !is_readable($path)) return '';
    $raw = (string)@file_get_contents($path);
    $norm = selynt_normalize_locale($raw, selynt_i18n_available());
    return $norm ?? '';
}

/** Returns the plugin-wide default locale chosen by the admin ('' if unset). */
function selynt_i18n_global(): string {
    return selynt_i18n_read_file(selynt_i18n_global_file());
}

/** Returns $username's stored panel-language preference ('' if unset). */
function selynt_i18n_user_pref(string $username): string {
    return selynt_i18n_read_file(selynt_i18n_user_file($username));
}

/**
 * Persists the plugin-wide default locale through the setuid `core-selynt`
 * binary. The state dir is owned by `diradmin` (711) and the panel CGI runs as
 * the web user, so the write has to happen as root inside the binary — a direct
 * file_put_contents() from PHP fails (this was the "saves OK but reverts" bug).
 *
 * Returns the raw `selynt_run` result (`['ok' => bool, ...]`).
 */
function selynt_i18n_set_global(string $locale): array {
    return selynt_run(['admin', 'set-locale', $locale]);
}

/** Saves $username's own panel-language preference via the setuid binary. */
function selynt_i18n_set_user_pref(string $locale): array {
    return selynt_run(['set-locale', $locale]);
}

function selynt_i18n_available(): array {
    static $list = null;
    if ($list !== null) return $list;
    $list = [];
    $dir = SELYNT_PLUGIN_DIR . '/lib/i18n';
    if (is_dir($dir)) {
        foreach (scandir($dir) ?: [] as $f) {
            if (substr($f, -5) === '.json') $list[] = substr($f, 0, -5);
        }
    }
    if (!in_array(SELYNT_I18N_DEFAULT, $list, true)) $list[] = SELYNT_I18N_DEFAULT;
    return $list;
}

function selynt_read_kv_value(string $path, string $key): string {
    if (!is_readable($path)) return '';
    $fh = @fopen($path, 'r');
    if (!$fh) return '';
    $val = '';
    while (($line = fgets($fh)) !== false) {
        $line = trim($line);
        if ($line === '' || $line[0] === '#') continue;
        $eq = strpos($line, '=');
        if ($eq === false) continue;
        if (trim(substr($line, 0, $eq)) === $key) {
            $val = trim(substr($line, $eq + 1));
            // Strip surrounding double or single quotes.
            $val = trim($val, "\"'");
            break;
        }
    }
    fclose($fh);
    return $val;
}

/**
 * Returns the available locales as a list of `['code' => ..., 'name' => ...]`,
 * where `name` is each dictionary's own `_meta.name` (falling back to the code).
 * Used to populate the language selectors in the UI.
 */
function selynt_i18n_options(): array {
    $opts = [];
    foreach (selynt_i18n_available() as $code) {
        $name = $code;
        $path = SELYNT_PLUGIN_DIR . '/lib/i18n/' . $code . '.json';
        $raw = @file_get_contents($path);
        if (is_string($raw)) {
            $decoded = json_decode($raw, true);
            if (is_array($decoded) && !empty($decoded['_meta.name'])) {
                $name = (string)$decoded['_meta.name'];
            }
        }
        $opts[] = ['code' => $code, 'name' => $name];
    }
    return $opts;
}

/** Display name of the currently active locale (its `_meta.name`). */
function selynt_i18n_active_name(): string {
    $active = selynt_locale();
    foreach (selynt_i18n_options() as $opt) {
        if ($opt['code'] === $active) return $opt['name'];
    }
    return $active;
}

function selynt_normalize_locale(string $raw, array $available): ?string {
    $raw = strtolower(trim($raw));
    if ($raw === '') return null;
    // Strip POSIX-style charset suffix (e.g. ".UTF-8" or "@euro").
    $raw = (string)preg_replace('/[.@].*$/', '', $raw);
    if ($raw === '') return null;
    $raw = str_replace('_', '-', $raw);
    if (in_array($raw, $available, true)) return $raw;
    // Try language prefix (e.g. "en-GB" → "en", "pt-BR" → "pt").
    $prefix = explode('-', $raw)[0];
    if (in_array($prefix, $available, true)) return $prefix;
    return null;
}

function selynt_locale(): string {
    static $cached = null;
    if ($cached !== null) return $cached;

    $available = selynt_i18n_available();
    $candidates = [];

    // 1. Explicit override (debug / passed through to the core binary).
    $candidates[] = trim((string)getenv('SELYNT_LOCALE'));

    // 2. The current user's own panel-language preference.
    if (function_exists('selynt_username')) {
        $username = selynt_username();
        if ($username !== '') {
            $candidates[] = selynt_i18n_user_pref($username);
        }
    }

    // 3. Plugin-wide default chosen by the admin.
    $candidates[] = selynt_i18n_global();

    foreach ($candidates as $c) {
        $norm = selynt_normalize_locale((string)$c, $available);
        if ($norm !== null) return $cached = $norm;
    }
    return $cached = SELYNT_I18N_DEFAULT;
}

function selynt_i18n_dict(): array {
    static $dict = null;
    if ($dict !== null) return $dict;

    $loc = selynt_locale();
    $load = static function (string $code): array {
        $path = SELYNT_PLUGIN_DIR . '/lib/i18n/' . $code . '.json';
        $raw = @file_get_contents($path);
        if (!is_string($raw)) return [];
        $decoded = json_decode($raw, true);
        return is_array($decoded) ? $decoded : [];
    };

    $primary = $load($loc);
    if ($loc === SELYNT_I18N_DEFAULT) return $dict = $primary;
    // Layer with default as fallback for missing keys.
    return $dict = $primary + $load(SELYNT_I18N_DEFAULT);
}

function selynt_t(string $key, array $vars = []): string {
    $dict = selynt_i18n_dict();
    $val = (string)($dict[$key] ?? $key);
    if ($vars !== []) {
        foreach ($vars as $k => $v) {
            $val = str_replace('{' . (string)$k . '}', (string)$v, $val);
        }
    }
    return $val;
}

function selynt_t_html(string $key, array $vars = []): string {
    return htmlspecialchars(selynt_t($key, $vars), ENT_QUOTES, 'UTF-8');
}

/**
 * Emits a `<script>` tag that exposes the active dictionary plus the locale
 * code to client-side code as `window.__SELYNT_I18N`.
 */
function selynt_i18n_script_tag(): string {
    $payload = json_encode(
        ['locale' => selynt_locale(), 'dict' => selynt_i18n_dict()],
        JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES
    );
    if ($payload === false) {
        $payload = '{"locale":"' . SELYNT_I18N_DEFAULT . '","dict":{}}';
    }
    return '<script>window.__SELYNT_I18N=' . $payload . ';</script>';
}
