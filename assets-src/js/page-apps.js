// Listagem de aplicações da conta: filtros, paginação e ações em cada card.
//
// A página entrega os dados em `window.__SELYNT_APPS`; o resto vive aqui.

import { t } from './i18n.min.js';
import { toast, confirm as slyConfirm } from './notify.min.js';
import { cssId, esc, fmtBytes } from './ui.min.js';

const { apiBase: API } = window.__SELYNT_APPS ?? {};
const BASE='/CMD_PLUGINS/selynt_panel';

function iconFor(type){
  if(type==='node') return {wrap:'app-icon app-icon-node',icon:'fa-solid fa-cube'};
  if(type==='binary') return {wrap:'app-icon',icon:'fa-solid fa-gears'};
  return {wrap:'app-icon',icon:'fa-solid fa-cube'};
}

// ─── Métricas de recursos ───────────────────────────────────────────────
// O card é reescrito a cada refresh, então a grade de métricas é montada junto
// com ele (rótulos e travessões estáveis) e só os *valores* são atualizados
// depois — caso contrário CPU e memória piscariam a cada 15s.
const statsPrev={};
const DASH='—';

function barClass(pct){return pct>=90?' is-crit':pct>=70?' is-warn':'';}

// id seguro para getElementById a partir do nome do app
// Esqueleto: rótulos fixos + valores em travessão, preenchidos por updateStats.
function metricsSkeleton(name){
  const id=cssId(name);
  const cell=(k,icon,label)=>
    `<div class="metric"><span class="metric-label"><i class="${icon}"></i> ${esc(label)}</span>`+
    `<span class="metric-value" id="${k}-${id}">${DASH}</span>`+
    `<div class="metric-bar" id="${k}bar-${id}" hidden><span style="width:0%"></span></div></div>`;
  return`<div class="app-metrics">`+
    cell('cpu','fa-solid fa-microchip',t('apps.metric.cpu'))+
    cell('mem','fa-solid fa-memory',t('apps.metric.memory'))+
  `</div>`;
}

function setMetric(key,id,text,pct){
  const v=document.getElementById(key+'-'+id);
  if(v)v.textContent=text;
  const bar=document.getElementById(key+'bar-'+id);
  if(!bar)return;
  if(pct==null){bar.hidden=true;return;}
  bar.hidden=false;
  bar.className='metric-bar'+barClass(pct);
  bar.firstElementChild.style.width=Math.min(100,pct)+'%';
}

function cpuRate(name,usec,quota){
  const now=Date.now(),prev=statsPrev[name];
  statsPrev[name]={usec,at:now};
  if(!prev||now<=prev.at||usec<prev.usec)return null;
  const pct=(usec-prev.usec)/((now-prev.at)*1000)*100;
  return{value:pct,ofQuota:quota?Math.min(100,pct/quota*100):null};
}

// Atualiza os valores no lugar. Apps parados ficam com travessão e sem barra.
async function updateStats(apps){
  await Promise.all(apps.map(async a=>{
    const id=cssId(a.name);
    if(a.status!=='RUNNING'){
      delete statsPrev[a.name];
      setMetric('cpu',id,DASH,null);
      setMetric('mem',id,DASH,null);
      return;
    }
    const r=await fetch(`${API}/stats.raw?name=${encodeURIComponent(a.name)}`)
      .then(r=>r.json()).catch(()=>null);
    if(!r||!r.ok||!r.running)return;

    const cpu=cpuRate(a.name,r.cpu.usage_usec,r.cpu.quota_percent);
    setMetric('cpu',id,
      cpu?cpu.value.toFixed(1)+'%'+(r.cpu.quota_percent?' / '+r.cpu.quota_percent+'%':''):DASH,
      cpu?cpu.ofQuota:null);

    const memPct=r.memory.limit?r.memory.used/r.memory.limit*100:null;
    setMetric('mem',id,
      fmtBytes(r.memory.used)+(r.memory.limit?' / '+fmtBytes(r.memory.limit):''),
      memPct);
  }));
}

// Reescrever o HTML a cada refresh fazia o card inteiro piscar. Só remontamos
// quando algo estrutural muda (app criado, removido ou que mudou de estado);
// caso contrário apenas os valores são atualizados no lugar.
// ─── Paginação ──────────────────────────────────────────────────────────
// Client-side: a lista de apps de um usuário é pequena e já vem inteira numa
// requisição; paginar no servidor só adicionaria idas e voltas.
const PER_PAGE=9;
let page=1, allApps=[];

// Janela deslizante em torno da página atual, com elipse quando há salto.
function pageWindow(cur,total){
  if(total<=7)return Array.from({length:total},(_,i)=>i+1);
  const out=[1];
  const from=Math.max(2,cur-1),to=Math.min(total-1,cur+1);
  if(from>2)out.push('…');
  for(let i=from;i<=to;i++)out.push(i);
  if(to<total-1)out.push('…');
  out.push(total);
  return out;
}

function renderPager(total){
  const pager=document.getElementById('sly-pager');
  const info=document.getElementById('sly-pageinfo');
  const pages=Math.ceil(total/PER_PAGE);
  if(pages<=1){pager.hidden=true;info.hidden=true;return;}
  pager.hidden=false;info.hidden=false;

  const btn=(label,target,opts={})=>
    `<button type="button" class="page-btn${opts.active?' active':''}${opts.disabled?' disabled':''}"`+
    `${opts.disabled?' disabled':''} data-page="${target}"`+
    `${opts.label?` aria-label="${esc(opts.label)}"`:''}>${label}</button>`;

  pager.innerHTML=
    btn('<i class="fa-solid fa-chevron-left"></i>',page-1,{disabled:page===1,label:t('page.prev')})+
    pageWindow(page,pages).map(p=>
      p==='…'?'<span class="page-gap">…</span>':btn(p,p,{active:p===page})).join('')+
    btn('<i class="fa-solid fa-chevron-right"></i>',page+1,{disabled:page===pages,label:t('page.next')});

  const first=(page-1)*PER_PAGE+1, last=Math.min(page*PER_PAGE,total);
  info.textContent=t('page.showing',{from:first,to:last,total:total});
}

// Delegação: os botões são recriados a cada render.
document.addEventListener('click',e=>{
  const b=e.target.closest('#sly-pager .page-btn');
  if(!b||b.disabled)return;
  const target=parseInt(b.dataset.page,10);
  if(!target||target===page)return;
  page=target;
  lastSig=null;            // força remontar a grade na nova página
  renderApps(allApps);
  document.getElementById('sly-list').scrollIntoView({behavior:'smooth',block:'nearest'});
});

let lastSig=null;
function appsSignature(apps){
  return apps.map(a=>[a.name,a.host,a.type,a.status].join('|')).join('~');
}

function renderApps(apps){
  const el=document.getElementById('sly-list');
  allApps=apps;
  const pages=Math.max(1,Math.ceil(apps.length/PER_PAGE));
  if(page>pages)page=pages;          // a página some quando apps são removidos
  const slice=apps.slice((page-1)*PER_PAGE,page*PER_PAGE);
  const sig=page+':'+appsSignature(slice);
  if(sig===lastSig&&el.children.length){updateStats(slice);return;}
  lastSig=sig;
  renderPager(apps.length);
  if(!apps.length){
    el.innerHTML='<p class="text-muted">'+esc(t('apps.none'))+' <a href="'+BASE+'/create" class="link-primary">'+esc(t('apps.create_now'))+'</a>.</p>';
    return;
  }
  el.innerHTML=slice.map(a=>{
    const run=a.status==='RUNNING';
    const link=`${BASE}/app?name=${encodeURIComponent(a.name)}`;
    const ic=iconFor(a.type);
    const badge=run?'badge-online':'badge-offline';
    const statusLabel=run?t('apps.online'):t('apps.offline');
    let buttons='';
    if(run){
      buttons+=`<button type="button" class="btn-xs btn-soft" onclick="action('${esc(a.name)}','restart')"><i class="fa-solid fa-arrows-rotate"></i> ${esc(t('apps.action.restart'))}</button>`;
      buttons+=`<button type="button" class="btn-xs btn-danger" onclick="action('${esc(a.name)}','stop')"><i class="fa-solid fa-stop"></i> ${esc(t('apps.action.stop'))}</button>`;
    } else {
      buttons+=`<button type="button" class="btn-xs btn-soft" onclick="action('${esc(a.name)}','start')"><i class="fa-solid fa-play"></i> ${esc(t('apps.action.start'))}</button>`;
      buttons+=`<button type="button" class="btn-xs btn-danger" onclick="action('${esc(a.name)}','remove')"><i class="fa-solid fa-trash"></i> ${esc(t('apps.action.remove'))}</button>`;
    }
    return`<article class="app-card">
      <header class="app-card-header">
        <div class="app-header-main">
          <div class="${ic.wrap}"><i class="${ic.icon}"></i></div>
          <div class="app-info">
            <div class="app-name"><a href="${link}">${esc(a.name)}</a></div>
            <div class="app-meta">${esc(a.host)}</div>
          </div>
        </div>
        <span class="badge ${badge}">${esc(statusLabel)}</span>
      </header>
      ${metricsSkeleton(a.name)}
      <footer class="app-card-footer">${buttons}</footer>
    </article>`;
  }).join('');
  updateStats(slice);
  setTimeout(()=>updateStats(slice),1500);
}

async function load(){
  const r=await fetch(`${API}/apps.raw`).then(r=>r.json()).catch(()=>null);
  if(!r){document.getElementById('sly-list').innerHTML='<p class="alert-error">'+esc(t('errors.communication'))+'</p>';return;}
  if(Array.isArray(r.apps)){renderApps(r.apps);return;}
  if(!r.ok&&(r.error==='binary_missing'||!r.error)){renderApps([]);return;}
  document.getElementById('sly-list').innerHTML=`<p class="alert-error">${esc(r.message||r.error||t('errors.load_apps'))}</p>`;
}
window.load=load;
load();setInterval(load,10000);
