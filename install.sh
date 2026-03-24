#!/bin/bash
# Selynt Panel — Instalação manual via linha de comando.
# Execute como root: bash <(curl -sL https://raw.githubusercontent.com/NullSablex/selynt-panel/master/install.sh)
set -euo pipefail

R="\033[0;31m"; G="\033[0;32m"; Y="\033[0;33m"; B="\033[0;36m"; D="\033[0;90m"; N="\033[0m"; BOLD="\033[1m"
ok()   { printf "${G}  ✓${N} %s\n" "$1"; }
erro() { printf "${R}  ✗${N} %s\n" "$1" >&2; }
warn() { printf "${Y}  ⚠${N} %s\n" "$1"; }
step() { printf "\n${BOLD}${B}── %s ──${N}\n" "$1"; }

PLUGIN_DIR="/usr/local/directadmin/plugins/selynt_panel"
DOWNLOAD_URL="https://nullsablex.com/download/selynt_panel"

printf "\n${BOLD}Selynt Panel${N} — Instalação manual\n"

[ "$(id -u)" -eq 0 ] || { erro "Execute como root."; exit 1; }
command -v directadmin >/dev/null 2>&1 || [ -x /usr/local/directadmin/directadmin ] || { erro "DirectAdmin não encontrado."; exit 1; }

step "Download"
TMP="$(mktemp)"
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$DOWNLOAD_URL" -o "$TMP"
elif command -v wget >/dev/null 2>&1; then
    wget -qO "$TMP" "$DOWNLOAD_URL"
else
    erro "curl ou wget necessário."; exit 1
fi
ok "Pacote baixado"

step "Instalação"
mkdir -p "$PLUGIN_DIR"
tar -xzf "$TMP" -C "$PLUGIN_DIR"
rm -f "$TMP"
ok "Extraído em $PLUGIN_DIR"

bash "$PLUGIN_DIR/scripts/install.sh"

step "Permissões"
bash "$PLUGIN_DIR/scripts/update.sh"

step "DirectAdmin"
if systemctl restart directadmin 2>/dev/null || service directadmin restart 2>/dev/null; then
    ok "DirectAdmin reiniciado"
else
    warn "Reinicie o DirectAdmin manualmente"
fi

printf "\n${G}${BOLD}  ✓ Selynt Panel instalado com sucesso!${N}\n"
printf "${D}  Acesse: https://seu-servidor:2222/CMD_PLUGINS_ADMIN/selynt_panel${N}\n\n"
