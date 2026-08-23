#!/bin/sh
# deploy-remote.sh — Envia e instala o pacote no servidor.
#
# O endereço do servidor NUNCA aparece aqui: usa-se um alias definido em
# ~/.ssh/config (por padrão `selynt-srv`), que só você mantém.
#
#   Host selynt-srv
#       HostName <ip>
#       User root
#       IdentityFile ~/.ssh/sua_chave
#
# Uso:
#   sh scripts/deploy-remote.sh                 # envia + instala
#   sh scripts/deploy-remote.sh --check         # só o pre-check, não instala
#   SELYNT_HOST=outro-alias sh scripts/deploy-remote.sh
set -eu

HOST="${SELYNT_HOST:-selynt-srv}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$(cd "$ROOT/.." && pwd)/selynt_panel.tar.gz"
# LogLevel=ERROR mantém o hostname fora da saída em operação normal.
SSH="ssh -o LogLevel=ERROR $HOST"

[ -f "$PKG" ] || { echo "pacote não encontrado: $PKG (rode scripts/package.sh)"; exit 1; }

echo "== enviando diagnósticos =="
scp -q -o LogLevel=ERROR "$ROOT/scripts/pre-check.sh" "$ROOT/scripts/diag-locale.sh" "$HOST:/tmp/"

echo "== pre-check (antes de instalar) =="
$SSH "sh /tmp/pre-check.sh"

[ "${1:-}" = "--check" ] && exit 0

printf '\nContinuar com a instalação? [s/N] '
read -r ans
case "$ans" in s|S|y|Y) ;; *) echo "abortado."; exit 0 ;; esac

echo "== enviando pacote =="
scp -q -o LogLevel=ERROR "$PKG" "$HOST:/tmp/selynt_panel.tar.gz"

echo "== instalando =="
$SSH 'set -eu
  P=/usr/local/directadmin/plugins/selynt_panel
  [ -d "$P" ] && cp -a "$P" "/root/selynt_panel.bak.$(date +%s)" && echo "backup criado"
  cd "$P"
  tar -xzf /tmp/selynt_panel.tar.gz
  sh scripts/install.sh
  echo "--- setuid final ---"
  ls -la "$P/bin/core-selynt"'
