# Changelog

## [1.2.0]

### Segurança
- **Binário Core Selynt atualizado com correções de segurança** — escalação de privilégio via `USERNAME`, comandos `admin` sem autenticação, execução de código como root via `NVM_DIR`, controle cruzado de apps via `SELYNT_STATE_DIR`, e destruição de dados via symlink no `cwd` (o `remove --delete-dir` apagava o conteúdo do alvo do link). Todas exploráveis por qualquer conta local em servidor compartilhado. Detalhes no changelog do `core-selynt`.

### Corrigido
- **Troca de idioma não funcionava** — o seletor era o único ponto do painel a enviar JSON no corpo do POST; sob o CGI do DirectAdmin o corpo não chegava ao PHP, então o código de idioma chegava vazio ao binário. O admin exibia "Invalid language." e o usuário não via retorno algum. `langModal()` passa a enviar por query string, como os demais endpoints.
- **Modal de idioma travado após erro** — o tratamento de falha apenas reabilitava os botões, deixando o modal aberto sobre um toast que passava despercebido; agora o modal fecha antes de exibir o erro.
- **Mensagem de erro vazia era mantida** — `$res['message'] ?? …` só substitui quando a chave não existe, e o binário retornava `message` presente porém vazia; a checagem passa a considerar string vazia. Vale para `user/api/locale.raw` e `admin/api/config.raw`.
- **Código de idioma inválido chegava ao binário** — ambos os endpoints agora validam contra os dicionários de `lib/i18n/` antes de invocar o binário; string vazia segue válida (limpa a preferência).
- **Logs de aplicação ilegíveis** — sequências ANSI gravadas pelos apps apareciam como `[2m`, `[0m` no visualizador; o binário passa a removê-las na leitura.
- **Seletor de versão do Node.js com aparência do sistema** — o estilo `.inline-select` perdia em especificidade para a regra genérica `.selynt-panel select` (0,1,0 contra 0,1,1), então o `<select>` mantinha seta e fundo nativos, destoando do restante do painel. Regra reescopada, com seta própria e estados de hover/foco.
- **Seletor exibido sem alternativas** — quando o admin não configurou runtimes, `nodes.raw` devolve uma entrada de fallback com `path` vazio (o Node do sistema). Ela era contada como opção, produzindo um seletor de um único item que, ao confirmar, falhava com "Campo node_version é obrigatório". Entradas sem `path` passam a ser rótulo, não opção.
- **Botão de confirmar sempre aceso** — o botão ao lado do seletor fazia a linha parecer pendente mesmo sem alteração; agora só ativa quando a versão escolhida difere da atual.
- **Apps não voltavam após reiniciar o servidor** — os apps herdavam o cgroup de quem os iniciava, então o systemd os encerrava junto com a unidade `oneshot` de recuperação: subiam e morriam no mesmo instante, com o log registrando sucesso. Cada app passa a rodar em escopo systemd próprio (correção no `core-selynt`), e o `selynt-panel.service` ganhou `KillMode=process`. Apps que estavam rodando voltam sozinhos; os que o usuário parou continuam parados.
- **Aplicação em execução sumia do painel** — a tabela de destaque ordenava apenas por data de criação, então bastavam cinco apps mais novos para esconder um app ativo. Agora aplicações em execução vêm primeiro, e a data desempata.
- **Diálogo de remoção não dizia o que seria apagado** — o texto perguntava apenas "Deseja excluir os arquivos do app também?", sem deixar claro que excluir remove a pasta inteira, `.env` incluído. Cada opção agora descreve o efeito real.

### Alterado
- **Painel deixa de ser embutido na skin do DirectAdmin** — as entradas de menu passam a apontar direto para as páginas do plugin, sem o wrapper `?src=%2F…` da Evolution. Com isso cada página tem URL própria: recarregar a página de um app mantém o app aberto, em vez de voltar ao início. Um link "Voltar ao DirectAdmin" foi adicionado ao cabeçalho, já que o menu lateral da skin não está mais presente.
- **Coluna "Tipo" removida da tabela** — o ícone do runtime passou a acompanhar o nome da aplicação, que já o identifica.
- **`install.sh` não reporta mais sucesso falso no setuid** — `chmod 4755` com `2>/dev/null || true` imprimia "setuid root applied" mesmo em caso de falha, escondendo a causa de todo comando privilegiado falhar com `root_required`.

### Adicionado
- **Painel (dashboard) do usuário** — nova página inicial com total de aplicações, online, offline, memória em uso e uma tabela das aplicações em destaque. A listagem completa passou para `apps.html`, e o menu do DirectAdmin ganhou as duas entradas.
- **Paginação na lista de aplicações** — 9 por página, com janela deslizante e elipse quando há muitas páginas, além do contador "Exibindo X–Y de Z". Feita no cliente: a lista já vem inteira em uma requisição.
- **Consumo de CPU e memória por app** — exibido nos cards da lista do usuário e em duas colunas novas na visão geral do admin. Quando a conta tem limite configurado no DirectAdmin (`MemoryMax`/`CPUQuota`), o valor aparece como "usado / limite" com barra de progresso que muda de cor em 70% e 90%; sem limite, mostra o valor absoluto. Layout reaproveitado do desenho anterior do painel.
- **`scripts/pre-check.sh`** — verifica, antes de instalar, se `etc/ols_web_user` está correto; relevante porque a resolução de usuário do binário depende dele.

## [1.1.2] — 2026-03-29

### Alterado
- Atualização do binário Core Selynt.

## [1.1.1] — 2026-03-29

### Corrigido
- **config.html: seção Node.js oculta por padrão** — card "Versões do Node.js" agora só aparece se o binário Core Selynt suportar detecção de Node.js; binários Rust não exibem a seção.
- **create.html: campo de versão Node.js visível com Rust** — ao selecionar "Binário Rust" como tipo de app, o campo de versão Node.js agora é ocultado corretamente.
- **release.yml: falso positivo no verify** — regex `install\.sh` casava com `uninstall.sh`; ancoragem corrigida para excluir apenas o instalador raiz.

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
