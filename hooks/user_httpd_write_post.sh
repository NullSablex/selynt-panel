#!/bin/bash
# Executado pelo DA após regenerar config do vhost (user_httpd_write_post).
# Re-aplica ACL dos sockets Unix para o web server (OLS) poder fazer proxy.
# Variáveis disponíveis: $username, $creator
[ -n "${username:-}" ] || exit 0

SELYNT_PLUGIN_DIR="/usr/local/directadmin/plugins/selynt_panel"
SELYNT_STATE="/var/lib/selynt_panel/$username"

# Diretórios de estado são criados on-demand pelo binário Core Selynt.
# Se não existem, o user nunca usou o plugin — nada a fazer.
[ -d "$SELYNT_STATE/.sockets" ] || exit 0
[ -d "$SELYNT_STATE/.proxy" ]   || exit 0

# ── Re-aplica ACL dos sockets para o web server acessar ──
WEB_USER_FILE="$SELYNT_PLUGIN_DIR/etc/ols_web_user"
[ -r "$WEB_USER_FILE" ] || exit 0
WEB_USER="$(head -n1 "$WEB_USER_FILE" | tr -d '[:space:]')"
[ -n "$WEB_USER" ] || exit 0

SOCKETS_DIR="$SELYNT_STATE/.sockets"
PROXY_DIR="$SELYNT_STATE/.proxy"

for marker in "$PROXY_DIR/"*; do
    [ -f "$marker" ] || continue
    host="$(basename "$marker")"
    socket="$SOCKETS_DIR/$host"
    [ -S "$socket" ] || continue

    if command -v setfacl >/dev/null 2>&1; then
        setfacl -m "u:${WEB_USER}:--x" "$SELYNT_STATE"   2>/dev/null || true
        setfacl -m "u:${WEB_USER}:--x" "$SOCKETS_DIR"    2>/dev/null || true
        setfacl -m "u:${WEB_USER}:--x" "$PROXY_DIR"      2>/dev/null || true
        setfacl -m "u:${WEB_USER}:rw-" "$socket"         2>/dev/null || true
        setfacl -m "u:${WEB_USER}:r--" "$marker"         2>/dev/null || true
    else
        chmod 711 "$SELYNT_STATE" "$SOCKETS_DIR" "$PROXY_DIR" 2>/dev/null || true
        chmod 660 "$socket"  2>/dev/null || true
        chmod 644 "$marker"  2>/dev/null || true
    fi
done

exit 0
