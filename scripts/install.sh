#!/bin/sh
# Selynt Panel — DirectAdmin Plugin Installer
# SEM set -e: o install do DA nunca pode falhar ou o plugin não será registrado.

PLUGIN_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

echo "Selynt Panel - Instalando..."

# ── Permissões nos arquivos do plugin ──
for dir in user admin hooks; do
    if [ -d "$PLUGIN_DIR/$dir" ]; then
        find "$PLUGIN_DIR/$dir" \( -name "*.html" -o -name "*.raw" \) \
            -exec chmod 755 {} \; 2>/dev/null || true
    fi
done

find "$PLUGIN_DIR/scripts" -name "*.sh" -exec chmod 700 {} \; 2>/dev/null || true
find "$PLUGIN_DIR/hooks"   -name "*.sh" -exec chmod 755 {} \; 2>/dev/null || true

chmod 644 "$PLUGIN_DIR/hooks/user_txt.html"  2>/dev/null || true
chmod 644 "$PLUGIN_DIR/hooks/admin_txt.html" 2>/dev/null || true
chmod 644 "$PLUGIN_DIR/plugin.conf"          2>/dev/null || true
chmod 755 "$PLUGIN_DIR/install.sh" "$PLUGIN_DIR/uninstall.sh" 2>/dev/null || true

# ── Binário core_selynt (setuid root) ──
# O CGI do DA roda como diradmin, não como o user logado.
# O binário precisa de setuid root (4755) para:
#   - Criar dirs de estado em /var/lib/selynt_panel/$username/
#   - Criar logs/ no cwd do app (dentro do home do user)
#   - Drop de privilégio para o user real antes de spawnar apps
BIN="$PLUGIN_DIR/bin/core_selynt"
if [ -f "$BIN" ]; then
    chown root:root "$BIN"  2>/dev/null || true
    chmod 4755 "$BIN"       2>/dev/null || true
    echo "    Binário: OK (setuid root)"
else
    echo "    ATENÇÃO: Compile o núcleo Rust e copie para: $BIN"
fi

# ── Propriedade dos arquivos do plugin (exceto binário) ──
if [ "$(id -u)" -eq 0 ]; then
    if id diradmin >/dev/null 2>&1; then
        chown -R diradmin:diradmin "$PLUGIN_DIR" 2>/dev/null || true
        # Binário DEVE ser root:root 4755 — reaplicar após o chown -R
        if [ -f "$BIN" ]; then
            chown root:root "$BIN" 2>/dev/null || true
            chmod 4755 "$BIN"      2>/dev/null || true
        fi
    fi
fi

# ── Diretório de configuração ──
mkdir -p "$PLUGIN_DIR/etc" 2>/dev/null || true
chmod 755 "$PLUGIN_DIR/etc" 2>/dev/null || true

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
echo "    Usuário DA: $DA_USER${DA_UID:+ (UID $DA_UID)}"
printf "%s\n" "$DA_USER"      > "$PLUGIN_DIR/etc/da_user" 2>/dev/null || true
printf "%s\n" "${DA_UID:-}"   > "$PLUGIN_DIR/etc/da_uid"  2>/dev/null || true
chmod 644 "$PLUGIN_DIR/etc/da_user" "$PLUGIN_DIR/etc/da_uid" 2>/dev/null || true

# ── Detectar usuário do servidor web ──
WEB_USER=""
for u in nobody lsws www-data apache nginx; do
    if id "$u" >/dev/null 2>&1; then
        WEB_USER="$u"
        break
    fi
done
if [ -n "$WEB_USER" ]; then
    printf "%s\n" "$WEB_USER" > "$PLUGIN_DIR/etc/ols_web_user" 2>/dev/null || true
    chmod 644 "$PLUGIN_DIR/etc/ols_web_user" 2>/dev/null || true
    echo "    Usuário web: $WEB_USER"
else
    echo "    [aviso] Usuário do servidor web não detectado."
fi

# ── Logs do plugin (dentro do etc/ do plugin, acessível por diradmin) ──
touch "$PLUGIN_DIR/etc/stderr.log" "$PLUGIN_DIR/etc/debug.log" 2>/dev/null || true
chmod 666 "$PLUGIN_DIR/etc/stderr.log" "$PLUGIN_DIR/etc/debug.log" 2>/dev/null || true
echo "    Logs: $PLUGIN_DIR/etc/"

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
echo "    State dir: $SELYNT_DATA"

# ── Configurar OLS (template, extProcessors, cron) ──
OLS_SETUP="$PLUGIN_DIR/scripts/setup-ols.sh"
if [ -f "$OLS_SETUP" ] && [ -d /usr/local/lsws ]; then
    echo ""
    echo "Configurando OpenLiteSpeed..."
    chmod 700 "$OLS_SETUP" 2>/dev/null || true
    "$OLS_SETUP" 2>&1 || echo "    [aviso] Configuração do OLS falhou (verifique manualmente)."
fi

# ── Limpar cache do DA (recarrega menus) ──
echo "action=cache&value=showall" >> /usr/local/directadmin/data/task.queue 2>/dev/null || true

echo ""
echo "Selynt Panel instalado!"
echo ""
exit 0
