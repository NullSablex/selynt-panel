Bubblewrap (https://github.com/containers/bubblewrap)
Copyright (C) 2016 Alexander Larsson e colaboradores

--------------------------------------------------------------------------------

# O que é distribuído

O Selynt Panel distribui o executável `bin/bwrap`, compilado sem modificações a
partir do código-fonte oficial do Bubblewrap, versão **0.11.2**, commit
`1b80120ef26a28e065e67f89bfef873f13bdd317`.

O binário é publicado pelo release do
[core-selynt](https://github.com/NullSablex/core-selynt), que o compila fixando
o **SHA do commit** — uma tag pode ser reapontada, um commit não.

Ele é usado para confinar a execução de comandos das aplicações — instalação de
dependências e scripts do `package.json` — de modo que cada execução veja apenas
o diretório da própria aplicação.

# Licença: GNU Lesser General Public License, versão 2.0 ou posterior

`SPDX-License-Identifier: LGPL-2.0-or-later`

O texto integral da licença está em `LICENSES/bubblewrap-COPYING.txt`, nesta
mesma pasta, e é o arquivo `COPYING` distribuído com o código-fonte original.

# Código-fonte correspondente

A LGPL exige que o código-fonte correspondente ao binário distribuído esteja
disponível. Como o binário é compilado sem nenhuma modificação, o fonte
correspondente é a própria release oficial:

    https://github.com/containers/bubblewrap/tree/1b80120ef26a28e065e67f89bfef873f13bdd317

Compilado com:

    meson setup build -Dselinux=disabled -Dman=disabled -Dtests=false \
      -Dbash_completion=disabled -Dbuildtype=release \
      -Dc_link_args="-static" -Ddefault_library=static --prefer-static
    ninja -C build

O resultado é um executável estático, sem dependências dinâmicas, instalado com
permissão 755 e **sem** bit setuid.

--------------------------------------------------------------------------------

# Relação com a licença do Selynt Panel

O Selynt Panel é licenciado sob a AGPL-3.0-or-later. O Bubblewrap é distribuído
como um **executável separado**, invocado como processo externo — não é
vinculado ao código do painel nem ao do binário `core-selynt`. Essa forma de uso
é compatível com a LGPL e não altera o licenciamento do Selynt Panel.
