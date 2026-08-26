// Gera images/assets/js/icons.min.js — o mesmo catálogo do Font Awesome, com
// apenas os ícones que o painel usa.
//
// As bibliotecas completas custavam 1,5 MB por página para servir algumas
// dezenas de desenhos. Nada muda na forma de usar: segue sendo
// `<i class="fa-solid fa-play">`, e `fontawesome.min.js` segue sendo o motor —
// este arquivo só entrega a ele um catálogo menor, pelo mesmo caminho que as
// bibliotecas oficiais usam (`___FONT_AWESOME___`, hook `addPack`).
//
// Os nomes saem das próprias páginas e módulos: um ícone novo entra sozinho na
// próxima geração, e um nome que não existe falha aqui em vez de virar um
// espaço vazio na tela.
//
//   FA_DIR=/caminho/do/fontawesome-free-x.y.z-web node tools/build-icons.mjs

import { readFileSync, writeFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import path from 'node:path';

const FA = process.env.FA_DIR;
if (!FA || !existsSync(path.join(FA, 'svgs'))) {
  console.error('defina FA_DIR apontando para o pacote web do Font Awesome');
  process.exit(1);
}

// Os prefixos que cada família registra — os mesmos das bibliotecas oficiais.
const PREFIXOS = {
  solid: ['fas', 'fa-solid'],
  regular: ['far', 'fa-regular'],
  brands: ['fab', 'fa-brands'],
};

function arquivos(dir) {
  return readdirSync(dir).flatMap((e) => {
    const p = path.join(dir, e);
    return statSync(p).isDirectory() ? arquivos(p) : [p];
  });
}

const fontes = ['user', 'admin', 'assets-src/js'].flatMap(arquivos)
  .filter((f) => !f.endsWith('.min.js'));

const usados = new Set();
for (const f of fontes) {
  for (const m of readFileSync(f, 'utf8')
      .matchAll(/fa-(solid|regular|brands)\s+fa-([a-z0-9-]+)/g)) {
    usados.add(`${m[1]}/${m[2]}`);
  }
}

const porFamilia = {};
for (const id of [...usados].sort()) {
  const [familia, nome] = id.split('/');
  const svg = path.join(FA, 'svgs', familia, `${nome}.svg`);
  if (!existsSync(svg)) {
    console.error(`ícone inexistente: ${id}`);
    process.exit(1);
  }
  const txt = readFileSync(svg, 'utf8');
  const box = txt.match(/viewBox="0 0 (\d+) (\d+)"/);
  const d = txt.match(/ d="([^"]+)"/)?.[1];
  if (!box || !d) {
    console.error(`não consegui ler ${id}`);
    process.exit(1);
  }
  // Mesma forma das bibliotecas: [largura, altura, aliases, unicode, path].
  (porFamilia[familia] ??= {})[nome] = [Number(box[1]), Number(box[2]), [], '', d];
}

const registros = Object.entries(porFamilia).map(([familia, icones]) => {
  const prefixos = PREFIXOS[familia].map((p) => JSON.stringify(p)).join(',');
  return `A(${JSON.stringify(icones)},[${prefixos}]);`;
}).join('');

const total = Object.values(porFamilia).reduce((n, o) => n + Object.keys(o).length, 0);

writeFileSync('images/assets/js/icons.min.js',
`/*! Selynt Panel — subconjunto do Font Awesome Free (Icons: CC BY 4.0).
 * Gerado por tools/build-icons.mjs — não editar à mão. */
(function(){var N="___FONT_AWESOME___",w=window;w[N]=w[N]||{};var n=w[N];
n.styles=n.styles||{};n.hooks=n.hooks||{};n.shims=n.shims||[];
function A(i,ps){var e={};for(var k in i){e[k]=i[k];}
for(var j=0;j<ps.length;j++){var p=ps[j];
if(typeof n.hooks.addPack==="function"){n.hooks.addPack(p,e);}
else{n.styles[p]=Object.assign(n.styles[p]||{},e);}}}
${registros}})();
`);
console.log(`  ${total} ícones -> images/assets/js/icons.min.js`);
