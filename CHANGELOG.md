# Changelog

## [1.1.0] — 2026-03-24

### Adicionado
- **Uptime dos apps** — exibe há quanto tempo cada app está ativo, tanto na visão geral do admin quanto na página individual do usuário.
- **Diagnóstico no painel admin** — botão "Executar Diagnóstico" na página de configurações que roda verificações de templates, vhosts, permissões, sockets, ACLs e logs.
- **Diagnóstico completo** (`diag-proxy.sh`) — reescrita total com seções: ambiente, templates, vhosts, configuração do LiteSpeed, estado dos apps (inclui teste de socket), permissões, logs, conectividade e resumo com contadores.
- Validação de tipo na criação de apps.

### Corrigido
- **Segurança XSS** — função `esc()` unificada em todas as páginas com escape dos 5 caracteres (`& < > " '`).
- **CI: verificação PHP** — corrigido bug de subshell onde erros de sintaxe PHP nunca falhavam o pipeline.
- **update.sh: setuid destruído** — `chown -R diradmin:diradmin` sobrescrevia permissões do binário; agora reaplica `root:root 4755` após o chown.
- **install.sh: chmod contraditório** — removido `chmod 700` duplicado que era sobrescrito por `chmod 755`.
- **install.sh: ordem de detecção do web user** — reordenado para priorizar `lsws` sobre `nobody`.
- **plugin.conf: campo inválido** — removido `description` que não é reconhecido pelo DirectAdmin e potencialmente causava erro de parsing.
- **common.php: stream_get_contents** — adicionada verificação de retorno `false`.

### Alterado
- README reescrito com documentação profissional: arquitetura, fluxo de proxy, segurança, empacotamento e CI/CD.

## [1.0.0] — Versão inicial

- Gerenciamento de apps via DirectAdmin.
- Binário Core Selynt com setuid para operações privilegiadas.
- Proxy reverso via templates OpenLiteSpeed/LiteSpeed Enterprise.
- Painel admin com visão geral de todos os apps do servidor.
- Painel do usuário com criação, controle e logs de apps.
- Seleção de runtime e versão por app.
- CI/CD com GitHub Actions (lint PHP, ShellCheck, build CSS/JS).
