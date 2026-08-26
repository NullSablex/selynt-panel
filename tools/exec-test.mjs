// Executa cada módulo de página num DOM mínimo. Empacotado pelo esbuild em IIFE,
// então imports resolvem de verdade e o que falha é execução, não sintaxe.
import { build } from 'esbuild';
import { readdirSync, readFileSync } from 'node:fs';
import vm from 'node:vm';

const dir = 'images/assets/js';
const mods = readdirSync(dir).filter(f => /^(page-|ui|i18n|notify|lang|theme|viewport|dom|icons)/.test(f));
let falhas = 0;

// Qual página carrega qual módulo. Um handler citado num `onclick` só existe
// para o navegador se o módulo o pendurar no window: módulo tem escopo
// próprio, e o atributo é resolvido no global.
const paginas = { 'page-app':'user/app', 'page-apps':'user/apps',
  'page-dashboard':'user/index.html', 'page-create':'user/create',
  'page-settings':'user/settings', 'page-admin':'admin/index.html',
  'page-config':'admin/config', 'page-diagnostic':'admin/diagnostic' };

// Elementos que o HTML entrega vazios e o módulo precisa preencher na carga.
// Não é derivável do HTML: um container vazio pode ser preenchido só depois de
// uma ação do usuário. Esta lista é dos que devem estar prontos ao abrir a
// página — foi um destes, o seletor de host, que a extração do JavaScript
// deixou sem quem o preenchesse.
const preenchidos = {
  'page-create': ['f-host', 'f-node-version'],
  'page-config': ['runtime-body'],
};

// Handlers citados no HTML da página e no HTML que o próprio módulo gera.
function handlersExigidos(nome) {
  const fontes = [];
  const pag = paginas[nome];
  if (pag) { try { fontes.push(readFileSync(pag, 'utf8')); } catch {} }
  try { fontes.push(readFileSync(`assets-src/js/${nome}.js`, 'utf8')); } catch {}

  const achados = new Set();
  for (const texto of fontes)
    for (const m of texto.matchAll(/\bon(?:click|change|submit|input|keyup|keydown)=[\\]*["']\s*([A-Za-z_$][\w$]*)\s*\(/g))
      achados.add(m[1]);
  return achados;
}

for (const f of mods) {
  const r = await build({ entryPoints: [`${dir}/${f}`], bundle: true, write: false,
                          format: 'esm', platform: 'browser', logLevel: 'silent' });
  const src = r.outputFiles[0].text;

  // Cada elemento registra se recebeu conteúdo. Um <select> ou container que o
  // HTML entrega vazio e ninguém preenche fica invisível ao teste de execução:
  // o módulo roda inteiro sem erro, e a tela chega vazia ao usuário.
  const escrito = new Set();
  const el = (id) => {
    const marca = () => { if (id) escrito.add(id); };
    const o = { classList:Object.assign([],{toggle(){},add(){},remove(){},contains:()=>false}),
      style:{setProperty(){}}, addEventListener(){}, setAttribute(){},
      appendChild(){ marca(); },
      getAttribute:()=>null, querySelector:()=>null, querySelectorAll:()=>[],
      getBoundingClientRect:()=>({top:0}), textContent:'', value:'',
      dataset:{}, focus(){}, blur(){}, remove(){}, closest:()=>null };
    let _html = '';
    Object.defineProperty(o, 'innerHTML', {
      get: () => _html,
      set: (v) => { _html = v; if (String(v).trim()) marca(); },
    });
    return o;
  };
  const cache = new Map();
  const doc = { readyState:'complete', documentElement:el(), body:el(),
    getElementById:(id)=>{ if(!cache.has(id)) cache.set(id, el(id)); return cache.get(id); },
    querySelector:()=>null, querySelectorAll:()=>[],
    createElement:el, addEventListener(){}, execCommand(){}, getSelection:()=>({removeAllRanges(){},addRange(){}}),
    createRange:()=>({selectNode(){}}) };
  const win = { __SELYNT_I18N:{locale:'pt-br',dict:{}}, __SELYNT_APP:{name:'x',apiBase:'/a'},
    __SELYNT_APPS:{apiBase:'/a'}, __SELYNT_DASH:{apiBase:'/a',base:'/b'},
    __SELYNT_CREATE:{user:'u',domains:{ok:true,domains:[{host:'exemplo.com',subdomains:[{host:'app.exemplo.com'}]}]}}, __SELYNT_SETTINGS:{endpoint:'/e'},
    __SELYNT_ADMIN:{apiBase:'/a'}, __SELYNT_CONFIG:{apiBase:'/a'}, __SELYNT_DIAG:{apiBase:'/a'},
    addEventListener(){}, matchMedia:()=>({matches:false}),
    localStorage:{getItem:()=>null,setItem(){},removeItem(){}},
    location:{href:''}, innerHeight:900, document:doc, navigator:{clipboard:{writeText(){}}} };
  const ctx = { window:win, document:doc, navigator:win.navigator,
    localStorage:win.localStorage, matchMedia:win.matchMedia,
    fetch:()=>Promise.resolve({json:()=>Promise.resolve({ok:true,apps:[],versions:[],memory:{pinned:null,max:null,limit:null,used:null},cpu:{},checks:[],summary:{},domains:[],lines:[],status:'STOPPED',running:false})}),
    setTimeout:()=>0, setInterval:()=>0, clearInterval(){}, console,
    MutationObserver:class{observe(){}}, URLSearchParams, requestAnimationFrame:()=>0 };
  ctx.globalThis = ctx;
  try {
    const mod = new vm.SourceTextModule(src, { context: vm.createContext(ctx), identifier: f });
    await mod.link(() => { throw new Error('sem dependências externas'); });
    await mod.evaluate({ timeout: 5000 });
    await new Promise(r => globalThis.setTimeout(r, 60));

    const nome = f.replace(/\.min\.js$/, '');

    const vazios = (preenchidos[nome] ?? []).filter(id => !escrito.has(id));
    if (vazios.length) {
      console.log(`  FALHA ${f}: elemento sem conteúdo após a carga: ${vazios.join(', ')}`);
      falhas++;
      continue;
    }

    const faltando = [...handlersExigidos(nome)]
      .filter(h => typeof win[h] !== 'function' && typeof ctx[h] !== 'function');
    if (faltando.length) {
      console.log(`  FALHA ${f}: handler não exposto no window: ${faltando.join(', ')}`);
      falhas++;
      continue;
    }
    console.log(`  ok    ${f}`);
  } catch (e) {
    console.log(`  FALHA ${f}: ${String(e.message).split('\n')[0]}`);
    falhas++;
  }
}
console.log(falhas ? `\n  ${falhas} módulo(s) falharam` : '\n  todos executam');
