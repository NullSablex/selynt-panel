#!/bin/bash
# setup-ols.sh — Configura o Selynt Panel no OpenLiteSpeed + DirectAdmin.
# Deve ser executado como root (pelo install.sh ou via admin/api/config.raw).
#
# O que faz:
#   1. Instala DA custom templates (CUSTOM.7 + CUSTOM.5) para proxy por vhost
#   2. Rebuild de vhosts para aplicar os templates
#   3. Detecta web user para ACL
#   4. Cron job para sync/reload do OLS
set -euo pipefail

OLS_CONF_DIR="/usr/local/lsws/conf"
OLS_MAIN_CONF="$OLS_CONF_DIR/httpd_config.conf"
PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

DA_TPL_DIR="/usr/local/directadmin/data/templates/custom"
BEGIN_MARK="# BEGIN SELYNT_PANEL"
END_MARK="# END SELYNT_PANEL"

# ── Cores e helpers ──
R="\033[0;31m"; G="\033[0;32m"; Y="\033[0;33m"; B="\033[0;36m"; D="\033[0;90m"; N="\033[0m"; BOLD="\033[1m"
ok()   { printf "${G}  ✓${N} %s\n" "$1"; }
erro() { printf "${R}  ✗${N} %s\n" "$1" >&2; }
warn() { printf "${Y}  ⚠${N} %s\n" "$1"; }
info() { printf "${D}    %s${N}\n" "$1"; }
step() { printf "\n${BOLD}${B}── %s ──${N}\n" "$1"; }

[ "$(id -u)" -eq 0 ] || { erro "Execute como root."; exit 1; }

if [ ! -d "$OLS_CONF_DIR" ] || [ ! -f "$OLS_MAIN_CONF" ]; then
    erro "OpenLiteSpeed não encontrado."
    exit 1
fi

printf "\n${BOLD}Selynt Panel${N} — Setup OLS\n"

# ── Função: upsert bloco delimitado em um arquivo ──
# Uso: upsert_template "path/file" "conteúdo"
upsert_template() {
    local file="$1" content="$2"

    if [ -f "$file" ]; then
        local clean
        clean="$(awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
            $0==b {inside=1; next}
            $0==e {inside=0; next}
            !inside {print}
        ' "$file")"
        # Conteúdo limpo vazio? Só o nosso bloco.
        if [ -z "$(echo "$clean" | tr -d '[:space:]')" ]; then
            printf "%s\n" "$content" > "$file"
        else
            printf "%s\n%s\n" "$content" "$clean" > "$file"
        fi
    else
        printf "%s\n" "$content" > "$file"
    fi
    chmod 755 "$file"
}

# ── 1. DA custom templates ──
#
# Mecanismo de proxy em duas camadas:
#
# CUSTOM.7 (fim do virtualHost): define um extProcessor POR VHOST usando
#   variáveis DA. O extProcessor aponta para o Unix socket do app.
#   Isso garante que o extProcessor exista no escopo do vhost,
#   sem depender de includes no httpd_config.conf ou sync externo.
#
# CUSTOM.5 (rewrite rules): RewriteCond verifica se o marker .proxy/|SDOMAIN|
#   existe. Se existe → app ativo → proxy para o extProcessor.
#   Se não existe → request segue normal (site estático, PHP, etc.).
#
# Variáveis DA expandidas por vhost:
#   |USER|    — username do dono do domínio
#   |SDOMAIN| — domínio/subdomínio do vhost
#   |VH_PORT| — porta do vhost (80 ou 443)

step "Templates"

if [ -d /usr/local/directadmin/data/templates ]; then
    mkdir -p "$DA_TPL_DIR"

    # Limpar templates com nome errado de versões anteriores
    rm -f "$DA_TPL_DIR"/cust_openlitespeed.CUSTOM.*.pre 2>/dev/null || true

    # CUSTOM.7 — extProcessor per-vhost (proxy via Unix socket)
    upsert_template "$DA_TPL_DIR/openlitespeed_vhost.conf.CUSTOM.7.pre" "$(cat <<'EOF'
# BEGIN SELYNT_PANEL
extprocessor selynt_proxy-|SDOMAIN|-|VH_PORT| {
  type                    proxy
  address                 uds:///var/lib/selynt_panel/|USER|/.sockets/|SDOMAIN|
  maxConns                35
  initTimeout             60
  retryTimeout            0
  persistConn             1
  respBuffer              0
  autoStart               0
  instances               1
}
# END SELYNT_PANEL
EOF
)"
    ok "Template CUSTOM.7 (extProcessor)"

    # CUSTOM.5 — rewrite condicional (só proxy se app ativo)
    upsert_template "$DA_TPL_DIR/openlitespeed_vhost.conf.CUSTOM.5.pre" "$(cat <<'EOF'
# BEGIN SELYNT_PANEL
RewriteCond /var/lib/selynt_panel/|USER|/.proxy/|SDOMAIN| -f
RewriteRule ^(.*)$ http://selynt_proxy-|SDOMAIN|-|VH_PORT|/$1 [P,L,E=PROXY-HOST:|HTTP_HOST|]
# END SELYNT_PANEL
EOF
)"
    ok "Template CUSTOM.5 (rewrite proxy)"

    # ── 2. Rebuild de vhosts ──
    step "Rebuild"
    if [ -x /usr/local/directadmin/custombuild/build ]; then
        if (cd /usr/local/directadmin/custombuild && ./build rewrite_confs) >/dev/null 2>&1; then
            ok "Vhosts reconstruídos"
        else
            warn "Rebuild de vhosts falhou"
        fi
    elif command -v da >/dev/null 2>&1; then
        if da build rewrite_confs >/dev/null 2>&1; then
            ok "Vhosts reconstruídos"
        else
            warn "Rebuild de vhosts falhou"
        fi
    else
        warn "Rebuild manual necessário"
        info "cd /usr/local/directadmin/custombuild && ./build rewrite_confs"
    fi
else
    warn "Templates do DA não encontrados"
fi

# ── 2b. Garantir traverse no state dir base (para web server acessar sockets/markers) ──
chmod 711 /var/lib/selynt_panel 2>/dev/null || true

# ── 3. Web user ──
step "Servidor web"

WEB_USER=""
if [ -r "$OLS_MAIN_CONF" ]; then
    WEB_USER="$(awk 'tolower($1)=="user"{print $2; exit}' "$OLS_MAIN_CONF" 2>/dev/null || true)"
    WEB_USER="${WEB_USER%\"}"; WEB_USER="${WEB_USER#\"}"
fi
if [ -z "$WEB_USER" ]; then
    for u in apache lsws www-data nginx nobody; do
        if id "$u" >/dev/null 2>&1; then WEB_USER="$u"; break; fi
    done
fi
if [ -n "$WEB_USER" ]; then
    mkdir -p "$PLUGIN_DIR/etc"
    printf "%s\n" "$WEB_USER" > "$PLUGIN_DIR/etc/ols_web_user"
    chmod 755 "$PLUGIN_DIR/etc/ols_web_user"
    ok "Usuário web: $WEB_USER"
fi

# ── 4. Cron job (sync + reload) ──
step "Cron"

SYNC_SCRIPT="$PLUGIN_DIR/scripts/sync-extprocessors.sh"
CRON_LINE="* * * * * [ -f /var/lib/selynt_panel/.sync_needed ] && $SYNC_SCRIPT"
if ! crontab -l 2>/dev/null | grep -qF "sync-extprocessors.sh"; then
    ( crontab -l 2>/dev/null; printf "%s\n" "$CRON_LINE" ) | crontab -
    ok "Cron job instalado"
else
    ok "Cron job já presente"
fi

# ── Reload ──
step "Reload"

if systemctl restart lsws 2>/dev/null; then
    ok "Servidor web reiniciado"
elif command -v lswsctrl >/dev/null 2>&1 && lswsctrl restart 2>/dev/null; then
    ok "Servidor web reiniciado (lswsctrl)"
else
    warn "Restart do servidor web falhou"
fi

printf "\n${G}${BOLD}  ✓ Setup OLS concluído${N}\n\n"
exit 0
