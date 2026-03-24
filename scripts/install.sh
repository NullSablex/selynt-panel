#!/bin/sh
# Selynt Panel — DirectAdmin Plugin Installer
# SEM set -e: o install do DA nunca pode falhar ou o plugin não será registrado.

PLUGIN_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

# ── Cores e helpers (compatível com sh) ──
R="\033[0;31m"; G="\033[0;32m"; Y="\033[0;33m"; B="\033[0;36m"; D="\033[0;90m"; N="\033[0m"; BOLD="\033[1m"
ok()   { printf "${G}  ✓${N} %s\n" "$1"; }
erro() { printf "${R}  ✗${N} %s\n" "$1"; }
warn() { printf "${Y}  ⚠${N} %s\n" "$1"; }
info() { printf "${D}    %s${N}\n" "$1"; }
step() { printf "\n${BOLD}${B}── %s ──${N}\n" "$1"; }

printf "\n${BOLD}Selynt Panel${N} — Instalando\n"

# ── Binário Core Selynt (setuid root) ──
# O CGI do DA roda como diradmin, não como o user logado.
# O binário precisa de setuid root (4755) para:
#   - Criar dirs de estado em /var/lib/selynt_panel/$username/
#   - Criar logs/ no cwd do app (dentro do home do user)
#   - Drop de privilégio para o user real antes de spawnar apps
BIN="$PLUGIN_DIR/bin/core-selynt"

# ── Diretório de configuração ──
mkdir -p "$PLUGIN_DIR/etc" 2>/dev/null || true

step "Ambiente"

# ── Detectar e salvar DA_USER e DA_UID ──
DA_USER=""
if id diradmin >/dev/null 2>&1; then
    DA_USER="diradmin"
elif pgrep -x directadmin >/dev/null 2>&1; then
    DA_USER="$(ps -o user= -p "$(pgrep -x directadmin | head -1)" 2>/dev/null | tr -d ' ')"
fi
if [ -z "$DA_USER" ] && [ -f /usr/local/directadmin/directadmin ]; then
    DA_USER="$(stat -c '%U' /usr/local/directadmin/directadmin 2>/dev/null)"
fi
[ -z "$DA_USER" ] && DA_USER="diradmin"
DA_UID="$(id -u "$DA_USER" 2>/dev/null || echo "")"
ok "Usuário DA: $DA_USER${DA_UID:+ (UID $DA_UID)}"
printf "%s\n" "$DA_USER"      > "$PLUGIN_DIR/etc/da_user" 2>/dev/null || true
printf "%s\n" "${DA_UID:-}"   > "$PLUGIN_DIR/etc/da_uid"  2>/dev/null || true

# ── Detectar usuário do servidor web ──
WEB_USER=""
for u in lsws www-data apache nginx nobody; do
    if id "$u" >/dev/null 2>&1; then
        WEB_USER="$u"
        break
    fi
done
if [ -n "$WEB_USER" ]; then
    printf "%s\n" "$WEB_USER" > "$PLUGIN_DIR/etc/ols_web_user" 2>/dev/null || true
    ok "Usuário web: $WEB_USER"
else
    warn "Usuário do servidor web não detectado"
fi

# ── Logs do plugin (dentro do etc/ do plugin, acessível por diradmin) ──
touch "$PLUGIN_DIR/etc/stderr.log" "$PLUGIN_DIR/etc/debug.log" 2>/dev/null || true
info "Logs: $PLUGIN_DIR/etc/"

# ── Diretório de estado (fora do home dos users) ──
# Dados operacionais (PIDs, sockets, proxy, metadata) ficam aqui.
# Subdirs por user criados on-demand pelo binário.
# Logs do APP ficam no cwd do app (criados pelo binário via setuid).
SELYNT_DATA="/var/lib/selynt_panel"
mkdir -p "$SELYNT_DATA" 2>/dev/null || true
if [ -n "$DA_USER" ]; then
    chown "$DA_USER:$DA_USER" "$SELYNT_DATA" 2>/dev/null || true
fi
chmod 711 "$SELYNT_DATA" 2>/dev/null || true
info "State dir: $SELYNT_DATA"

# ── Configurar OLS (template, extProcessors, cron) ──
OLS_SETUP="$PLUGIN_DIR/scripts/setup-ols.sh"
if [ -f "$OLS_SETUP" ] && [ -d /usr/local/lsws ]; then
    "$OLS_SETUP" 2>&1 || warn "Configuração do OLS falhou (verifique manualmente)"
fi

step "Permissões"

# ── Permissões (root:root 755) ──
find "$PLUGIN_DIR" -type d -exec chmod 755 {} \; 2>/dev/null || true
find "$PLUGIN_DIR" -type f -exec chmod 755 {} \; 2>/dev/null || true

# Binário: setuid root (4755)
if [ -f "$BIN" ]; then
    chown root:root "$BIN"  2>/dev/null || true
    chmod 4755 "$BIN"       2>/dev/null || true
    ok "Binário Core Selynt (setuid root)"
else
    warn "Compile o Core Selynt e copie para: $BIN"
fi

# ── Limpar cache do DA (recarrega menus) ──
echo "action=cache&value=showall" >> /usr/local/directadmin/data/task.queue 2>/dev/null || true

printf "\n${G}${BOLD}  ✓ Selynt Panel instalado!${N}\n\n"
exit 0
