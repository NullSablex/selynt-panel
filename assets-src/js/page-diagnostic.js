// Diagnóstico da instalação, como o binário o reporta.
//
// A página entrega os dados em `window.__SELYNT_DIAG`; o resto vive aqui.

import { t } from './i18n.min.js';
import { esc } from './ui.min.js';

const { apiBase: API } = window.__SELYNT_DIAG ?? {};
const btn=document.getElementById('run-diag');
const out=document.getElementById('diag-output');
const summary=document.getElementById('diag-summary');

const ICON={pass:'fa-circle-check',warn:'fa-triangle-exclamation',fail:'fa-circle-xmark'};

btn.addEventListener('click',async()=>{
  btn.disabled=true;
  summary.textContent='';
  out.innerHTML='<p class="text-muted">'+esc(t('diagnostic.running'))+'</p>';

  const r=await fetch(`${API}/diagnostic.raw`,{method:'POST'})
    .then(r=>r.json()).catch(()=>null);
  btn.disabled=false;

  if(!r||!r.ok){
    out.innerHTML='<p class="alert-error">'+esc((r&&(r.message||r.error))||t('errors.generic'))+'</p>';
    return;
  }

  // Agrupa por área para o relatório ser lido por seção, não como uma lista
  // corrida de trinta linhas.
  const groups={};
  for(const c of r.checks||[]) (groups[c.group]??=[]).push(c);

  // O binário devolve a chave e, quando há, um valor; o texto vem do idioma
  // ativo. Antes ele mandava a frase pronta, em inglês e cheia de detalhe
  // interno ("setuid root", "diradmin", "CUSTOM.5 present").
  out.innerHTML=Object.entries(groups).map(([g,items])=>
    `<div class="diag-group"><h3>${esc(t('diagnostic.group.'+g))}</h3>`+
    items.map(c=>{
      let vars={};
      if(c.arg!=null){
        // Algumas chaves carregam dois números; o resto, um só.
        if(c.key==='registered'){
          const [apps,accounts]=String(c.arg).split('|');
          vars={apps,accounts};
        } else if(c.key==='vhosts_ok'){
          const [n,total]=String(c.arg).split('|');
          vars={n,total};
        } else {
          vars={n:c.arg};
        }
      }
      return`<div class="diag-row is-${esc(c.level)}">`+
        `<i class="fa-solid ${ICON[c.level]||'fa-circle'}"></i>`+
        `<span class="diag-detail">${esc(t('diag.'+c.key,vars))}</span>`+
      `</div>`;
    }).join('')+
    `</div>`).join('');

  const s=r.summary||{};
  const clean=!s.fail&&!s.warn;
  const parts=[t('diagnostic.passed',{n:s.pass||0})];
  if(s.warn)parts.push(t('diagnostic.warnings',{n:s.warn}));
  if(s.fail)parts.push(t('diagnostic.failures',{n:s.fail}));
  summary.innerHTML='<span class="status-pill '+(clean?'online':'offline')+'">'+
    '<i class="fa-solid '+(clean?'fa-circle-check':'fa-triangle-exclamation')+'"></i> '+
    esc(parts.join(' · '))+'</span>';
});
