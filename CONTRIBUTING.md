# Contribuindo com o Selynt Panel

Obrigado pelo interesse em contribuir! Leia este guia antes de abrir uma issue ou
pull request.

## Antes de começar

- Verifique se já existe uma
  [issue](https://github.com/NullSablex/selynt-panel/issues) aberta para o
  problema ou funcionalidade.
- Para mudanças significativas, abra uma issue primeiro para discutir a
  abordagem antes de implementar.
- **Falha de segurança não vai em issue pública.** Use o
  [relato privado](https://github.com/NullSablex/selynt-panel/security/advisories/new);
  ver [SECURITY.md](SECURITY.md).
- Ao contribuir, você concorda que seu código será licenciado sob os mesmos
  termos da [licença do projeto](LICENSE) (AGPL-3.0-or-later).

## Configurando o ambiente

**Pré-requisitos:**

- Node.js 20+ e npm (só para compilar os assets)
- PHP CLI (para conferir a sintaxe das páginas)
- Um servidor com DirectAdmin, para testar de verdade

```bash
git clone https://github.com/NullSablex/selynt-panel
cd selynt-panel
npm install
```

**Compilar os assets** (CSS e JS minificados em `images/assets/`):

```bash
npm run build
```

**Executar os módulos do painel:**

```bash
npm run check
```

Cada módulo roda num DOM mínimo, e os handlers citados nos `onclick` são
cobrados no `window`. Serve para pegar o que o build não pega: uma função pode
compilar, executar sem erro e mesmo assim o botão não fazer nada, porque o
atributo é resolvido no escopo global e o módulo tem o seu próprio.

**Conferir a sintaxe PHP:**

```bash
find lib hooks -type f \( -name '*.php' -o -name '*.raw' \) -exec php -l {} \;
find user admin -type f ! -name '*.md' -exec php -l {} \;
```

As páginas de `user/` e `admin/` **não têm extensão** — o DirectAdmin executa o
arquivo cujo nome bate com o caminho pedido. São scripts PHP mesmo assim.

## Estrutura do projeto

```
user/          ← páginas e endpoints do painel do usuário
admin/         ← páginas e endpoints do painel do administrador
lib/           ← código PHP compartilhado (common.php) e traduções em lib/i18n/
assets-src/    ← fonte do CSS e dos módulos JS (é o que se edita)
images/assets/ ← saída minificada do build (não editar à mão)
templates/     ← templates de vhost do servidor web
hooks/         ← hooks do DirectAdmin
scripts/       ← instalação, atualização e remoção
bin/           ← o binário core-selynt
tools/         ← ferramentas de desenvolvimento (não vão no pacote)
```

## Regras de código

- **Editar `assets-src/`, nunca `images/assets/`** — a segunda é gerada pelo
  build e qualquer alteração à mão é perdida no próximo `npm run build`.
- **Antes de escrever CSS, procurar a classe em `assets-src/css/panel.css`** —
  boa parte do design já está lá. Criar uma regra que já existe gera duplicata
  que sobrescreve a original, e o sintoma costuma ser visual e sutil.
- **Todo texto ao usuário passa por `selynt_t_html()`** — as traduções ficam em
  `lib/i18n/`. Sem string fixa na página.
- **Escapar tudo que vem do usuário** — use a `esc()` do módulo compartilhado.
- **O plugin não roda como root.** Operação privilegiada é responsabilidade do
  binário [core-selynt](https://github.com/NullSablex/core-selynt), que é setuid
  e valida quem chama. Não contorne isso com `sudo`, script auxiliar ou
  permissão ampliada.
- **Não confiar em valor vindo do cliente** — nome de conta, caminho e variável
  de ambiente são entrada hostil até prova em contrário.

## Uso de IA

O uso de ferramentas de IA (assistentes de código, LLMs, tradutores) neste
projeto é **permitido e bem-vindo**. Em resumo:

- **Você é o responsável.** Quem abre o PR assume autoria e responsabilidade
  integral pelo que enviou — revise e entenda o código, tenha usado IA ou não.
- **Sem co-autoria de IA.** A autoria é humana; não atribua co-autoria a um
  assistente em commits ou PRs (`Co-Authored-By:` de IA, "gerado por", etc.).
- **Sem preconceito.** Nenhuma contribuição é rejeitada *só por* ter sido feita
  com auxílio de IA — o que vale é o mérito dela.

Detalhes completos em [AI-POLICY.md](AI-POLICY.md).

## Abrindo uma Pull Request

1. Crie um branch a partir de `master`: `git checkout -b feat/minha-mudanca`
2. Faça as alterações seguindo as regras acima.
3. Rode `npm run build` e `npm run check`, e confira a sintaxe PHP.
4. Se a mudança é visível a quem usa, atualize o `CHANGELOG.md`.
5. Abra a PR com uma descrição clara do que mudou e por quê.

## Reportando bugs

Inclua na issue:

- Versão do plugin (o campo `version=` em `plugin.conf`, no diretório do
  plugin) e do `core-selynt` (`core-selynt --version`)
- Versão do DirectAdmin e qual servidor web (OpenLiteSpeed, LiteSpeed, Apache…)
- Passos para reproduzir
- Comportamento esperado e o que aconteceu
- Saída de `Diagnóstico` no painel do administrador, quando fizer sentido

## Sugestões de melhoria

Abra uma issue descrevendo:

- O problema que a mudança resolveria
- Como você imagina que funcionaria
- Alternativas que você considerou
