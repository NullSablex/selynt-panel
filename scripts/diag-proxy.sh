#!/bin/bash
# diag-proxy.sh — Diagnóstico completo do proxy Selynt Panel.
# Execute como root: bash /usr/local/directadmin/plugins/selynt_panel/scripts/diag-proxy.sh
set -u

# ── Cores e helpers ──
R="\033[0;31m"; G="\033[0;32m"; Y="\033[0;33m"; B="\033[0;36m"; D="\033[0;90m"; N="\033[0m"; BOLD="\033[1m"
PASS=0; FAILS=0; WARNS=0

ok()   { printf "${G}  ✓${N} %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "${R}  ✗${N} %s\n" "$1"; FAILS=$((FAILS+1)); }
warn() { printf "${Y}  ⚠${N} %s\n" "$1"; WARNS=$((WARNS+1)); }
info() { printf "${D}    %s${N}\n" "$1"; }
section() { printf "\n${BOLD}${B}── %s ──${N}\n" "$1"; }
sep()  { printf "${D}%s${N}\n" "────────────────────────────────────────────────────────"; }

PLUGIN_DIR="/usr/local/directadmin/plugins/selynt_panel"
STATE_BASE="/var/lib/selynt_panel"
OLS_CONF_DIR="/usr/local/lsws/conf"
OLS_MAIN="$OLS_CONF_DIR/httpd_config.conf"
DA_TPL_DIR="/usr/local/directadmin/data/templates/custom"

printf "\n${BOLD}╔══════════════════════════════════════════════╗${N}\n"
printf "${BOLD}║     Selynt Panel — Diagnóstico de Proxy      ║${N}\n"
printf "${BOLD}╚══════════════════════════════════════════════╝${N}\n"
printf "${D}  %s${N}\n" "$(date '+%Y-%m-%d %H:%M:%S %Z')"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Ambiente"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Root check
if [ "$(id -u)" -eq 0 ]; then
    ok "Executando como root"
else
    warn "Executando como $(whoami) — alguns testes podem ser limitados"
fi

# DirectAdmin
if [ -x /usr/local/directadmin/directadmin ]; then
    DA_VER="$(/usr/local/directadmin/directadmin v 2>/dev/null || echo 'desconhecida')"
    ok "DirectAdmin: $DA_VER"
else
    fail "DirectAdmin não encontrado"
fi

# OpenLiteSpeed / LiteSpeed Enterprise
if command -v lshttpd >/dev/null 2>&1; then
    LS_VER="$(lshttpd -v 2>/dev/null | head -1 || echo 'desconhecida')"
    ok "OLS/LSWS: $LS_VER"
elif [ -d /usr/local/lsws ]; then
    ok "OLS/LSWS: instalado"
else
    fail "OLS/LSWS: não encontrado"
fi

if systemctl is-active lsws >/dev/null 2>&1; then
    ok "Serviço lsws: ativo"
else
    fail "Serviço lsws: NÃO está rodando"
fi

# Plugin
if [ -d "$PLUGIN_DIR" ]; then
    PLUGIN_VER="$(cat "$PLUGIN_DIR/version" 2>/dev/null | tr -d '[:space:]')"
    ok "Plugin instalado: v${PLUGIN_VER:-?}"
else
    fail "Plugin não instalado em $PLUGIN_DIR"
fi

# Binário Core Selynt
BIN="$PLUGIN_DIR/bin/core-selynt"
if [ -x "$BIN" ]; then
    PERMS="$(stat -c '%a %U:%G' "$BIN" 2>/dev/null)"
    if stat -c '%a' "$BIN" 2>/dev/null | grep -q '^4'; then
        ok "Binário Core Selynt: OK (setuid, $PERMS)"
    else
        fail "Binário Core Selynt: sem setuid ($PERMS) — esperado 4755 root:root"
    fi
    CORE_VER="$("$BIN" version 2>/dev/null || echo '')"
    [ -n "$CORE_VER" ] && info "Versão: $CORE_VER"
else
    fail "Binário Core Selynt NÃO encontrado: $BIN"
fi

# PHP CLI
if command -v php >/dev/null 2>&1; then
    PHP_VER="$(php -v 2>/dev/null | head -1)"
    ok "PHP CLI: $PHP_VER"
else
    fail "PHP CLI não encontrado"
fi

# Node.js
if command -v node >/dev/null 2>&1; then
    NODE_VER="$(node --version 2>/dev/null)"
    NODE_MAJOR="${NODE_VER#v}"; NODE_MAJOR="${NODE_MAJOR%%.*}"
    NODE_MINOR="${NODE_VER#*.}"; NODE_MINOR="${NODE_MINOR%%.*}"
    if [ "$NODE_MAJOR" -gt 20 ] 2>/dev/null || { [ "$NODE_MAJOR" -eq 20 ] && [ "$NODE_MINOR" -ge 6 ]; } 2>/dev/null; then
        ok "Node.js: $NODE_VER (≥ 20.6 requerido)"
    else
        fail "Node.js: $NODE_VER (< 20.6 — incompatível com --import loader)"
    fi
else
    warn "Node.js não encontrado no PATH"
fi

# Versões configuradas
NV_FILE="$PLUGIN_DIR/etc/node_versions"
if [ -f "$NV_FILE" ]; then
    NV_COUNT="$(wc -l < "$NV_FILE" | tr -d '[:space:]')"
    ok "Versões Node.js configuradas: $NV_COUNT"
    while IFS= read -r line; do
        path="$(echo "$line" | awk '{print $1}')"
        ver="$(echo "$line" | awk '{print $2}')"
        if [ -x "$path" ]; then
            info "$ver → $path"
        else
            warn "$ver → $path (NÃO EXISTE)"
        fi
    done < "$NV_FILE"
else
    info "Nenhuma versão Node.js configurada (usa padrão do sistema)"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Templates DirectAdmin"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

for f in openlitespeed_vhost.conf.CUSTOM.7.pre openlitespeed_vhost.conf.CUSTOM.5.pre; do
    TPL="$DA_TPL_DIR/$f"
    if [ -f "$TPL" ]; then
        if grep -q "SELYNT_PANEL" "$TPL" 2>/dev/null; then
            ok "$f — bloco SELYNT_PANEL presente"
            # Verificar conteúdo esperado
            case "$f" in
                *.7.pre)
                    grep -q "extprocessor.*selynt_proxy" "$TPL" 2>/dev/null \
                        && info "extProcessor definido: selynt_proxy-|SDOMAIN|-|VH_PORT|" \
                        || warn "extProcessor NÃO encontrado dentro do template"
                    grep -q "uds://" "$TPL" 2>/dev/null \
                        && info "Endereço: Unix socket (uds://)" \
                        || warn "Endereço uds:// NÃO encontrado"
                    ;;
                *.5.pre)
                    grep -q "RewriteCond.*\.proxy" "$TPL" 2>/dev/null \
                        && info "RewriteCond: verifica marker .proxy/|SDOMAIN|" \
                        || warn "RewriteCond .proxy NÃO encontrado"
                    grep -q "RewriteRule.*selynt_proxy" "$TPL" 2>/dev/null \
                        && info "RewriteRule: proxy para selynt_proxy-|SDOMAIN|-|VH_PORT|" \
                        || warn "RewriteRule selynt_proxy NÃO encontrado"
                    ;;
            esac
        else
            fail "$f existe mas NÃO contém bloco SELYNT_PANEL"
        fi
    else
        fail "$f NÃO existe"
        info "Corrija: bash $PLUGIN_DIR/scripts/setup-ols.sh"
    fi
done

# Templates antigos (versões anteriores usavam nomes errados)
for old in "$DA_TPL_DIR"/cust_openlitespeed.CUSTOM.*.pre; do
    [ -f "$old" ] || continue
    warn "Template antigo encontrado: $(basename "$old") — remover manualmente"
done

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Vhosts Gerados"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

VHOST_CHECKED=0
VHOST_WITH_PROXY=0
VHOST_WITHOUT_PROXY=0
VHOST_DIRS=("/usr/local/lsws/conf/vhosts" "/usr/local/directadmin/data/users")

for vdir in "${VHOST_DIRS[@]}"; do
    [ -d "$vdir" ] || continue
    while IFS= read -r vconf; do
        [ -f "$vconf" ] || continue
        VHOST_CHECKED=$((VHOST_CHECKED+1))
        if grep -q "selynt_proxy" "$vconf" 2>/dev/null; then
            VHOST_WITH_PROXY=$((VHOST_WITH_PROXY+1))
        else
            VHOST_WITHOUT_PROXY=$((VHOST_WITHOUT_PROXY+1))
        fi
    done < <(find "$vdir" -name "*.conf" -path "*openlitespeed*" -o -name "vhost.conf" 2>/dev/null | head -50)
done

if [ "$VHOST_CHECKED" -gt 0 ]; then
    ok "Vhosts analisados: $VHOST_CHECKED"
    if [ "$VHOST_WITH_PROXY" -gt 0 ]; then
        ok "  Com selynt_proxy: $VHOST_WITH_PROXY"
    fi
    if [ "$VHOST_WITHOUT_PROXY" -gt 0 ]; then
        info "  Sem selynt_proxy: $VHOST_WITHOUT_PROXY (normal se templates recém-instalados)"
    fi
    if [ "$VHOST_WITH_PROXY" -eq 0 ]; then
        warn "Nenhum vhost contém selynt_proxy — rebuild necessário"
        info "Corrija: cd /usr/local/directadmin/custombuild && ./build rewrite_confs"
    fi
else
    warn "Nenhum vhost encontrado para análise"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Configuração do OLS/LSWS"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Web user
WEB_USER_FILE="$PLUGIN_DIR/etc/ols_web_user"
if [ -f "$WEB_USER_FILE" ]; then
    WEB_USER="$(head -n1 "$WEB_USER_FILE" | tr -d '[:space:]')"
    if [ -n "$WEB_USER" ]; then
        if id "$WEB_USER" >/dev/null 2>&1; then
            ok "Web user: $WEB_USER (existe no sistema)"
        else
            fail "Web user: $WEB_USER (NÃO existe no sistema)"
        fi
    else
        fail "Arquivo ols_web_user vazio"
    fi
else
    fail "Web user NÃO configurado — $WEB_USER_FILE não existe"
    info "Corrija: bash $PLUGIN_DIR/scripts/setup-ols.sh"
fi

# DA user
DA_USER_FILE="$PLUGIN_DIR/etc/da_user"
if [ -f "$DA_USER_FILE" ]; then
    DA_USER="$(head -n1 "$DA_USER_FILE" | tr -d '[:space:]')"
    ok "DA user: $DA_USER"
else
    warn "Arquivo da_user não encontrado"
fi

# selynt_extprocessors.conf (gerado pelo sync)
SELYNT_CONF="$OLS_CONF_DIR/selynt_extprocessors.conf"
if [ -f "$SELYNT_CONF" ]; then
    EP_COUNT=$(grep -c "^extProcessor" "$SELYNT_CONF" 2>/dev/null || echo 0)
    LAST_SYNC="$(head -1 "$SELYNT_CONF" 2>/dev/null | sed 's/.*— //')"
    ok "selynt_extprocessors.conf: $EP_COUNT extProcessors"
    info "Última sincronização: $LAST_SYNC"
else
    info "selynt_extprocessors.conf não existe (criado pelo sync quando há apps ativos)"
fi

# Cron job (instalado no crontab do root)
CRON_FOUND=false
if crontab -l 2>/dev/null | grep -qF "sync-extprocessors.sh"; then
    CRON_FOUND=true
elif crontab -u root -l 2>/dev/null | grep -qF "sync-extprocessors.sh"; then
    CRON_FOUND=true
elif [ -f /var/spool/cron/root ] && grep -qF "sync-extprocessors.sh" /var/spool/cron/root 2>/dev/null; then
    CRON_FOUND=true
elif [ -f /var/spool/cron/crontabs/root ] && grep -qF "sync-extprocessors.sh" /var/spool/cron/crontabs/root 2>/dev/null; then
    CRON_FOUND=true
fi
if $CRON_FOUND; then
    ok "Cron job: presente"
else
    fail "Cron job: AUSENTE"
    info "Corrija: bash $PLUGIN_DIR/scripts/setup-ols.sh"
fi

# Sync needed flag
if [ -f "$STATE_BASE/.sync_needed" ]; then
    warn "Flag .sync_needed presente — sync pendente (cron executará em breve)"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "State Dir e Aplicações"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TOTAL_APPS=0
RUNNING_APPS=0
STOPPED_APPS=0
ORPHAN_PIDS=0

if [ -d "$STATE_BASE" ]; then
    STATE_PERMS="$(stat -c '%a %U:%G' "$STATE_BASE")"
    STATE_MODE="$(stat -c '%a' "$STATE_BASE")"
    if [ "$STATE_MODE" = "711" ]; then
        ok "State dir: $STATE_BASE ($STATE_PERMS)"
    else
        warn "State dir: $STATE_BASE ($STATE_PERMS) — esperado 711"
    fi

    for udir in "$STATE_BASE"/*/; do
        [ -d "$udir" ] || continue
        user="$(basename "$udir")"
        USER_APPS=0

        for app_file in "$udir".run/*.app; do
            [ -f "$app_file" ] || continue
            TOTAL_APPS=$((TOTAL_APPS+1))
            USER_APPS=$((USER_APPS+1))
            app="$(basename "$app_file" .app)"
            host="$(grep '^host=' "$app_file" 2>/dev/null | cut -d= -f2- || echo '?')"
            type="$(grep '^type=' "$app_file" 2>/dev/null | cut -d= -f2- || echo '?')"

            # Status
            pidfile="$udir.run/$app.pid"
            marker="$udir.proxy/$host"
            socket="$udir.sockets/$host"
            status="PARADO"
            pid=""

            if [ -f "$pidfile" ]; then
                pid="$(cat "$pidfile" 2>/dev/null)"
                if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                    status="ATIVO"
                    RUNNING_APPS=$((RUNNING_APPS+1))
                else
                    status="MORTO"
                    ORPHAN_PIDS=$((ORPHAN_PIDS+1))
                fi
            else
                STOPPED_APPS=$((STOPPED_APPS+1))
            fi

            # Cor do status
            case "$status" in
                ATIVO) STATUS_FMT="${G}ATIVO${N}" ;;
                MORTO) STATUS_FMT="${R}MORTO${N}" ;;
                *)     STATUS_FMT="${D}PARADO${N}" ;;
            esac

            printf "    ${BOLD}%s${N} [%s] ${D}%s${N} — " "$app" "$type" "$host"
            printf "$STATUS_FMT"
            [ -n "$pid" ] && printf " ${D}(PID %s)${N}" "$pid"
            printf "\n"

            # Detalhes do app
            if [ "$status" = "ATIVO" ]; then
                # Socket
                if [ -S "$socket" ]; then
                    SOCK_PERMS="$(stat -c '%a %U:%G' "$socket" 2>/dev/null)"
                    ok "      Socket: $SOCK_PERMS"
                    # ACL check
                    if command -v getfacl >/dev/null 2>&1 && [ -n "${WEB_USER:-}" ]; then
                        if getfacl -p "$socket" 2>/dev/null | grep -q "user:${WEB_USER}:rw"; then
                            ok "      ACL: $WEB_USER tem acesso rw"
                        else
                            fail "      ACL: $WEB_USER NÃO tem acesso ao socket"
                            info "      Corrija: setfacl -m u:${WEB_USER}:rw- $socket"
                        fi
                    fi
                else
                    fail "      Socket NÃO existe: $socket"
                fi

                # Marker
                if [ -f "$marker" ]; then
                    ok "      Marker: presente"
                else
                    fail "      Marker NÃO existe — proxy inativo mesmo com app rodando"
                fi

                # Conexão ao socket (teste real)
                if [ -S "$socket" ] && command -v curl >/dev/null 2>&1; then
                    HTTP_CODE="$(curl -s -o /dev/null -w '%{http_code}' --unix-socket "$socket" http://localhost/ --max-time 3 2>/dev/null || echo '000')"
                    if [ "$HTTP_CODE" != "000" ]; then
                        ok "      Resposta via socket: HTTP $HTTP_CODE"
                    else
                        warn "      Socket não respondeu (app pode não estar ouvindo ainda)"
                    fi
                fi
            elif [ "$status" = "MORTO" ]; then
                fail "      PID $pid não está ativo — pidfile órfão"
                info "      Corrija: inicie o app ou limpe com 'rm $pidfile'"
            fi
        done

        if [ "$USER_APPS" -gt 0 ]; then
            # ACL nos diretórios do user
            if command -v getfacl >/dev/null 2>&1 && [ -n "${WEB_USER:-}" ]; then
                for subdir in .sockets .proxy; do
                    dir="$udir$subdir"
                    [ -d "$dir" ] || continue
                    if getfacl -p "$dir" 2>/dev/null | grep -q "user:${WEB_USER}"; then
                        ok "    ACL [$user/$subdir]: $WEB_USER configurado"
                    else
                        warn "    ACL [$user/$subdir]: $WEB_USER SEM acesso"
                        info "    Corrija: setfacl -m u:${WEB_USER}:--x $dir"
                    fi
                done
            fi
        fi

        [ "$USER_APPS" -eq 0 ] && info "  [$user] nenhum app registrado"
    done

    sep
    printf "    ${BOLD}Total:${N} %d apps — ${G}%d ativos${N}, ${D}%d parados${N}" "$TOTAL_APPS" "$RUNNING_APPS" "$STOPPED_APPS"
    [ "$ORPHAN_PIDS" -gt 0 ] && printf ", ${R}%d mortos${N}" "$ORPHAN_PIDS"
    printf "\n"
else
    fail "State dir NÃO existe: $STATE_BASE"
    info "Corrija: bash $PLUGIN_DIR/scripts/install.sh"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Permissões do Plugin"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [ -d "$PLUGIN_DIR" ]; then
    # plugin.conf: DA reescreve com 600, corrigir para 644 (diradmin precisa ler)
    PC="$PLUGIN_DIR/plugin.conf"
    if [ -f "$PC" ]; then
        PC_PERMS="$(stat -c '%a' "$PC")"
        if [ "$PC_PERMS" = "600" ]; then
            if chmod 644 "$PC" 2>/dev/null; then
                ok "plugin.conf: corrigido 600 → 644"
            else
                fail "plugin.conf: $PC_PERMS (DA não consegue ler, requer root para corrigir)"
            fi
        else
            ok "plugin.conf: $PC_PERMS"
        fi
    fi

    # Demais arquivos devem ser 755, exceto binário (4755) e plugin.conf
    # Auto-corrige quando possível
    BAD_PERMS=0
    FIXED=0
    while IFS= read -r f; do
        [ "$f" = "$BIN" ] && continue
        [ "$f" = "$PC" ] && continue
        FPERMS="$(stat -c '%a' "$f" 2>/dev/null)"
        if [ "$FPERMS" != "755" ]; then
            if chmod 755 "$f" 2>/dev/null; then
                FIXED=$((FIXED+1))
            else
                BAD_PERMS=$((BAD_PERMS+1))
                info "  $FPERMS → $(echo "$f" | sed "s|$PLUGIN_DIR/||")"
            fi
        fi
    done < <(find "$PLUGIN_DIR" -type f 2>/dev/null)
    [ "$FIXED" -gt 0 ] && ok "Permissões corrigidas: $FIXED arquivos"
    [ "$BAD_PERMS" -eq 0 ] && ok "Arquivos do plugin: todos 755" || fail "Permissões: $BAD_PERMS arquivos não são 755 (requer root)"

    # Hook presente
    if [ -f "$PLUGIN_DIR/hooks/user_httpd_write_post.sh" ]; then
        ok "Hook user_httpd_write_post.sh: presente"
    else
        fail "Hook user_httpd_write_post.sh NÃO existe"
    fi

    # node-loader.js
    if [ -f "$PLUGIN_DIR/lib/node-loader.js" ]; then
        ok "node-loader.js: presente"
    else
        fail "node-loader.js NÃO encontrado"
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Logs Recentes"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# OLS error log (DA usa /var/log/openlitespeed/error_log)
OLS_ERRLOG="/var/log/openlitespeed/error_log"
if [ -f "$OLS_ERRLOG" ]; then
    RELEVANT="$(grep -i "selynt\|proxy\|extprocessor\|rewrite\|uds://" "$OLS_ERRLOG" 2>/dev/null | tail -10)"
    if [ -n "$RELEVANT" ]; then
        warn "Entradas relevantes no error log do OLS:"
        echo "$RELEVANT" | while IFS= read -r line; do
            printf "    ${D}%s${N}\n" "$line"
        done
    else
        ok "Nenhuma menção a selynt/proxy no error log do OLS"
    fi
else
    info "Log do OLS não encontrado: $OLS_ERRLOG"
fi

# Plugin stderr log
PLUGIN_ERR="$PLUGIN_DIR/etc/stderr.log"
if [ -f "$PLUGIN_ERR" ] && [ -s "$PLUGIN_ERR" ]; then
    LINES="$(wc -l < "$PLUGIN_ERR" | tr -d '[:space:]')"
    warn "stderr.log do plugin: $LINES linhas"
    tail -5 "$PLUGIN_ERR" | while IFS= read -r line; do
        printf "    ${D}%s${N}\n" "$line"
    done
else
    ok "stderr.log do plugin: limpo"
fi

# DirectAdmin error log (últimas 24h)
DA_ERRLOG="/var/log/directadmin/error.log"
if [ -f "$DA_ERRLOG" ]; then
    TODAY="$(date '+%Y:%m:%d')"
    YESTERDAY="$(date -d '1 day ago' '+%Y:%m:%d' 2>/dev/null || date -v-1d '+%Y:%m:%d' 2>/dev/null || echo '')"
    DA_RELEVANT="$(grep -i "selynt_panel\|timeout.*plugin" "$DA_ERRLOG" 2>/dev/null | grep -E "^($TODAY|$YESTERDAY)" 2>/dev/null | sed 's/<[^>]*>//g' | tail -5)"
    if [ -n "$DA_RELEVANT" ]; then
        warn "Entradas recentes do selynt_panel no log do DirectAdmin:"
        echo "$DA_RELEVANT" | while IFS= read -r line; do
            printf "    ${D}%s${N}\n" "$line"
        done
    else
        ok "Nenhum erro recente do selynt_panel no log do DirectAdmin"
    fi
fi

# journald (últimos 10 minutos)
if command -v journalctl >/dev/null 2>&1; then
    JOURNAL="$(journalctl -u directadmin --since '10 min ago' --no-pager -q 2>/dev/null | grep -i "selynt\|timeout.*plugin" | tail -5)"
    if [ -n "$JOURNAL" ]; then
        warn "Entradas recentes no journald (últimos 10 min):"
        echo "$JOURNAL" | while IFS= read -r line; do
            printf "    ${D}%s${N}\n" "$line"
        done
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Conectividade (teste rápido)"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if command -v curl >/dev/null 2>&1; then
    # Teste acesso local ao DA
    DA_PORT="$(grep '^port=' /usr/local/directadmin/conf/directadmin.conf 2>/dev/null | cut -d= -f2 | tr -d '[:space:]')"
    DA_PORT="${DA_PORT:-2222}"
    HTTP_CODE="$(curl -sk -o /dev/null -w '%{http_code}' "https://127.0.0.1:${DA_PORT}/CMD_PLUGINS/selynt_panel" --max-time 5 2>/dev/null || echo '000')"
    case "$HTTP_CODE" in
        200|301|302) ok "Acesso ao plugin via DA: HTTP $HTTP_CODE" ;;
        401|403)     ok "Plugin acessível (requer autenticação): HTTP $HTTP_CODE" ;;
        000)         warn "Não foi possível conectar ao DA na porta $DA_PORT" ;;
        *)           warn "Resposta inesperada do DA: HTTP $HTTP_CODE" ;;
    esac
else
    info "curl não disponível — teste de conectividade ignorado"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Resumo
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

printf "\n${BOLD}╔══════════════════════════════════════════════╗${N}\n"
printf "${BOLD}║                   Resumo                     ║${N}\n"
printf "${BOLD}╚══════════════════════════════════════════════╝${N}\n"
printf "  ${G}✓ %d passou${N}  ${Y}⚠ %d avisos${N}  ${R}✗ %d falhas${N}\n" "$PASS" "$WARNS" "$FAILS"

if [ "$FAILS" -gt 0 ]; then
    printf "\n  ${R}${BOLD}Ação necessária:${N} corrija os itens marcados com ✗ acima.\n"
    printf "  ${D}Comandos comuns:${N}\n"
    printf "    ${D}bash %s/scripts/setup-ols.sh${N}   — reconfigurar templates e cron\n" "$PLUGIN_DIR"
    printf "    ${D}cd /usr/local/directadmin/custombuild && ./build rewrite_confs${N}   — reaplicar templates\n"
    printf "    ${D}systemctl restart lsws${N}   — reiniciar OLS/LSWS\n"
elif [ "$WARNS" -gt 0 ]; then
    printf "\n  ${Y}Verifique os avisos acima. Podem indicar configuração incompleta.${N}\n"
else
    printf "\n  ${G}${BOLD}Tudo OK!${N} Nenhum problema encontrado.\n"
fi

printf "\n"
exit 0
