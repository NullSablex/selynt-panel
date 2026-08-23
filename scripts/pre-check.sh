#!/bin/sh
# Confere, ANTES de subir o pacote, se a correção de segurança vai reconhecer
# o web user real. Só leitura.
P=/usr/local/directadmin/plugins/selynt_panel
F="$P/etc/ols_web_user"
echo "== etc/ols_web_user =="
if [ -f "$F" ]; then
    ls -la "$F"
    echo "conteudo: [$(cat "$F")]"
else
    echo "AUSENTE: $F"
fi
echo
echo "== quem realmente executa os .raw (dono do processo web) =="
ps -eo user,comm --no-headers | grep -Ei 'httpd|lsphp|litespeed|openlitespeed|nginx|php-fpm' \
  | awk '{print $1}' | sort | uniq -c | sort -rn | head
echo
echo "== veredito =="
W=$(cat "$F" 2>/dev/null | tr -d '[:space:]')
if [ -z "$W" ]; then
    echo "ols_web_user VAZIO -> apache NAO sera 'trusted'."
    echo "   O painel quebraria. Corrigir antes de subir:"
    echo "   printf 'apache\\n' > $F"
else
    echo "ols_web_user = '$W'"
    if id "$W" >/dev/null 2>&1; then
        echo "   usuario existe -> OK, correcao vai reconhecer."
    else
        echo "   usuario NAO existe -> corrigir antes de subir."
    fi
fi
