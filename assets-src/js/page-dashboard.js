// Painel inicial da conta: totais, uso de memória e as aplicações em destaque.
//
// A página entrega os dados em `window.__SELYNT_DASH`; o resto vive aqui.

import { t } from './i18n.min.js';
import { cssId, esc, fmtBytes, uptime } from './ui.min.js';

const { apiBase: API, base: BASE } = window.__SELYNT_DASH ?? {};
// Ícone em caixa, igual aos cards: wrapper .app-icon + cor por runtime.
function appIcon(ty){
  const map={node:['app-icon-node','fa-solid fa-cube'],
             binary:['app-icon-binary','fa-solid fa-gears']};
  const [cls,icon]=map[ty]||['','fa-solid fa-cube'];
  return`<div class="app-icon${cls?' '+cls:''}"><i class="${icon}"></i></div>`;
}

// Filtro por status. Persistido para sobreviver ao refresh de 15s e ao reload.
let statusFilter='all';
try{
  const f=localStorage.getItem('selynt.dashFilter');
  if(f==='RUNNING'||f==='STOPPED')statusFilter=f;
}catch(e){}

function applyFilter(list){
  return statusFilter==='all'?list:list.filter(a=>a.status===statusFilter);
}

// Só remonta quando algo muda, para a tabela não piscar a cada refresh.
// O filtro entra na assinatura: trocar de aba precisa redesenhar.
let lastSig=null;
function signature(a){return statusFilter+':'+a.map(x=>[x.name,x.status,x.host].join('|')).join('~');}

function topApps(apps){
  // Em execução primeiro, depois mais recentes: ordenar só por data escondia
  // um app ativo assim que cinco mais novos eram criados.
  return applyFilter(apps).sort((a,b)=>{
    const ra=a.status==='RUNNING'?1:0, rb=b.status==='RUNNING'?1:0;
    return rb-ra || (b.created_at||0)-(a.created_at||0);
  }).slice(0,5);
}

function renderRecent(apps){
  const el=document.getElementById('sly-recent');
  if(!apps.length){
    el.innerHTML='<p style="font-size:0.85rem; color:var(--color-text-muted);">'+
      esc(t('apps.none'))+' <a href="'+BASE+'/create">'+esc(t('apps.create_now'))+'</a>.</p>';
    return;
  }
  const sig=signature(apps);
  if(sig===lastSig&&el.querySelector('tbody'))return;
  lastSig=sig;

  const rows=topApps(apps);
  if(!rows.length){
    el.innerHTML='<p style="font-size:0.85rem; color:var(--color-text-muted);">'+
      esc(t('dash.recent_empty_filter'))+'</p>';
    return;
  }

  const L={app:t('admin.overview.col.app'),status:t('admin.overview.col.status'),
           cpu:t('apps.metric.cpu'),mem:t('apps.metric.memory'),up:t('admin.overview.col.uptime')};

  el.innerHTML=`<div style="overflow-x:auto;"><table class="apps-table"><thead><tr>`+
    `<th>${esc(L.app)}</th><th>${esc(L.status)}</th><th>${esc(L.cpu)}</th>`+
    `<th>${esc(L.mem)}</th><th>${esc(L.up)}</th></tr></thead><tbody>`+
    rows.map(a=>{
      const run=a.status==='RUNNING', id=cssId(a.name);
      return`<tr>`+
        `<td data-label="${esc(L.app)}"><div class="app-row-main">${appIcon(a.type)}`+
          `<div><a href="${BASE}/app?name=${encodeURIComponent(a.name)}">${esc(a.name)}</a>`+
          `<div class="app-row-host">${esc(a.host)}</div></div></div></td>`+
        `<td data-label="${esc(L.status)}"><span class="status-pill ${run?'online':'offline'}">`+
          `<i class="fa-solid ${run?'fa-circle':'fa-circle-xmark'}"></i> `+
          `${esc(run?t('apps.online'):t('apps.offline'))}</span></td>`+
        `<td data-label="${esc(L.cpu)}" id="rcpu-${id}">${DASH}</td>`+
        `<td data-label="${esc(L.mem)}" id="rmem-${id}">${DASH}</td>`+
        `<td data-label="${esc(L.up)}">${run&&a.started_at?esc(uptime(a.started_at)):DASH}</td>`+
      `</tr>`;
    }).join('')+`</tbody></table></div>`;
}

// CPU é contador acumulado: a taxa vem do delta entre dois refreshes.
const rowPrev={};
async function updateRowStats(rows){
  await Promise.all(rows.filter(a=>a.status==='RUNNING').map(async a=>{
    const r=await fetch(`${API}/stats.raw?name=${encodeURIComponent(a.name)}`)
      .then(r=>r.json()).catch(()=>null);
    if(!r||!r.ok||!r.running)return;
    const id=cssId(a.name);
    const mem=document.getElementById('rmem-'+id);
    if(mem)mem.textContent=fmtBytes(r.memory.used);
    const cpu=document.getElementById('rcpu-'+id);
    if(!cpu)return;
    const now=Date.now(),prev=rowPrev[a.name];
    rowPrev[a.name]={usec:r.cpu.usage_usec,at:now};
    if(prev&&now>prev.at&&r.cpu.usage_usec>=prev.usec){
      cpu.textContent=((r.cpu.usage_usec-prev.usec)/((now-prev.at)*1000)*100).toFixed(1)+'%';
    }
  }));
}

async function load(){
  const r=await fetch(`${API}/apps.raw`).then(r=>r.json()).catch(()=>null);
  if(!r||!Array.isArray(r.apps)){
    document.getElementById('sly-recent').innerHTML=
      '<p class="alert-error">'+esc(t('errors.load_apps'))+'</p>';
    return;
  }
  const apps=r.apps, online=apps.filter(a=>a.status==='RUNNING').length;
  document.getElementById('s-total').textContent=apps.length;
  document.getElementById('s-online').textContent=online;
  document.getElementById('s-offline').textContent=apps.length-online;
  document.getElementById('s-online-pct').textContent=
    apps.length?Math.round(online/apps.length*100)+'%':DASH;
  renderRecent(apps);
  updateRowStats(topApps(apps));
}
// Os cards são o filtro: clicar em "Online" mostra só as online, e clicar de
// novo volta para todas. Não há controle separado — o card já diz o que faz.
function markFilterCards(){
  document.querySelectorAll('.stat-card.is-filter').forEach(c=>{
    c.classList.toggle('is-active',c.dataset.status===statusFilter);
  });
}

function setFilter(status){
  // Clicar no card já ativo desmarca, voltando para "todas".
  statusFilter=(statusFilter===status&&status!=='all')?'all':status;
  try{localStorage.setItem('selynt.dashFilter',statusFilter);}catch(err){}
  markFilterCards();
  load();
}

document.querySelectorAll('.stat-card.is-filter').forEach(card=>{
  card.addEventListener('click',()=>setFilter(card.dataset.status));
  card.addEventListener('keydown',e=>{
    if(e.key==='Enter'||e.key===' '){e.preventDefault();setFilter(card.dataset.status);}
  });
});

markFilterCards();

load();setInterval(load,15000);
