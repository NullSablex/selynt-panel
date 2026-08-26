// Configuração do servidor: runtimes disponíveis e o padrão de isolamento.
//
// A página entrega os dados em `window.__SELYNT_CONFIG`; o resto vive aqui.

import { t, toast } from './script.min.js';
import { esc } from './ui.min.js';

const { apiBase: API } = window.__SELYNT_CONFIG ?? {};
let allowed=[];
let detected=[];
// Ambiente em exibição. Cada um tem sua própria natureza: Node oferece
// versões que o admin escolhe; um binário roda o executável que o cliente
// enviou, e portanto não tem nada a configurar aqui.
let runtime='node';

function switchRuntime(){
  runtime=document.getElementById('runtime-select').value;
  detected=[];
  renderRuntime();
}
window.switchRuntime=switchRuntime;

// Desenha o corpo do card conforme o ambiente selecionado.
function renderRuntime(){
  const body=document.getElementById('runtime-body');
  const actions=document.getElementById('runtime-actions');
  if(runtime!=='node'){
    body.innerHTML='<p class="cfg-desc">'+esc(t('admin.cfg.runtime_none'))+'</p>';
    actions.style.display='none';
    return;
  }
  actions.style.display='';
  body.innerHTML='<div id="node-list"><em class="text-faded">'+
    esc(t('admin.cfg.node_detect_hint'))+'</em></div>';
  if(detected.length)render();
}

async function detect(){
  const list=document.getElementById('node-list');
  if(list)list.innerHTML='<em class="text-faded">'+esc(t('admin.cfg.detecting'))+'</em>';
  const [r,a]=await Promise.all([
    fetch(API+'?action=detect_nodes').then(r=>r.json()).catch(()=>null),
    fetch(API+'?action=allowed_versions').then(r=>r.json()).catch(()=>null)
  ]);
  if(a&&a.ok) allowed=a.versions||[];
  if(!r||!r.ok){return;}
  detected=r.versions||[];
  if(!detected.length){
    const l=document.getElementById('node-list');
    if(l)l.innerHTML='<em class="text-faded">'+esc(t('admin.cfg.node_none'))+'</em>';
    return;
  }
  document.getElementById('runtime-section').style.display='';
  render();
  document.getElementById('btn-save').classList.remove('d-none');document.getElementById('btn-save').classList.remove('btn-save-hidden');
}

function render(){
  const list=document.getElementById('node-list');
  if(!list)return;
  list.innerHTML='<ul class="cfg-node-list">'+detected.map(v=>{
    const chk=allowed.includes(v.version)?'checked':'';
    return `<li><label><input type="checkbox" value="${esc(v.path)}" ${chk}>`+
      `<span class="cfg-node-ver">${esc(v.version)}</span></label>`+
      `<code class="cfg-node-path">${esc(v.path)}</code></li>`;
  }).join('')+'</ul>';
}

async function save(){
  const checked=[...document.querySelectorAll('#node-list input:checked')];
  if(!checked.length){msg(t('errors.no_selection'),'err');return;}
  const selected=checked.map(i=>detected.findIndex(d=>d.path===i.value)).filter(x=>x>=0);
  const res=await fetch(API+'?action=save_node_versions&s='+selected.join('-'),{method:'POST'});
  const txt=await res.text();
  let r=null;
  try{r=JSON.parse(txt);}catch(e){console.error('Response:',txt);}
  if(r&&r.ok){
    allowed=checked.map(i=>{
      const v=detected.find(d=>d.path===i.value);
      return v?v.version:'';
    }).filter(x=>x);
    msg(t('admin.cfg.save_ok'),'ok');
  } else {
    msg(r?.message||t('admin.cfg.save_err_http',{status:res.status,text:txt.substring(0,200)}),'err');
  }
}

function msg(tx,c){const el=document.getElementById('node-msg');el.className='cfg-msg '+c;el.textContent=tx;setTimeout(()=>el.textContent='',3000);}

async function copyCmd(id){
  const el=document.getElementById(id);
  if(!el)return;
  try{
    await navigator.clipboard.writeText(el.textContent.trim());
  } catch(e){
    const r=document.createRange();r.selectNode(el);
    const sel=window.getSelection();sel.removeAllRanges();sel.addRange(r);
    try{document.execCommand('copy');}catch(_){}
    sel.removeAllRanges();
  }
}
window.copyCmd=copyCmd;

window.detect=detect;
window.renderRuntime=renderRuntime;
window.save=save;
// Desenha o card no ambiente padrão e já busca o que houver instalado.
renderRuntime();
detect();
fetch(API+'?action=version').then(r=>r.json()).then(r=>{
  const el=document.getElementById('bin-ver');
  if(el){el.textContent=r.ok?r.version:t('admin.cfg.version_err');el.classList.remove('text-half');}
}).catch(()=>{});

// Server-wide isolation default. Only applies to accounts that never chose for
// themselves — an explicit per-account setting always wins.
const isoState=document.getElementById('iso-default-state');
const isoBtn=document.getElementById('iso-default-toggle');
let isoDefault=false;

function renderIsoDefault(){
  isoState.textContent=t(isoDefault?'settings.isolation.on':'settings.isolation.off');
  isoState.className='cfg-val '+(isoDefault?'ok':'text-half');
  document.getElementById('iso-default-label').textContent=
    t(isoDefault?'settings.isolation.disable':'settings.isolation.enable');
  isoBtn.disabled=false;
}

fetch(API+'?action=get_default_isolated').then(r=>r.json()).then(r=>{
  if(!r||!r.ok){isoState.textContent=t('errors.generic');return;}
  isoDefault=!!r.isolated; renderIsoDefault();
}).catch(()=>{isoState.textContent=t('errors.generic');});

isoBtn.addEventListener('click',async()=>{
  isoBtn.disabled=true;
  const next=isoDefault?'0':'1';
  const r=await fetch(API+'?action=save_default_isolated&isolated='+next,{method:'POST'})
    .then(x=>x.json()).catch(()=>null);
  if(!r||!r.ok){toast('error',(r&&r.message)||t('errors.generic'));isoBtn.disabled=false;return;}
  isoDefault=!!r.isolated; renderIsoDefault();
  toast('success',t('settings.isolation.saved'));
});
