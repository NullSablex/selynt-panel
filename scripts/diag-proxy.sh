#!/bin/bash
# diag-proxy.sh — Diagnóstico do proxy Selynt Panel no OLS.
# Execute como root: bash /usr/local/directadmin/plugins/selynt_panel/scripts/diag-proxy.sh
set -u

R="\033[0;31m"; G="\033[0;32m"; Y="\033[0;33m"; N="\033[0m"
ok()   { printf "${G}[OK]${N}   %s\n" "$1"; }
fail() { printf "${R}[FAIL]${N} %s\n" "$1"; }
warn() { printf "${Y}[WARN]${N} %s\n" "$1"; }
info() { printf "       %s\n" "$1"; }

echo "=== Selynt Panel — Diagnóstico de Proxy ==="
echo ""

# 1. Templates DA
echo "── Templates DA ──"
TPL_DIR="/usr/local/directadmin/data/templates/custom"

for f in openlitespeed_vhost.conf.CUSTOM.5.pre openlitespeed_vhost.conf.CUSTOM.7.pre; do
    if [ -f "$TPL_DIR/$f" ]; then
        ok "$f existe"
        if grep -q "SELYNT_PANEL" "$TPL_DIR/$f" 2>/dev/null; then
            ok "  Contém bloco SELYNT_PANEL"
        else
            fail "  NÃO contém bloco SELYNT_PANEL"
        fi
    else
        fail "$f NÃO existe em $TPL_DIR/"
        info "Execute: bash /usr/local/directadmin/plugins/selynt_panel/scripts/setup-ols.sh"
    fi
done

# 2. Vhost gerado
echo ""
echo "── Vhost gerado ──"
VHOST_DIR="/usr/local/lsws/conf/vhosts"
if [ -d "$VHOST_DIR" ]; then
    # Pegar o primeiro vhost como amostra
    SAMPLE=""
    for vh in "$VHOST_DIR"/*/vhost.conf; do
        [ -f "$vh" ] && SAMPLE="$vh" && break
    done
    if [ -z "$SAMPLE" ]; then
        for vh in "$VHOST_DIR"/*.conf; do
            [ -f "$vh" ] && SAMPLE="$vh" && break
        done
    fi

    if [ -n "$SAMPLE" ]; then
        info "Amostra: $SAMPLE"
        if grep -q "selynt_proxy" "$SAMPLE" 2>/dev/null; then
            ok "Vhost contém extProcessor selynt_proxy"
        else
            fail "Vhost NÃO contém extProcessor selynt_proxy"
            info "Os templates não foram aplicados. Execute:"
            info "  cd /usr/local/directadmin/custombuild && ./build rewrite_confs"
        fi
        if grep -q "selynt_panel" "$SAMPLE" 2>/dev/null; then
            ok "Vhost contém rewrite rules selynt_panel"
        else
            fail "Vhost NÃO contém rewrite rules"
        fi
    else
        warn "Nenhum arquivo de vhost encontrado em $VHOST_DIR/"
    fi
else
    # DA pode gerar vhosts em outro local
    warn "Diretório $VHOST_DIR/ não encontrado"
    # Tentar buscar em /usr/local/lsws/conf/httpd_config.conf
    if [ -f /usr/local/lsws/conf/httpd_config.conf ]; then
        info "Procurando vhosts no httpd_config.conf..."
        VH_COUNT=$(grep -c "virtualHost" /usr/local/lsws/conf/httpd_config.conf 2>/dev/null || echo 0)
        info "  virtualHost encontrados: $VH_COUNT"

        if grep -q "selynt_proxy" /usr/local/lsws/conf/httpd_config.conf 2>/dev/null; then
            ok "httpd_config.conf contém referência selynt_proxy"
        else
            warn "httpd_config.conf NÃO contém selynt_proxy"
        fi
    fi
fi

# 2b. Procurar vhosts gerados pelo DA em outro local
DA_VHOST_DIR="/usr/local/directadmin/data/users"
if [ -d "$DA_VHOST_DIR" ]; then
    echo ""
    echo "── Configs OLS geradas pelo DA ──"
    FOUND_OLS=0
    for udir in "$DA_VHOST_DIR"/*/; do
        [ -d "$udir" ] || continue
        user="$(basename "$udir")"
        for ols_conf in "$udir"openlitespeed.conf "$udir"domains/*/openlitespeed*.conf; do
            [ -f "$ols_conf" ] || continue
            FOUND_OLS=1
            if grep -q "selynt_proxy" "$ols_conf" 2>/dev/null; then
                ok "[$user] $(basename "$ols_conf") contém selynt_proxy"
            fi
            break 2
        done
    done
    if [ "$FOUND_OLS" -eq 0 ]; then
        info "Nenhum config OLS encontrado em DA users dir"
    fi
fi

# 3. State dirs e apps ativos
echo ""
echo "── Apps e state dirs ──"
STATE_BASE="/var/lib/selynt_panel"
if [ -d "$STATE_BASE" ]; then
    ok "State dir existe: $STATE_BASE"
    info "Permissões: $(stat -c '%a %U:%G' "$STATE_BASE")"

    for udir in "$STATE_BASE"/*/; do
        [ -d "$udir" ] || continue
        user="$(basename "$udir")"
        info ""
        info "User: $user ($(stat -c '%a %U:%G' "$udir"))"

        # Apps registrados
        for app_file in "$udir".run/*.app; do
            [ -f "$app_file" ] || continue
            app="$(basename "$app_file" .app)"
            host="$(grep '^host=' "$app_file" 2>/dev/null | cut -d= -f2-)"
            info "  App: $app (host=$host)"

            # Marker
            marker="$udir.proxy/$host"
            if [ -f "$marker" ]; then
                ok "    Marker: existe ($(stat -c '%a %U:%G' "$marker"))"
            else
                warn "    Marker: NÃO existe (app parado?)"
            fi

            # Socket
            socket="$udir.sockets/$host"
            if [ -S "$socket" ]; then
                ok "    Socket: existe ($(stat -c '%a %U:%G' "$socket"))"
            else
                warn "    Socket: NÃO existe"
            fi

            # PID
            pidfile="$udir.run/$app.pid"
            if [ -f "$pidfile" ]; then
                pid="$(cat "$pidfile")"
                if kill -0 "$pid" 2>/dev/null; then
                    ok "    Processo: PID $pid ativo"
                else
                    fail "    Processo: PID $pid MORTO"
                fi
            else
                info "    PID: sem arquivo (app parado)"
            fi
        done

        # ACL check
        if command -v getfacl >/dev/null 2>&1; then
            proxy_dir="$udir.proxy"
            if [ -d "$proxy_dir" ]; then
                acl="$(getfacl -p "$proxy_dir" 2>/dev/null | grep "user:" | grep -v "user::" || true)"
                if [ -n "$acl" ]; then
                    ok "    ACL em .proxy/: $acl"
                else
                    warn "    ACL em .proxy/: NENHUMA (web server não pode ler marker)"
                fi
            fi
        fi
    done
else
    fail "State dir NÃO existe: $STATE_BASE"
fi

# 4. OLS config
echo ""
echo "── OLS ──"
OLS_MAIN="/usr/local/lsws/conf/httpd_config.conf"
if [ -f "$OLS_MAIN" ]; then
    if grep -q "selynt_extprocessors" "$OLS_MAIN" 2>/dev/null; then
        ok "Include selynt_extprocessors.conf presente no httpd_config.conf"
    else
        warn "Include selynt_extprocessors.conf AUSENTE do httpd_config.conf"
    fi

    SELYNT_CONF="/usr/local/lsws/conf/selynt_extprocessors.conf"
    if [ -f "$SELYNT_CONF" ]; then
        EP_COUNT=$(grep -c "extProcessor" "$SELYNT_CONF" 2>/dev/null || echo 0)
        info "selynt_extprocessors.conf: $EP_COUNT extProcessors definidos"
    fi
fi

# OLS web user
WEB_USER_FILE="/usr/local/directadmin/plugins/selynt_panel/etc/ols_web_user"
if [ -f "$WEB_USER_FILE" ]; then
    WEB_USER="$(head -n1 "$WEB_USER_FILE" | tr -d '[:space:]')"
    ok "Web user configurado: $WEB_USER"
else
    fail "Web user NÃO configurado"
fi

# OLS error log
echo ""
echo "── Últimas linhas do error log OLS ──"
OLS_ERRLOG="/usr/local/lsws/logs/error.log"
if [ -f "$OLS_ERRLOG" ]; then
    # Mostrar linhas recentes relacionadas a selynt ou proxy
    RELEVANT="$(grep -i "selynt\|proxy\|extprocessor\|rewrite" "$OLS_ERRLOG" 2>/dev/null | tail -10)"
    if [ -n "$RELEVANT" ]; then
        echo "$RELEVANT"
    else
        info "(nenhuma menção a selynt/proxy no error log)"
        info "Últimas 5 linhas:"
        tail -5 "$OLS_ERRLOG" 2>/dev/null
    fi
else
    warn "Log não encontrado: $OLS_ERRLOG"
fi

echo ""
echo "=== Fim do diagnóstico ==="
