// Página de uma aplicação: estado, estatísticas, logs e as ações do usuário.
//
// A página entrega o nome da aplicação e o caminho da API em
// `window.__SELYNT_APP`; tudo o mais vive aqui.

import { t } from './i18n.min.js';
import { toast, confirm as slyConfirm, alert as slyAlert } from './notify.min.js';
import { esc, fmtMB, typeLabel, uptime } from './ui.min.js';

const { name: NAME, apiBase: API } = window.__SELYNT_APP ?? {};

let activeTab='out',nodeVersions=[],appRunning=false;

await fetch(`${API}/nodes.raw`).then(r=>r.json()).then(r=>{if(r&&r.ok)nodeVersions=r.versions||[];}).catch(()=>{});

function iconFor(type){
  if(type==='node') return {icon:'fa-brands fa-node-js',cls:'icon-node'};
  if(type==='binary') return {icon:'fa-solid fa-gears',cls:''};
  return {icon:'fa-solid fa-cube',cls:''};
}

function tab(tg){
  activeTab=tg;
  document.querySelectorAll('.log-tab-btn').forEach((b,i)=>b.classList.toggle('active',['out','err'][i]===tg));
  document.querySelectorAll('.log-pane').forEach(p=>p.classList.remove('active'));
  document.getElementById('pane-'+tg).classList.add('active');
  loadLog(tg);
}
window.tab=tab;

// Busca os limites em vigor. Precede loadStatus, que desenha a linha usando
// `memPinned`/`memMax`.
async function loadStats(){
  const r=await fetch(`${API}/stats.raw?name=${encodeURIComponent(NAME)}`)
    .then(r=>r.json()).catch(()=>null);
  if(!r||!r.ok)return;
  memPinned=r.memory.pinned??null;
  memMax=r.memory.max??r.memory.limit??null;
  memUsed=r.running?(r.memory.used??null):null;
}

async function loadStatus(){
  const r=await fetch(`${API}/apps.raw`).then(r=>r.json()).catch(()=>null);
  if(!r||!r.ok)return;
  const a=(r.apps||[]).find(a=>a.name===NAME);if(!a)return;
  const run=a.status==='RUNNING';
  appRunning=run;

  const ic=iconFor(a.type);
  document.getElementById('app-icon').innerHTML=`<i class="${ic.icon}${ic.cls?' '+ic.cls:''}"></i>`;

  const bdg=document.getElementById('app-badge');
  bdg.textContent=run?t('apps.online'):t('apps.offline');
  bdg.className='badge '+(run?'badge-online':'badge-offline');

  const rows=[
    ['fa-solid fa-server',t('app.field.type'),typeLabel(a.type)],
    ['fa-solid fa-globe',t('app.field.host'),esc(a.host)],
    ['fa-solid fa-folder',t('app.field.cwd'),esc(a.cwd)],
    ['fa-solid fa-file-code',t('app.field.entry'),esc(a.entry||t('app.log.dash'))],
  ];
  if(a.type==='node'){
    const nv=nodeVersions.find(v=>v.path===a.node_version);
    const configured=!!a.node_version;
    const missing=configured&&!nv;
    // With no runtime configured, prefer the fallback entry's label — it carries
    // the actual system version ("25.9.0 (padrão)") instead of a bare "default".
    const sysDefault=nodeVersions.find(v=>!v.path);
    const label=nv?nv.label
      :(configured?t('app.nv.configured_missing'):(sysDefault?sysDefault.label:t('app.nv.default')));
    // nodes.raw falls back to a single entry with an empty `path` when the admin
    // configured no runtimes — that is the system default, not something you can
    // pick. Offering it produced a one-option selector whose confirm failed with
    // "node_version is required", so only count entries with a real path.
    const selectable=nodeVersions.filter(v=>v.path);
    const canSelect=selectable.length>0&&(selectable.length>1||missing||!configured);
    if(canSelect){
      const opts=selectable.map(v=>`<option value="${esc(v.path)}"${v.path===a.node_version?' selected':''}>${esc(v.label)}</option>`).join('');
      const warn=missing?`<div class="nv-warn"><i class="fa-solid fa-triangle-exclamation"></i> ${esc(t('app.nv.warn_missing'))}</div>`:'';
      const tip=run?t('app.nv.tooltip_running'):t('app.nv.tooltip_stopped');
      // `is-dirty` up front when nothing is configured yet: picking any version
      // is a real change, so the confirm button must be usable right away.
      const dirty=configured&&nv?'':' is-dirty';
      rows.push(['fa-brands fa-node-js',t('app.field.node'),`${warn}<span class="nv-control${dirty}" id="nv-control" data-current="${esc(configured?a.node_version:'')}"><select id="nv-select" class="inline-select" onchange="markNvDirty()">${opts}</select><button class="btn-xs btn-soft" onclick="changeNodeVersion()" title="${esc(tip)}"><i class="fa-solid fa-check"></i></button></span>`]);
    } else {
      rows.push(['fa-brands fa-node-js',t('app.field.node'),esc(label)]);
    }
  }
  rows.push(['fa-solid fa-memory',t('app.field.memlimit'),memLimitControl()]);
  if(run&&a.started_at) rows.push(['fa-solid fa-clock',t('app.field.uptime'),uptime(a.started_at, 'long')]);
  rows.push(['fa-solid fa-calendar',t('app.field.created'),a.created_at?new Date(a.created_at*1000).toLocaleString():t('app.log.dash')]);
  // O refresh periódico não pode apagar uma edição em andamento: se o controle
  // de limite está sujo ou com foco, guardamos o *nó* e o recolocamos depois.
  // Guardar `outerHTML` não bastaria: o valor escolhido num <select> e o texto
  // digitado num <input> vivem no DOM, não nos atributos, então a marcação
  // serializada traria de volta o estado antigo.
  const memBox=document.getElementById('mem-control');
  const editing=memBox&&(memBox.classList.contains('is-dirty')||memBox.contains(document.activeElement));
  const keep=editing?memBox:null;
  const hadFocus=editing&&memBox.contains(document.activeElement)
    ?document.activeElement.id:null;

  document.getElementById('app-info').innerHTML=rows.map(([ic,lbl,val])=>
    `<div class="stat-row"><span class="stat-label"><i class="${ic}"></i> ${lbl}</span><span class="stat-value">${val}</span></div>`
  ).join('');

  // Recoloca o nó preservado, com a escolha e o texto que o usuário fez.
  if(keep){
    const fresh=document.getElementById('mem-control');
    if(fresh){
      fresh.replaceWith(keep);
      if(hadFocus){
        const el=document.getElementById(hadFocus);
        if(el)el.focus();
      }
    }
  }

  let btns='';
  if(run){
    btns+=`<button class="btn-xs btn-soft" onclick="act('restart')"><i class="fa-solid fa-arrows-rotate"></i> ${esc(t('apps.action.restart'))}</button>`;
    btns+=`<button class="btn-xs btn-danger" onclick="act('stop')"><i class="fa-solid fa-stop"></i> ${esc(t('apps.action.stop'))}</button>`;
  } else {
    btns+=`<button class="btn-xs btn-soft" onclick="act('start')"><i class="fa-solid fa-play"></i> ${esc(t('apps.action.start'))}</button>`;
  }
  if(a.type==='node'){
    btns+=`<button class="btn-xs btn-soft" onclick="openScripts()"><i class="fa-solid fa-terminal"></i> ${esc(t('app.scripts.action'))}</button>`;
  }
  btns+=`<button class="btn-xs btn-danger" onclick="doRemove()"><i class="fa-solid fa-trash"></i> ${esc(t('apps.action.remove'))}</button>`;
  document.getElementById('app-actions').innerHTML=btns;
}

async function act(a){
  const actionLabel=t('apps.action.'+a);
  const actionDone=t('apps.action.'+a+'_done');
  const ok=await slyConfirm({
    title:t('apps.confirm.title',{action:actionLabel}),
    text:t('apps.confirm.text',{action_lower:actionLabel.toLowerCase(),name:NAME}),
    okText:actionLabel,
    cancelText:t('common.cancel')
  });
  if(!ok)return;
  const p=new URLSearchParams({name:NAME,action:a});
  const r=await fetch(`${API}/action.raw?${p}`,{method:'POST'}).then(r=>r.json()).catch(()=>({ok:false}));
  if(r.ok){
    toast('success',t('apps.confirm.success',{action_done:actionDone}));
  } else {
    toast('error',r.message||r.error||t('errors.action_failed'));
  }
  loadStatus();
}
window.act=act;

async function callAction(action,extra){
  const p=new URLSearchParams({name:NAME,action,...(extra||{})});
  return fetch(`${API}/action.raw?${p}`,{method:'POST'}).then(r=>r.json()).catch(()=>({ok:false}));
}

// ─── Limite de memória ──────────────────────────────────────────────────
// "Auto" deixa o app crescer conforme a folga da conta; um valor fixo é um teto
// rígido — o usuário só pode reduzir, nunca pedir mais do que a conta permite.
const MEM_PRESETS=[0,128,256,512,1024,2048];
let memPinned=null;      // bytes definidos pelo usuário, ou null
let memMax=null;         // teto efetivo em vigor
let memUsed=null;        // consumo atual

function memLimitControl(){
  const cur=memPinned?Math.round(memPinned/1048576):0;
  // Um valor fora dos atalhos (definido à mão) aparece como "Personalizado".
  const isCustom=cur>0&&!MEM_PRESETS.includes(cur);
  const opts=MEM_PRESETS.map(mb=>{
    const label=mb===0?t('app.mem.auto'):fmtMB(mb*1048576);
    return`<option value="${mb}"${!isCustom&&mb===cur?' selected':''}>${esc(label)}</option>`;
  }).join('')+`<option value="custom"${isCustom?' selected':''}>${esc(t('app.mem.custom'))}</option>`;

  // Campo manual: aparece só quando "Personalizado" está escolhido.
  const box=`<input type="number" id="mem-input" class="inline-input" min="16" step="16"`+
    ` value="${isCustom?cur:''}" placeholder="MB" oninput="markMemDirty()"`+
    `${isCustom?'':' hidden'}>`;
  // Consumo atual sobre o teto — o mesmo indicador dos cards da listagem.
  const pct=(memUsed!=null&&memMax)?Math.min(100,memUsed/memMax*100):null;
  const usage=pct===null?'':
    `<div class="mem-usage">`+
      `<span class="mem-hint">${esc(t('app.mem.usage',{used:fmtMB(memUsed),total:fmtMB(memMax)}))}</span>`+
      `<div class="metric-bar${pct>=90?' is-crit':pct>=70?' is-warn':''}">`+
      `<span style="width:${pct}%"></span></div>`+
    `</div>`;

  // Uso e barra acima do select: dizem o consumo e o teto de uma vez, e ficam
  // livres do dropdown, que ao abrir cobriria o que estivesse abaixo dele.
  return`<span class="mem-field" id="mem-control" data-current="${cur}">`+
    usage+
    `<span class="mem-row">`+
      `<select id="mem-select" class="inline-select" onchange="onMemSelect()">${opts}</select>`+
      box+
      `<button class="btn-xs btn-soft" onclick="changeMemLimit()" title="${esc(t('app.mem.apply'))}">`+
      `<i class="fa-solid fa-check"></i></button>`+
    `</span>`;
}

// Valor escolhido, em MB. `null` quando "Personalizado" está vazio ou inválido.
function memChosenMb(){
  const sel=document.getElementById('mem-select');
  if(!sel)return null;
  if(sel.value!=='custom')return parseInt(sel.value,10)||0;
  const inp=document.getElementById('mem-input');
  const v=parseInt(inp&&inp.value,10);
  return Number.isFinite(v)&&v>0?v:null;
}

function onMemSelect(){
  const sel=document.getElementById('mem-select'),inp=document.getElementById('mem-input');
  if(inp){
    inp.hidden=sel.value!=='custom';
    if(!inp.hidden)inp.focus();
  }
  markMemDirty();
}
window.onMemSelect=onMemSelect;

function markMemDirty(){
  const box=document.getElementById('mem-control'),sel=document.getElementById('mem-select');
  if(!box||!sel)return;
  const cur=parseInt(box.getAttribute('data-current'),10)||0;
  const chosen=memChosenMb();
  // "Personalizado" com o campo ainda vazio conta como edição em andamento:
  // sem isso o refresh redesenharia a linha e descartaria a escolha antes de o
  // usuário terminar de digitar.
  const dirty=sel.value==='custom'
    ? (chosen===null||chosen!==cur)
    : (chosen!==null&&chosen!==cur);
  box.classList.toggle('is-dirty',dirty);
}
window.markMemDirty=markMemDirty;

async function changeMemLimit(){
  const mb=memChosenMb();
  if(mb===null){
    toast('error',t('errors.invalid_memory_max'));
    return;
  }
  // O binário recusa abaixo de 16 MB; avisar aqui evita uma ida ao servidor.
  if(mb!==0&&mb<16){
    toast('error',t('app.mem.too_small'));
    return;
  }
  const p=new URLSearchParams({name:NAME,action:'set-memory-max',megabytes:String(mb)});
  const r=await fetch(`${API}/action.raw?${p}`,{method:'POST'}).then(r=>r.json()).catch(()=>({ok:false}));
  if(!r.ok){
    toast('error',r.message||r.error||t('errors.generic'));
    return;
  }
  // O limite vale de imediato — não há reinício a pedir.
  toast('success',t('app.mem.applied'));

  // A edição terminou: limpar o estado sujo libera o redesenho, que de outro
  // modo preservaria o controle antigo e esconderia o valor recém-salvo.
  const box=document.getElementById('mem-control');
  if(box)box.classList.remove('is-dirty');
  if(document.activeElement&&box&&box.contains(document.activeElement)){
    document.activeElement.blur();
  }

  // `await` aqui é o que faz a linha mostrar o novo limite: sem ele o redesenho
  // aconteceria antes de `memPinned`/`memMax` chegarem.
  await loadStats();
  await loadStatus();
}
window.changeMemLimit=changeMemLimit;

// Enables the confirm button once the picked version differs from the one in
// use, so the row reads as settled until there is something to apply.
function markNvDirty(){
  const sel=document.getElementById('nv-select'),box=document.getElementById('nv-control');
  if(!sel||!box)return;
  const current=box.getAttribute('data-current')||'';
  box.classList.toggle('is-dirty',sel.value!==current);
}
window.markNvDirty=markNvDirty;

async function changeNodeVersion(){
  const sel=document.getElementById('nv-select');
  if(!sel)return;
  const nv=sel.value;
  const status=await fetch(`${API}/apps.raw`).then(r=>r.json()).catch(()=>null);
  const app=status&&status.ok?(status.apps||[]).find(a=>a.name===NAME):null;
  const wasRunning=app&&app.status==='RUNNING';

  if(wasRunning){
    const ok=await slyConfirm({
      title:t('app.nv.confirm_title'),
      text:t('app.nv.confirm_text',{name:NAME}),
      okText:t('app.nv.confirm_ok'),
      cancelText:t('common.cancel')
    });
    if(!ok)return;
    const stopR=await callAction('stop');
    if(!stopR.ok){
      toast('error',stopR.message||stopR.error||t('errors.stop_failed'));
      loadStatus();return;
    }
  }

  const r=await callAction('set-node-version',{node_version:nv});
  if(!r.ok){
    toast('error',r.message||r.error||t('errors.change_node_failed'));
    if(wasRunning) await callAction('start');
    loadStatus();return;
  }

  if(wasRunning){
    const startR=await callAction('start');
    if(!startR.ok){
      toast('error',startR.message||startR.error||t('errors.version_partial'));
      loadStatus();return;
    }
  }
  toast('success',t('app.nv.changed'));
  loadStatus();
}
window.changeNodeVersion=changeNodeVersion;

async function doRemove(){
  const ok=await slyConfirm({
    title:t('apps.confirm.title',{action:t('apps.action.remove')}),
    text:t('apps.confirm.text',{action_lower:t('apps.action.remove').toLowerCase(),name:NAME}),
    okText:t('apps.action.remove'),
    cancelText:t('common.cancel')
  });
  if(!ok)return;
  const d=await slyConfirm({
    title:t('apps.confirm.delete_title'),
    text:t('apps.confirm.delete_text'),
    okText:t('apps.confirm.delete_yes'),
    cancelText:t('apps.confirm.delete_no')
  });
  const p=new URLSearchParams({name:NAME,action:'remove'});
  if(d)p.set('delete_dir','1');
  const r=await fetch(`${API}/action.raw?${p}`,{method:'POST'}).then(r=>r.json()).catch(()=>({ok:false}));
  if(r.ok){
    toast('success',t('apps.confirm.success',{action_done:t('apps.action.remove_done')}));
    setTimeout(()=>{window.location.href='/CMD_PLUGINS/selynt_panel/apps';},1200);
  } else {
    toast('error',r.message||r.error||t('errors.action_failed'));
  }
}
window.doRemove=doRemove;

async function loadLog(tg){
  const box=document.getElementById('log-'+tg);
  const r=await fetch(`${API}/logs.raw?name=${encodeURIComponent(NAME)}&type=${tg}&lines=100`).then(r=>r.json()).catch(()=>null);
  if(!r)return;
  // Sem linhas pode ser "parado" (não há saída ao vivo) ou "rodando e calado".
  const empty=appRunning?t('app.log.empty'):t('app.log.stopped');
  box.textContent=r.ok?(r.lines||[]).join('\n')||empty:t('app.log.error',{msg:r.message||r.error||''});
  box.scrollTop=box.scrollHeight;
}
window.loadLog=loadLog;

// Os limites vêm antes do primeiro desenho; depois acompanham o mesmo ciclo.
loadStats().then(loadStatus);
setInterval(()=>loadStats().then(loadStatus),8000);
loadLog('out');
setInterval(()=>loadLog(activeTab),5000);

// Scripts do package.json — PROTÓTIPO DE UI.
//
// A lista vem do binário, mas a execução aqui é simulada em JavaScript: serve
// para desenhar o progresso, o log e os desfechos antes de existir o job no
// core. Por ser só JS, recarregar a página perde tudo — na versão real o job
// vive no servidor e a página apenas consulta, então recarregar reencontra a
// execução em andamento.
// Execuções npm da aplicação. O comando roda no servidor, desprendido da
// requisição: fechar a página não o interrompe, e reabrir reencontra o estado.
const JOB_POLL_MS = 2000;

let jobAtivo = null;
let dialogoJob = null;   // diálogo aberto do job, para trocar a ação do rodapé
// Jobs desta sessão: o que roda e os que terminaram. Fechar a tela não pode
// significar perder o resultado — é o que falta no CloudLinux, onde a execução
// some com a página. Na versão real virá do servidor; aqui vive enquanto a
// página não recarrega.
const jobs = [];

// Um job encerrado permanece na lista: é registro de algo que rodou de fato, e
// fazê-lo sumir sozinho apagaria a única evidência do que aconteceu. Sai quando
// o usuário limpa.

// Um passo do job. `estado` é o que a UI precisa saber: em execução, sucesso,
// falha ou cancelado — no CloudLinux é justamente isso que falta e deixa o
// usuário sem saber se rodou.
function jobHtml(j) {
  // Sem progresso real, a barra vira indeterminada: o npm não informa quanto
  // falta, e uma barra que avança sozinha mentiria sobre o andamento.
  const indeterminado = j.progresso === null;
  const pct = indeterminado ? 100 : Math.min(100, Math.round(j.progresso));
  const icone = { rodando: 'fa-spinner fa-spin', ok: 'fa-circle-check',
                  erro: 'fa-circle-xmark', parado: 'fa-ban',
                  timeout: 'fa-hourglass-end' }[j.estado];
  const cor = { rodando: '', ok: 'job-ok', erro: 'job-erro', parado: 'job-parado',
                timeout: 'job-erro' }[j.estado];
  const rotulo = { rodando: t('app.job.running'), ok: t('app.job.done'),
                   erro: t('app.job.failed'), parado: t('app.job.stopped'),
                   timeout: t('app.job.timeout') }[j.estado];

  return '<div class="job-head">' +
      '<span class="job-cmd"><i class="fa-solid ' + icone + '"></i> ' + esc(j.cmd) + '</span>' +
      '<span class="job-state ' + cor + '">' + esc(rotulo) + '</span>' +
    '</div>' +
    '<div class="job-bar"><div class="job-bar-fill ' + cor +
      (indeterminado ? ' job-bar-indet' : '') + '" style="width:' + pct + '%"></div></div>' +
    '<div class="job-meta">' +
      '<span>' + esc(t('app.job.elapsed', { s: String(Math.max(0, j.segundos)) })) + '</span>' +
    '</div>' +
    '<pre class="job-log" id="job-log">' + esc(j.log.join('\n')) + '</pre>';
}

// A ação do job vive no rodapé do diálogo, na mesma linha do "Fechar" e à
// esquerda dele. É o mesmo lugar durante e depois da execução — só muda o
// botão: interromper enquanto roda, voltar quando termina.
// Ação do job no rodapé, à esquerda do "Fechar". Interromper não encerra o
// diálogo (`closes: false`): quem interrompe quer ler o log para saber onde
// parou. Voltar troca de diálogo, então fecha este.
function acaoDoJob(j) {
  // Interromper é o Ctrl+C do terminal: o servidor manda SIGINT ao grupo de
  // processos, dando ao npm a chance de encerrar sem deixar node_modules pela
  // metade. Não fecha o diálogo — quem interrompe quer ler onde parou.
  return j.estado === 'rodando'
    ? { text: t('app.job.stop'), className: 'btn-xs btn-danger',
        closes: false, onClick: pararJob }
    : { text: t('app.job.back'), className: 'btn-xs btn-soft',
        onClick: voltarScripts };
}

async function pararJob() {
  const p = new URLSearchParams({ name: NAME, action: 'stop' });
  const r = await fetch(`${API}/job.raw?${p}`, { method: 'POST' })
    .then((x) => x.json()).catch(() => null);
  if (!r || !r.ok) {
    toast('error', (r && r.message) || t('errors.network'));
    return;
  }
  acompanhar();
}
window.pararJob = pararJob;

function pintarJob() {
  // Sem diálogo aberto o job continua avançando, apenas não há o que desenhar.
  if (!dialogoJob || !jobAtivo) return;
  dialogoJob.setHtml(jobHtml(jobAtivo));
  // Ao terminar, "Interromper" vira "Voltar" sem sair do lugar.
  dialogoJob.setExtra(acaoDoJob(jobAtivo));

  const log = document.getElementById('job-log');
  if (log) log.scrollTop = log.scrollHeight;   // acompanha a saída
}

// Dispara o comando e passa a acompanhar. O servidor responde assim que o job
// começa, não quando termina — um install grande passa do timeout do CGI.
async function executar(command, script, args) {
  const p = new URLSearchParams({ name: NAME, command });
  if (script) p.set('script', script);
  if (args) p.set('args', args);

  const r = await fetch(`${API}/job.raw?${p}`, { method: 'POST' })
    .then((x) => x.json()).catch(() => null);

  if (!r || !r.ok) {
    const conhecido = {
      app_running: 'app.job.err_running',
      job_running: 'app.job.err_busy',
      not_node: 'app.scripts.not_node',
      invalid_script: 'app.job.err_script',
      invalid_arguments: 'app.job.err_args',
      sandbox_unavailable: 'app.job.err_sandbox',
    }[r && r.error];
    toast('error', conhecido ? t(conhecido) : ((r && r.message) || t('errors.network')));
    return;
  }

  abrirJob();
  acompanhar();
}

// Consulta o estado até o comando terminar. Enquanto roda, o log cresce na
// tela; ao terminar, o desfecho fica visível sem depender de a página estar
// aberta no momento certo.
let pollTimer = null;
async function acompanhar() {
  clearTimeout(pollTimer);
  const r = await fetch(`${API}/job.raw?name=${encodeURIComponent(NAME)}`)
    .then((x) => x.json()).catch(() => null);

  const j = r && r.ok && r.job;
  if (!j) return;

  const estado = { running: 'rodando', ok: 'ok', failed: 'erro',
                   timeout: 'timeout', stopped: 'parado' }[j.status] || j.status;

  jobAtivo = {
    id: j.started_at || 0,
    cmd: j.command || '',
    estado,
    log: j.lines || [],
    segundos: (j.finished_at || Math.floor(Date.now() / 1000)) - (j.started_at || 0),
    // Sem progresso real: o npm não informa quanto falta, e uma barra que
    // avança sozinha mentiria sobre o que está acontecendo.
    progresso: estado === 'rodando' ? null : 100,
    fim: j.finished_at || null,
  };

  const i = jobs.findIndex((x) => x.id === jobAtivo.id);
  if (i >= 0) jobs[i] = jobAtivo; else jobs.unshift(jobAtivo);

  pintarJob();
  pintarPainel();

  if (estado === 'rodando') pollTimer = setTimeout(acompanhar, JOB_POLL_MS);
}

// Abre o diálogo do job sem disparar nada — usado ao iniciar e ao reabrir.
function abrirJob() {
  dialogoJob = slyAlert({
    title: t('app.job.title'), html: '', okText: t('common.close'),
    extra: jobAtivo ? acaoDoJob(jobAtivo) : undefined,
  });
}

function voltarScripts() { openScripts(); }
window.voltarScripts = voltarScripts;

// Abre um job do histórico. Se ainda roda, volta a acompanhar ao vivo; se
// terminou, mostra o resultado como ele ficou.
function verJob(id) {
  const j = jobs.find((x) => x.id === Number(id));
  if (!j) return;
  jobAtivo = j;
  abrirJob();
  pintarJob();
  // Ainda rodando: volta a acompanhar de onde está.
  if (j.estado === 'rodando') acompanhar();
}
window.verJob = verJob;

// Diálogo de scripts: dependências, comandos do npm e os scripts do package.
async function openScripts() {
  // O job segue correndo com o diálogo fechado — parar o relógio aqui faria a
  // execução congelar ao trocar de tela, que é o oposto do que o recurso
  // promete. Só o diálogo é solto.
  jobAtivo = null;
  dialogoJob = null;
  pintarPainel();

  const r = await fetch(`${API}/scripts.raw?name=${encodeURIComponent(NAME)}`)
    .then(x => x.json()).catch(() => null);

  const motivo = { no_package: 'app.scripts.no_package',
                   invalid_package: 'app.scripts.invalid_package' }[r && r.reason];

  let corpo = '';

  // Dependências: o estado decide a ação. Oferecer instalar e atualizar com
  // tudo em ordem contradiz o próprio aviso — não há o que instalar.
  const dep = (r && r.ok && r.deps) || 'unknown';
  const CENARIO = {
    ok:         { cor: 'deps-ok',       icone: 'fa-circle-check',        acoes: [] },
    none:       { cor: 'deps-neutro',   icone: 'fa-circle-info',         acoes: [] },
    missing:    { cor: 'deps-faltando', icone: 'fa-triangle-exclamation', acoes: ['install'] },
    incomplete: { cor: 'deps-faltando', icone: 'fa-triangle-exclamation', acoes: ['install'] },
    outdated:   { cor: 'deps-atencao',  icone: 'fa-arrow-rotate-right',  acoes: ['install', 'update'] },
    unknown:    { cor: 'deps-neutro',   icone: 'fa-circle-info',         acoes: [] },
  }[dep] || { cor: 'deps-neutro', icone: 'fa-circle-info', acoes: [] };

  if (dep !== 'unknown') {
    const rotuloAcao = { install: t('app.deps.install'), update: t('app.deps.update') };
    corpo += '<div class="deps-box ' + CENARIO.cor + '">' +
        '<span class="deps-info"><i class="fa-solid ' + CENARIO.icone + '"></i>' +
          '<span>' + esc(t('app.deps.' + dep)) + '</span></span>' +
        (CENARIO.acoes.length
          ? '<span class="deps-acoes">' + CENARIO.acoes.map((a, i) =>
              '<button type="button" class="btn-xs ' + (i === 0 ? 'btn-primary' : 'btn-soft') +
              '" onclick="rodarNpm(\'' + a + '\')">' + esc(rotuloAcao[a]) + '</button>').join('') +
            '</span>'
          : '') +
      '</div>';
  }

  corpo += '<div class="form-field"><label class="form-label" for="scripts-args">' +
    esc(t('app.scripts.args')) + '</label>' +
    '<input type="text" id="scripts-args" class="inline-input" placeholder="' +
    esc(t('app.scripts.args_ph')) + '"></div>';

  if (motivo || !r || !r.ok || !r.scripts || !r.scripts.length) {
    corpo += '<p class="cfg-desc">' + esc(t(motivo || 'app.scripts.empty')) + '</p>';
  } else {
    corpo += '<div class="scripts-list">' + r.scripts.map(n =>
      '<div class="cfg-row"><span class="cfg-lbl">' + esc(n) + '</span>' +
      '<span class="cfg-val"><button type="button" class="btn-xs btn-soft" ' +
      'onclick="rodarScript(\'' + esc(n) + '\')">' +
      '<i class="fa-solid fa-play"></i> ' + esc(t('app.scripts.run')) +
      '</button></span></div>').join('') + '</div>';
  }

  slyAlert({ title: t('app.scripts.title'), html: corpo, okText: t('common.close') });
}
window.openScripts = openScripts;

function argsAtuais() {
  const el = document.getElementById('scripts-args');
  return el ? el.value.trim() : '';
}
window.rodarNpm = (qual) => executar(qual, '', '');

// No protótipo, um script chamado `test` termina em erro de propósito: o
// desfecho que mais importa avaliar é o que falha, não o que dá certo.
window.rodarScript = (nome) => executar('run', nome, argsAtuais());

// ─── Painel lateral de execuções ───────────────────────────────────────────
//
// Fica no canto, sobre a página, sem escurecer o fundo: acompanhar uma execução
// não deve impedir de usar o painel. Recolhido, é só um indicador; aberto,
// lista o que roda e o que terminou há pouco.
//
// Vive fora de `.selynt-panel`, como o modal, então o CSS dele é próprio.
let painelAberto = false;

function elPainel() {
  let el = document.getElementById('selynt-jobs');
  if (el) return el;
  el = document.createElement('div');
  el.id = 'selynt-jobs';
  el.className = 'selynt-jobs';
  const p = document.querySelector('.selynt-panel');
  if (p && p.classList.contains('theme-light')) el.classList.add('theme-light');
  document.body.appendChild(el);
  return el;
}

// Limpa um job encerrado. O que ainda roda não sai da lista: some quando
// termina e o usuário decidir.
function limparJob(id) {
  const i = jobs.findIndex((x) => x.id === Number(id) && x.estado !== 'rodando');
  if (i >= 0) jobs.splice(i, 1);
  pintarPainel();
}
window.limparJob = limparJob;

function limparEncerrados() {
  for (let i = jobs.length - 1; i >= 0; i--) {
    if (jobs[i].estado !== 'rodando') jobs.splice(i, 1);
  }
  pintarPainel();
}
window.limparEncerrados = limparEncerrados;

function pintarPainel() {
  const el = elPainel();

  // O painel é parte fixa da tela, não um alerta que surge do nada: fica no
  // lugar mesmo sem nada a mostrar, para o usuário saber onde procurar.
  el.classList.add('tem-jobs');

  const rodando = jobs.filter((j) => j.estado === 'rodando').length;

  if (!painelAberto) {
    // Recolhido: o indicador diz o que está acontecendo agora.
    // Sem nada a relatar o texto não acrescenta, e vira só o ícone. Havendo
    // execução ou histórico, o texto é a informação — fica.
    const rotulo = rodando ? t('app.job.running_n', { n: String(rodando) })
                 : jobs.length ? t('app.job.recent')
                 : '';
    el.innerHTML = '<button type="button" class="jobs-tag' + (rotulo ? '' : ' jobs-vazio') +
      '" onclick="alternarPainel()" title="' + esc(t('app.job.panel_title')) + '">' +
      '<i class="fa-solid ' + (rodando ? 'fa-spinner fa-spin' : 'fa-list-check') + '"></i>' +
      (rotulo ? '<span>' + esc(rotulo) + '</span>' : '') + '</button>';
    return;
  }

  el.innerHTML = '<div class="jobs-caixa">' +
      '<div class="jobs-topo">' +
        '<span>' + esc(t('app.job.panel_title')) + '</span>' +
        '<span class="jobs-topo-acoes">' +
          (jobs.some((j) => j.estado !== 'rodando')
            ? '<button type="button" class="jobs-limpar-tudo" onclick="limparEncerrados()">' +
              esc(t('app.job.clear_all')) + '</button>'
            : '') +
          '<button type="button" class="jobs-fechar" onclick="alternarPainel()" aria-label="' +
            esc(t('common.close')) + '"><i class="fa-solid fa-chevron-down"></i></button>' +
        '</span>' +
      '</div>' +
      (jobs.length
        ? ''
        : '<p class="jobs-nada">' + esc(t('app.job.none')) + '</p>') +
      '<div class="jobs-lista">' + jobs.map((j) => {
        const cor = { ok: 'job-ok', erro: 'job-erro', parado: 'job-parado', rodando: '' }[j.estado];
        const ic = { ok: 'fa-circle-check', erro: 'fa-circle-xmark',
                     parado: 'fa-ban', rodando: 'fa-spinner fa-spin' }[j.estado];
        const rot = { ok: t('app.job.done'), erro: t('app.job.failed'),
                      parado: t('app.job.stopped'), rodando: t('app.job.running') }[j.estado];
        return '<div class="jobs-item" onclick="verJob(' + j.id + ')">' +
            '<span class="jobs-item-topo">' +
              '<span class="jobs-cmd"><i class="fa-solid ' + ic + ' ' + cor + '"></i> ' +
                esc(j.cmd) + '</span>' +
              '<span class="job-state ' + cor + '">' + esc(rot) + '</span>' +
              (j.estado === 'rodando'
                ? ''
                : '<button type="button" class="jobs-limpar" title="' +
                  esc(t('app.job.clear')) + '" onclick="event.stopPropagation();limparJob(' +
                  j.id + ')"><i class="fa-solid fa-xmark"></i></button>') +
            '</span>' +
            (j.estado === 'rodando'
              ? '<span class="jobs-bar"><span class="jobs-bar-fill" style="width:' +
                Math.min(100, Math.round(j.progresso)) + '%"></span></span>'
              : '') +
          '</div>';
      }).join('') + '</div>' +
    '</div>';
}

function alternarPainel() { painelAberto = !painelAberto; pintarPainel(); }
window.alternarPainel = alternarPainel;

// Desenha o painel já na carga: ele é parte da tela, não consequência de uma
// execução.
pintarPainel();
