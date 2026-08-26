// Visão geral do administrador: as aplicações de todas as contas.
//
// A página entrega os dados em `window.__SELYNT_ADMIN`; o resto vive aqui.

import { t } from './script.min.js';
import { esc, fmtBytes, typeLabel } from './ui.min.js';

const { apiBase: API } = window.__SELYNT_ADMIN ?? {};
function uptime(ts){
  let s=Math.floor(Date.now()/1000-ts);
  if(s<60)return t('time.now');
  const u=[
    [31536000,'time.year','time.years'],
    [2592000,'time.month','time.months'],
    [86400,'time.day','time.days'],
    [3600,'time.hour','time.hours'],
    [60,'time.minute','time.minutes'],
  ];
  const p=[];
  for(const[d,sg,pl] of u){
    const v=Math.floor(s/d);
    if(v>0){p.push(v+' '+t(v===1?sg:pl));s%=d;}
    if(p.length===2)break;
  }
  return p.join(t('time.connector'));
}
// Ícone em caixa, com a cor do runtime — mesmo componente dos cards.
function appIcon(ty){
  const map={node:['app-icon-node','fa-solid fa-cube'],
             binary:['app-icon-binary','fa-solid fa-gears']};
  const [cls,icon]=map[ty]||['','fa-solid fa-cube'];
  return`<div class="app-icon${cls?' '+cls:''}"><i class="${icon}"></i></div>`;
}

function typeIcon(ty){
  if(ty==='node') return '<i class="fa-solid fa-cube icon-node"></i>';
  if(ty==='binary') return '<i class="fa-solid fa-gears"></i>';
  return '<i class="fa-solid fa-cube"></i>';
}
// CPU é contador acumulado: a taxa sai do delta entre dois refreshes da
// tabela (15s), sem custo extra de requisição.
const cpuPrev={};

// ─── Filtro e paginação ─────────────────────────────────────────────────
// Mesmo padrão do painel do usuário: os cards são o filtro, e a lista é
// paginada no cliente — `admin list` já traz tudo numa requisição.
const PER_PAGE=15;
let page=1, statusFilter='all', allApps=[];
try{
  const f=localStorage.getItem('selynt.adminFilter');
  if(f==='RUNNING'||f==='STOPPED')statusFilter=f;
}catch(e){}

function applyFilter(list){
  return statusFilter==='all'?list:list.filter(a=>a.status===statusFilter);
}

function markFilterCards(){
  document.querySelectorAll('.stat-card.is-filter').forEach(c=>{
    c.classList.toggle('is-active',c.dataset.status===statusFilter);
  });
}

function setFilter(status){
  // Clicar no card já ativo desmarca, voltando para todas.
  statusFilter=(statusFilter===status&&status!=='all')?'all':status;
  page=1;
  try{localStorage.setItem('selynt.adminFilter',statusFilter);}catch(e){}
  markFilterCards();
  lastTableSig=null;
  load();
}

// Janela deslizante com elipse quando há muitas páginas.
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
  const btn=(label,target,o={})=>
    `<button type="button" class="page-btn${o.active?' active':''}${o.disabled?' disabled':''}"`+
    `${o.disabled?' disabled':''} data-page="${target}">${label}</button>`;
  pager.innerHTML=
    btn('<i class="fa-solid fa-chevron-left"></i>',page-1,{disabled:page===1})+
    pageWindow(page,pages).map(n=>
      n==='…'?'<span class="page-gap">…</span>':btn(n,n,{active:n===page})).join('')+
    btn('<i class="fa-solid fa-chevron-right"></i>',page+1,{disabled:page===pages});
  const first=(page-1)*PER_PAGE+1,last=Math.min(page*PER_PAGE,total);
  info.textContent=t('page.showing',{from:first,to:last,total:total});
}

document.addEventListener('click',e=>{
  const card=e.target.closest('.stat-card.is-filter');
  if(card){setFilter(card.dataset.status);return;}
  const b=e.target.closest('#sly-pager .page-btn');
  if(!b||b.disabled)return;
  const target=parseInt(b.dataset.page,10);
  if(!target||target===page)return;
  page=target; lastTableSig=null; load();
});

document.addEventListener('keydown',e=>{
  if(e.key!=='Enter'&&e.key!==' ')return;
  const card=e.target.closest&&e.target.closest('.stat-card.is-filter');
  if(card){e.preventDefault();setFilter(card.dataset.status);}
});
function cellId(a){return String(a.user+'-'+a.name).replace(/[^A-Za-z0-9_-]/g,'_');}
function tableSignature(apps){
  return statusFilter+':'+page+':'+
    apps.map(a=>[a.user,a.name,a.type,a.host,a.status,a.pid].join('|')).join('~');
}
let lastTableSig=null;
function cpuCell(key,usec){
  if(usec==null)return null;
  const now=Date.now(),prev=cpuPrev[key];
  cpuPrev[key]={usec,at:now};
  if(!prev||now<=prev.at||usec<prev.usec)return null;
  return((usec-prev.usec)/((now-prev.at)*1000)*100).toFixed(1)+'%';
}

async function load(){
  const r=await fetch('/CMD_PLUGINS_ADMIN/selynt_panel/api/overview.raw').then(r=>r.json()).catch(()=>null);
  if(!r||!r.ok){document.getElementById('sly-table').innerHTML='<p class="alert-error">'+esc(t('errors.load_apps'))+'</p>';return;}
  const apps=r.apps||[];
  allApps=apps;
  const dash=t('app.log.dash');
  const users=[...new Set(apps.map(a=>a.user))];
  const run=apps.filter(a=>a.status==='RUNNING').length;
  document.getElementById('stat-users').textContent=users.length;
  document.getElementById('stat-total').textContent=apps.length;
  document.getElementById('stat-run').textContent=run;
  document.getElementById('stat-stopped').textContent=apps.length-run;
  document.getElementById('stat-run-pct').textContent=
    apps.length?Math.round(run/apps.length*100)+'% '+t('dash.of_total'):dash;
  if(!apps.length){
    document.getElementById('sly-table').innerHTML='<p class="text-muted">'+esc(t('admin.overview.none'))+'</p>';
    document.getElementById('sly-pager').hidden=true;
    document.getElementById('sly-pageinfo').hidden=true;
    return;
  }

  // A tabela mostra a página atual do filtro; os cards seguem contando tudo.
  const filtered=applyFilter(apps);
  const pages=Math.max(1,Math.ceil(filtered.length/PER_PAGE));
  if(page>pages)page=pages;
  const slice=filtered.slice((page-1)*PER_PAGE,page*PER_PAGE);
  markFilterCards();

  if(!filtered.length){
    document.getElementById('sly-table').innerHTML='<p class="text-muted">'+esc(t('dash.recent_empty_filter'))+'</p>';
    document.getElementById('sly-pager').hidden=true;
    document.getElementById('sly-pageinfo').hidden=true;
    lastTableSig=tableSignature(apps);
    return;
  }
  // Só remonta a tabela quando algo estrutural muda; caso contrário atualiza
  // apenas as células de CPU e memória, para não piscar a cada 15s.
  const sig=tableSignature(slice);
  if(sig===lastTableSig&&document.querySelector('#sly-table tbody')){
    slice.forEach(a=>{
      const id=cellId(a);
      const c=document.getElementById('cpu-'+id);
      const m=document.getElementById('mem-'+id);
      if(c)c.textContent=cpuCell(a.user+'/'+a.name,a.cpu_usec)||dash;
      if(m)m.textContent=a.memory?fmtBytes(a.memory):dash;
    });
    return;
  }
  lastTableSig=sig;
  renderPager(filtered.length);
  document.getElementById('sly-table').innerHTML=`<div class="table-scroll"><table class="apps-table"><thead><tr><th>${esc(t('admin.overview.col.user'))}</th><th>${esc(t('admin.overview.col.app'))}</th><th>${esc(t('admin.overview.col.status'))}</th><th>${esc(t('admin.overview.col.uptime'))}</th><th>${esc(t('admin.overview.col.cpu'))}</th><th>${esc(t('admin.overview.col.memory'))}</th><th>${esc(t('admin.overview.col.pid'))}</th></tr></thead><tbody>${
    slice.map(a=>{
      const run=a.status==='RUNNING';
      return`<tr>`+
        `<td data-label="${esc(t('admin.overview.col.user'))}">${esc(a.user)}</td>`+
        `<td data-label="${esc(t('admin.overview.col.app'))}"><div class="app-row-main">${appIcon(a.type)}`+
          `<div><span class="app-name-plain">${esc(a.name)}</span>`+
          `<div class="app-row-host">${esc(a.host)}</div></div></div></td>`+
        `<td data-label="${esc(t('admin.overview.col.status'))}"><span class="status-pill ${run?'online':'offline'}">`+
          `<i class="fa-solid ${run?'fa-circle':'fa-circle-xmark'}"></i> `+
          `${esc(run?t('apps.online'):t('apps.offline'))}</span></td>`+
        `<td data-label="${esc(t('admin.overview.col.uptime'))}">${run&&a.started_at?esc(uptime(a.started_at)):dash}</td>`+
        `<td data-label="${esc(t('admin.overview.col.cpu'))}" id="cpu-${cellId(a)}">${cpuCell(a.user+'/'+a.name,a.cpu_usec)||dash}</td>`+
        `<td data-label="${esc(t('admin.overview.col.memory'))}" id="mem-${cellId(a)}">${a.memory?esc(fmtBytes(a.memory)):dash}</td>`+
        `<td data-label="${esc(t('admin.overview.col.pid'))}">${a.pid||dash}</td>`+
      `</tr>`;
    }).join('')
  }</tbody></table></div>`;
}
load();setInterval(load,15000);
