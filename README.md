<p align="center">
  <img src="images/assets/img/logo.png" alt="Selynt Panel" width="140">
</p>

<h1 align="center">Selynt Panel</h1>

<p align="center">
  <strong>Gerenciamento de aplicações para DirectAdmin</strong><br>
  Proxy reverso automático via Unix socket com OpenLiteSpeed
</p>

<p align="center">
  <a href="https://github.com/NullSablex/selynt-panel/actions/workflows/ci.yml"><img src="https://github.com/NullSablex/selynt-panel/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://github.com/NullSablex/selynt-panel/releases/latest"><img src="https://img.shields.io/github/v/release/NullSablex/selynt-panel" alt="Última release"></a>
  <a href="https://scorecard.dev/viewer/?uri=github.com/NullSablex/selynt-panel"><img src="https://api.scorecard.dev/projects/github.com/NullSablex/selynt-panel/badge?style=flat-square" alt="OpenSSF Scorecard"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/NullSablex/selynt-panel" alt="Licença"></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/DirectAdmin-plugin-2B5797?logo=cpanel&logoColor=white" alt="DirectAdmin">
  <img src="https://img.shields.io/badge/OpenLiteSpeed-1.9.2-4B8BBE" alt="OpenLiteSpeed">
</p>

> [!CAUTION]
> **Este plugin está em fase inicial de desenvolvimento.** Pode conter falhas, comportamentos inesperados ou instabilidades, especialmente em ambientes de produção ou uso em larga escala. Use por sua conta e risco e reporte problemas via [Issues](https://github.com/NullSablex/selynt-panel/issues).

---

## Visão Geral

O **Selynt Panel** é um plugin para [DirectAdmin](https://www.directadmin.com/) que permite a usuários hospedar e gerenciar aplicações de forma isolada, com proxy reverso automático via Unix socket integrado ao [OpenLiteSpeed](https://openlitespeed.org/).

O núcleo de execução é o binário [Core Selynt](https://github.com/NullSablex/core-selynt), responsável pelo ciclo de vida dos processos, gerenciamento de sockets e isolamento de privilégios.

---

## Funcionalidades

### Painel Administrativo
- Visão geral consolidada de todas as aplicações do servidor
- Configuração do OpenLiteSpeed (templates e extProcessors)
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
| [DirectAdmin](https://www.directadmin.com/) | 1.708 ou superior |
| [OpenLiteSpeed](https://openlitespeed.org/) | 1.9.2 ou superior |
| PHP CLI | 8.0 ou superior |
| systemd com cgroup v2 | — |
| `setfacl` (pacote `acl`) | — |
| [bubblewrap](https://github.com/containers/bubblewrap) | opcional — apenas para o isolamento entre aplicações |
| [Core Selynt](https://github.com/NullSablex/core-selynt) | Última versão |

> [!NOTE]
> As versões acima são as **testadas**, não um mínimo verificado. Versões anteriores podem funcionar, mas não foram validadas — a documentação do OpenLiteSpeed não indica desde quando as diretivas usadas existem.

> [!IMPORTANT]
> Requer **OpenLiteSpeed** como servidor web. **LiteSpeed Enterprise não é suportado**: ele lê a configuração do Apache, enquanto o painel injeta seus blocos nos templates `openlitespeed_*` do DirectAdmin, que aquele servidor não utiliza. Apache e Nginx também não são suportados — o proxy é montado sobre `extProcessor`, uma diretiva do OpenLiteSpeed.

---

## Instalação

### Via Plugin Manager (recomendado)

No DirectAdmin, acesse **Plugin Manager** e forneça a URL de instalação:

```
https://github.com/NullSablex/selynt-panel/releases/latest/download/selynt_panel.tar.gz
```

### Via linha de comando

Execute como **root**:

```bash
bash <(curl -sL https://raw.githubusercontent.com/NullSablex/selynt-panel/master/install.sh)
```

### O que o instalador configura

- Permissões e setuid do binário Core Selynt
- Templates de vhost do DirectAdmin (extProcessor + rewrite condicional)
- Serviços do systemd: recuperação após reinício, varredura de portas expostas e sincronização do proxy
- Diretório de estado em `/var/lib/selynt_panel`

> [!WARNING]
> Após a instalação, o DirectAdmin pode definir permissões restritivas no `plugin.conf`, impedindo a leitura pelo painel. Execute `update.sh` como root para corrigir.

### Pós-instalação e manutenção

Scripts de manutenção e diagnóstico — **executar como root**:

```bash
# Corrigir permissões e configuração
bash /usr/local/directadmin/plugins/selynt_panel/scripts/update.sh

# Reconfigurar templates e servidor web
/usr/local/directadmin/plugins/selynt_panel/bin/core-selynt setup-ols

# Diagnóstico completo
/usr/local/directadmin/plugins/selynt_panel/bin/core-selynt admin diagnose
```

> [!NOTE]
> O mesmo diagnóstico está no painel administrativo em **Diagnóstico**, com o resultado já traduzido e formatado. Pela linha de comando ele sai como JSON, útil para inspeção ou automação.

---

## Arquitetura

### Como funciona o proxy

```
Cliente → LiteSpeed → RewriteRule (condicional) → extProcessor → Unix Socket → Aplicação
```

1. **Template CUSTOM.7** — declara um `extProcessor` por vhost, apontando para o socket da aplicação
2. **Template CUSTOM.5** — aplica um `RewriteRule` condicional: se o marker `.proxy/<domínio>` existir, o tráfego é redirecionado ao extProcessor; caso contrário, segue o fluxo normal (PHP, arquivos estáticos, etc.)
3. **Sincronização** — quando o conjunto de aplicações ativas muda, o binário regenera o arquivo de extProcessors e recarrega o servidor web. Um timer do systemd verifica a cada poucos segundos se há alteração pendente

### Estrutura do plugin

```
selynt_panel/
├── admin/             Painel administrativo (páginas e API)
├── user/              Painel do usuário (páginas e API)
├── lib/
│   ├── common.php     Utilitários compartilhados (CGI, execução do binário)
│   ├── i18n.php       Tradução das páginas
│   ├── i18n/          Dicionários por idioma
│   └── node-loader.js Loader ESM — intercepta rede para Unix sockets
├── bin/               Binário Core Selynt (setuid root)
├── scripts/           Hooks de instalação do DirectAdmin
├── hooks/             Hooks do DirectAdmin (regeneração de permissões)
├── templates/         Templates para novas aplicações
├── assets-src/        Código-fonte CSS/JS (pré-minificação)
├── tools/             Ferramentas de desenvolvimento (fora do pacote)
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
- **Isolamento entre aplicações da conta** — opcional, por conta, com padrão definido pelo administrador. Ligado, cada aplicação roda sem enxergar arquivos, processos ou sockets das demais
- **Bloqueio de rede** — interceptação de chamadas de rede, impedindo bind direto em portas TCP/UDP. Uma varredura periódica derruba aplicação que exponha porta alcançável de fora; ouvir em `127.0.0.1` continua permitido
- **Nada roda como root fora do binário** — o plugin não executa shell script privilegiado; recuperação de boot, varredura de portas e sincronização do proxy ficam dentro do Core Selynt
- **Setuid controlado** — o binário Core Selynt opera com setuid root apenas para criar estruturas de estado e realizar drop de privilégio para o usuário real antes de spawnar a aplicação
- **Proxy condicional** — o LiteSpeed só encaminha tráfego se o marker de proxy existir, evitando conflitos com sites estáticos ou PHP

---

## Desenvolvimento

```bash
npm install
npm run build     # compila e minifica assets-src/ em images/assets/
npm run check     # executa cada módulo do painel
```

O `build` usa o [esbuild](https://esbuild.github.io/). Edite sempre `assets-src/`: `images/assets/` é gerado e qualquer alteração à mão se perde no próximo build.

O `check` executa cada módulo num DOM mínimo e cobra no `window` os handlers citados nos `onclick`. Serve para o que o build não pega: uma função pode compilar, rodar sem erro e mesmo assim o botão não fazer nada, porque o atributo é resolvido no escopo global e o módulo tem o seu próprio.

As páginas de `user/` e `admin/` **não têm extensão** — o DirectAdmin executa o arquivo cujo nome bate com o caminho pedido. São scripts PHP mesmo assim, e entram no `php -l` como os demais.

### Empacotamento

O pacote é montado pelo workflow de release, que baixa o binário Core Selynt publicado e gera o `selynt_panel.tar.gz` pronto para o Plugin Manager. Para gerar um localmente, use o mesmo caminho — publique uma tag e deixe o CI montar — ou reproduza os passos do `.github/workflows/release.yml`.

### CI/CD

| Workflow | Descrição |
|:---|:---|
| **CI** | Build de assets, validação do `plugin.conf`, sincronia de versão, lint de PHP e Shell |
| **Release** | Gera e publica o pacote `.tar.gz` automaticamente ao criar uma release no GitHub |

---

## Contribuindo

Leia o [guia de contribuição](CONTRIBUTING.md) antes de abrir uma issue ou pull
request. Valem também o [código de conduta](CODE_OF_CONDUCT.md) e a
[política de uso de IA](AI-POLICY.md) — o uso de IA é permitido, e quem
contribui responde pelo que envia.

Falha de segurança **não** vai em issue pública: use o
[relato privado](https://github.com/NullSablex/selynt-panel/security/advisories/new),
como descrito no [SECURITY.md](SECURITY.md).

## Autor

**NullSablex** — [github.com/NullSablex](https://github.com/NullSablex)

## Licença

Distribuído sob a licença [AGPL-3.0-or-later](LICENSE).
