# Política de segurança

## Como relatar

**Não abra issue pública para falha de segurança.**

Use o [relato privado de vulnerabilidade][priv] deste repositório
(aba *Security* → *Report a vulnerability*). O canal é privado entre quem
relata e quem mantém, e permite publicar o aviso junto com a correção.

[priv]: https://github.com/NullSablex/selynt-panel/security/advisories/new

Ao relatar, ajuda incluir: a versão do plugin, a versão do DirectAdmin e do
servidor web, o que era esperado e o que aconteceu, e o passo a passo para
reproduzir.

O projeto é mantido por uma pessoa, sem plantão: não há prazo de resposta
garantido. Relatos de segurança têm prioridade sobre o resto da fila, e o
retorno vem assim que possível.

## Escopo

O plugin roda sob o CGI do DirectAdmin e conversa com o `core-selynt`, que é
setuid root. Interessa em especial qualquer caminho que permita:

- uma conta ler ou operar aplicações, arquivos ou estado de outra;
- alcançar os endpoints de `admin/` sem ser administrador;
- injetar conteúdo nas páginas do painel (XSS) ou forjar requisição de outra
  origem;
- fazer o plugin invocar o binário com valor que o chamador controla e que o
  binário trate como confiável.

Falha que exija acesso root prévio está fora de escopo.

Vulnerabilidade no binário deve ser relatada em
[core-selynt](https://github.com/NullSablex/core-selynt/security/advisories/new),
que é onde a correção sai.

## Divulgação

A correção sai antes do detalhe técnico. Publicado o release corrigido, o
aviso é divulgado com crédito a quem relatou, salvo pedido em contrário.
