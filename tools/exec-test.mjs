// Executa cada módulo de página num DOM mínimo. Empacotado pelo esbuild em IIFE,
// então imports resolvem de verdade e o que falha é execução, não sintaxe.
import { build } from 'esbuild';
import { readdirSync } from 'node:fs';
import vm from 'node:vm';

const dir = 'images/assets/js';
const mods = readdirSync(dir).filter(f => /^(page-|ui|i18n|notify|lang|theme|viewport|dom|icons)/.test(f));
let falhas = 0;

for (const f of mods) {
  const r = await build({ entryPoints: [`${dir}/${f}`], bundle: true, write: false,
                          format: 'esm', platform: 'browser', logLevel: 'silent' });
  const src = r.outputFiles[0].text;

  const el = () => ({ classList:Object.assign([],{toggle(){},add(){},remove(){},contains:()=>false}),
    style:{setProperty(){}}, addEventListener(){}, appendChild(){}, setAttribute(){},
    getAttribute:()=>null, querySelector:()=>null, querySelectorAll:()=>[],
    getBoundingClientRect:()=>({top:0}), innerHTML:'', textContent:'', value:'',
    dataset:{}, focus(){}, blur(){}, remove(){}, closest:()=>null });
  const doc = { readyState:'complete', documentElement:el(), body:el(),
    getElementById:()=>el(), querySelector:()=>null, querySelectorAll:()=>[],
    createElement:el, addEventListener(){}, execCommand(){}, getSelection:()=>({removeAllRanges(){},addRange(){}}),
    createRange:()=>({selectNode(){}}) };
  const win = { __SELYNT_I18N:{locale:'pt-br',dict:{}}, __SELYNT_APP:{name:'x',apiBase:'/a'},
    __SELYNT_APPS:{apiBase:'/a'}, __SELYNT_DASH:{apiBase:'/a',base:'/b'},
    __SELYNT_CREATE:{user:'u',domains:{ok:true,domains:[]}}, __SELYNT_SETTINGS:{endpoint:'/e'},
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
    console.log(`  ok    ${f}`);
  } catch (e) {
    console.log(`  FALHA ${f}: ${String(e.message).split('\n')[0]}`);
    falhas++;
  }
}
console.log(falhas ? `\n  ${falhas} módulo(s) falharam` : '\n  todos executam');
