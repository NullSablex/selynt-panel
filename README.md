<p align="center">
  <img src="images/assets/img/logo.png" alt="Selynt Panel" width="140">
</p>

<h1 align="center">Selynt Panel</h1>

<p align="center">
  <strong>Gerenciamento de aplicações para DirectAdmin</strong><br>
  Proxy reverso automático via Unix socket com OpenLiteSpeed / LiteSpeed Enterprise
</p>

<p align="center">
  <a href="https://github.com/NullSablex/selynt-panel/actions/workflows/ci.yml"><img src="https://github.com/NullSablex/selynt-panel/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://github.com/NullSablex/selynt-panel/releases/latest"><img src="https://img.shields.io/github/v/release/NullSablex/selynt-panel" alt="Última release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/NullSablex/selynt-panel" alt="Licença"></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/DirectAdmin-plugin-2B5797?logo=cpanel&logoColor=white" alt="DirectAdmin">
  <img src="https://img.shields.io/badge/LiteSpeed-OLS_|_Enterprise-4B8BBE" alt="LiteSpeed">
</p>

> [!CAUTION]
> **Este plugin está em fase inicial de desenvolvimento.** Pode conter falhas, comportamentos inesperados ou instabilidades, especialmente em ambientes de produção ou uso em larga escala. Use por sua conta e risco e reporte problemas via [Issues](https://github.com/NullSablex/selynt-panel/issues).

---

## Visão Geral

O **Selynt Panel** é um plugin para [DirectAdmin](https://www.directadmin.com/) que permite a usuários hospedar e gerenciar aplicações de forma isolada, com proxy reverso automático via Unix socket integrado ao [OpenLiteSpeed](https://openlitespeed.org/) ou LiteSpeed Enterprise.

O núcleo de execução é o binário [Core Selynt](https://github.com/NullSablex/core-selynt), responsável pelo ciclo de vida dos processos, gerenciamento de sockets e isolamento de privilégios.

---

## Funcionalidades

### Painel Administrativo
- Visão geral consolidada de todas as aplicações do servidor
- Configuração do LiteSpeed (templates, extProcessors, cron de sincronização)
- Detecção e seleção de versões de runtime disponíveis no sistema

### Painel do Usuário
- Criação, inicialização, parada, reinício e remoção de aplicações
- Vinculação de aplicações a domínios e subdomínios configurados no DirectAdmin
- Alteração da versão do runtime por aplicação (com o app desligado)
- Visualização de logs em tempo real (stdout e stderr)

---

## Requisitos

| Componente | Versão |
|:---|:---|
| [DirectAdmin](https://www.directadmin.com/) | Qualquer versão com suporte a plugins |
| [OpenLiteSpeed](https://openlitespeed.org/) ou LiteSpeed Enterprise | — |
| PHP CLI | 8.0 ou superior |
| [Core Selynt](https://github.com/NullSablex/core-selynt) | Última versão |

> [!IMPORTANT]
> Compatível exclusivamente com **OpenLiteSpeed** e **LiteSpeed Enterprise**. Apache e Nginx não são suportados.

---

## Instalação

### Via Plugin Manager (recomendado)

No DirectAdmin, acesse **Plugin Manager** e forneça a URL de instalação:

```
https://nullsablex.com/download/selynt_panel
```

### Via linha de comando

Execute como **root**:

```bash
bash <(curl -sL https://raw.githubusercontent.com/NullSablex/selynt-panel/master/install.sh)
```

### O que o instalador configura

- Permissões e setuid do binário Core Selynt
- Templates de vhost do DirectAdmin (extProcessor + rewrite condicional)
- Cron de sincronização de extProcessors
- Diretório de estado em `/var/lib/selynt_panel`

> [!WARNING]
> Após a instalação, o DirectAdmin pode definir permissões restritivas no `plugin.conf`, impedindo a leitura pelo painel. Execute `update.sh` como root para corrigir.

### Pós-instalação e manutenção

Scripts de manutenção e diagnóstico — **executar como root**:

```bash
# Corrigir permissões e configuração
bash /usr/local/directadmin/plugins/selynt_panel/scripts/update.sh

# Reconfigurar templates, cron e servidor web
bash /usr/local/directadmin/plugins/selynt_panel/scripts/setup-ols.sh

# Diagnóstico completo (com auto-correção)
bash /usr/local/directadmin/plugins/selynt_panel/scripts/diag-proxy.sh
```

> [!NOTE]
> O diagnóstico também está disponível no painel administrativo em **Configurações > Diagnóstico**, mas com permissões limitadas. Para resultados completos e auto-correção, execute via SSH como root.

---

## Arquitetura

### Como funciona o proxy

```
Cliente → LiteSpeed → RewriteRule (condicional) → extProcessor → Unix Socket → Aplicação
```

1. **Template CUSTOM.7** — declara um `extProcessor` por vhost, apontando para o socket da aplicação
2. **Template CUSTOM.5** — aplica um `RewriteRule` condicional: se o marker `.proxy/<domínio>` existir, o tráfego é redirecionado ao extProcessor; caso contrário, segue o fluxo normal (PHP, arquivos estáticos, etc.)
3. **Cron** — a cada minuto, verifica se há alterações pendentes e regenera o arquivo de extProcessors com reload graceful do LiteSpeed

### Estrutura do plugin

```
selynt_panel/
├── admin/             Painel administrativo (páginas e API)
├── user/              Painel do usuário (páginas e API)
├── lib/
│   ├── common.php     Utilitários compartilhados (CGI, execução do binário)
│   └── node-loader.js Loader ESM — intercepta rede para Unix sockets
├── bin/               Binário Core Selynt (setuid root)
├── scripts/           Scripts de instalação, configuração e sincronização
├── hooks/             Hooks do DirectAdmin (regeneração de permissões)
├── templates/         Templates para novas aplicações
├── assets-src/        Código-fonte CSS/JS (pré-minificação)
└── images/            Menus JSON e assets compilados
```

### Diretório de estado

```
/var/lib/selynt_panel/<usuário>/
├── .sockets/    Unix sockets das aplicações ativas
├── .proxy/      Markers de proxy (presença = proxy ativo)
├── .run/        PID files dos processos
└── .meta/       Metadados das aplicações
```

---

## Segurança

- **Isolamento de privilégios** — cada aplicação roda sob o UID/GID do respectivo usuário do DirectAdmin
- **Bloqueio de rede** — interceptação de chamadas de rede, impedindo bind direto em portas TCP/UDP
- **Setuid controlado** — o binário Core Selynt opera com setuid root apenas para criar estruturas de estado e realizar drop de privilégio para o usuário real antes de spawnar a aplicação
- **Proxy condicional** — o LiteSpeed só encaminha tráfego se o marker de proxy existir, evitando conflitos com sites estáticos ou PHP

---

## Desenvolvimento

```bash
npm install
npm run build
```

Compila e minifica os arquivos de `assets-src/` via [esbuild](https://esbuild.github.io/), gerando os assets finais em `images/assets/`.

### Empacotamento

```bash
scripts/package.sh
```

Compila o binário Core Selynt (musl, estático) e gera o pacote `selynt_panel.tar.gz` pronto para o Plugin Manager.

### CI/CD

| Workflow | Descrição |
|:---|:---|
| **CI** | Build de assets, validação do `plugin.conf`, sincronia de versão, lint de PHP e Shell |
| **Release** | Gera e publica o pacote `.tar.gz` automaticamente ao criar uma release no GitHub |

---

## Autor

**NullSablex** — [github.com/NullSablex](https://github.com/NullSablex)

## Licença

Distribuído sob a licença [AGPL-3.0-or-later](LICENSE).
