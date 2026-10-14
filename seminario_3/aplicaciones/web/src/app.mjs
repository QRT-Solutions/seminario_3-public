// Author: QRT Solutions. Public telemetry with restricted reason editing; never contains an EA token.
import {number,net,selectDeals,summarize,freshness,phaseDetails} from './metrics.mjs';
import {createEditor} from './editor.mjs';
import {renderKpis} from './kpis.mjs';
import {createPerformanceCharts} from './performance-charts.mjs';
const $=id=>document.getElementById(id);
let snapshot=null, config=null, selected=[], page=0, pending=false, requestFailed=false;
let journalPage=0, refreshAgain=false, lastHistory=0;
let kpiStats=null;
const renderPerformance=createPerformanceCharts();
const editor=createEditor({getConfig:()=>config,onChange:()=>{if(snapshot)renderJournals();},onSaved:refresh});
const pageSize=25, charts={};
const formatter=new Intl.NumberFormat('es-CL',{minimumFractionDigits:2,maximumFractionDigits:2});
const amount=value=>number(value)===null?'No disponible':formatter.format(number(value));
const price=value=>number(value)===null?'—':new Intl.NumberFormat('es-CL',{maximumFractionDigits:6}).format(number(value));
const money=value=>`${amount(value)}${number(value)===null?'':` ${snapshot?.account?.currency||''}`}`;
const utc=value=>{const d=new Date(value);return Number.isFinite(d.valueOf())?`${d.toLocaleString('es-CL',{timeZone:'UTC',hour12:false})} UTC`:'Fecha no disponible';};
const brokerDate=value=>typeof value==='string'?value.replace('T',' ').slice(0,19):'—';
const entryLabels={IN:'Entrada',OUT:'Salida',OUT_BY:'Salida por opuesta',INOUT:'Reversión'};
function value(id,n,{currency=true,signed=false}={}){
  $(id).textContent=currency?money(n):amount(n);
  $(id).classList.toggle('pos',signed&&number(n)>0);
  $(id).classList.toggle('neg',signed&&number(n)<0);
}
function row(values){const tr=document.createElement('tr');for(const v of values){const td=document.createElement('td');if(v==='BUY'||v==='SELL'){const badge=document.createElement('span');badge.className=`badge-side ${v.toLowerCase()}`;badge.textContent=v;td.append(badge);}else td.textContent=v;tr.append(td);}return tr;}
function emptyRow(text,cols){const tr=row([text]);tr.firstChild.colSpan=cols;tr.firstChild.className='empty';return tr;}
function filters(){return {symbol:$('symbol').value,entry:$('entry').value,from:$('from').value,to:$('to').value,direction:$('direction').value};}
function updateFreshness(){
  if(!snapshot?.account)return;
  const state=freshness(snapshot.account.received_at);
  $('freshness').textContent=`Última recepción ${state.label} · Consulta cada 30 s`;
  $('freshness').classList.toggle('stale',!state.fresh);
  $('status').textContent=requestFailed?'Consulta fallida · Se conserva la última lectura':state.fresh?'Conectado · Telemetría al día':'Conectado · Telemetría atrasada';
  $('status').classList.toggle('stale',requestFailed||!state.fresh);
}
function renderAccount(){
  const a=snapshot.account;
  $('accountLabel').textContent=`${a.display_name} · ${a.broker} · ${a.currency}`;
  $('received').textContent=`Recepción: ${utc(a.received_at)}`;
  value('balance',a.balance);value('equity',a.equity);value('floating',a.profit_floating,{signed:true});value('marginFree',a.margin_free);value('marginUsed',a.margin);
  $('positionsCount').textContent=number(a.open_positions_count)===null?'No disponible':String(a.open_positions_count);
  $('marginDetail').textContent=`Margen utilizado: ${money(a.margin)}`;
  const positions=a.positions||[];
  $('positions').replaceChildren(...(positions.length?positions.map(p=>row([p.symbol,p.type,price(p.volume),price(p.open_price),price(p.current_price),`${number(p.sl)===0?'Sin SL':price(p.sl)} / ${number(p.tp)===0?'Sin TP':price(p.tp)}`,money(p.profit),money(p.swap)])):[emptyRow('Sin posiciones abiertas en el último estado recibido.',8)]));
  for(const [i,tr] of [...$('positions').rows].entries())if(positions[i])tr.cells[6].classList.add(number(positions[i].profit)>0?'pos':number(positions[i].profit)<0?'neg':'neutral');
  const days=['Domingo','Lunes','Martes','Miércoles','Jueves','Viernes','Sábado'];
  const rates=snapshot.swap_rates||[];
  $('rates').replaceChildren(...(rates.length?rates.map(r=>row([r.symbol,price(r.swap_long),price(r.swap_short),String(r.swap_mode??'—'),days[r.triple_swap_day]??'—',utc(r.received_at)])):[emptyRow('No hay tasas de swap recibidas para los símbolos de esta cuenta.',6)]));
  const previous=$('symbol').value;
  $('symbol').replaceChildren(...['all',...new Set((snapshot.symbols||snapshot.deals.map(d=>d.symbol)))].map(s=>{const o=document.createElement('option');o.value=s;o.textContent=s==='all'?'Todos':s;return o;}));
  if([...$('symbol').options].some(o=>o.value===previous))$('symbol').value=previous;
  const truncated=snapshot.deals_total>snapshot.deals.length;
  $('coverage').textContent=`${snapshot.deals.length} de ${snapshot.deals_total} registros del filtro · Página ${page+1}`;
  $('coverage').classList.toggle('stale',truncated);
  updateFreshness();
}
function renderTable(){
  const all=[...selected].reverse();
  const maxPage=Math.max(0,Math.ceil(snapshot.deals_total/pageSize)-1);
  const visible=all;
  $('deals').replaceChildren(...(visible.length?visible.map(d=>row([brokerDate(d.deal_time),d.symbol,d.deal_type,entryLabels[d.deal_entry]||d.deal_entry,price(d.volume),price(d.price),money(d.profit),money(d.commission),money(d.swap),money(net(d))])):[emptyRow('Sin registros para los filtros seleccionados.',10)]));
  for(const [i,tr] of [...$('deals').rows].entries())if(visible[i]){const d=visible[i];[d.profit,d.commission,d.swap,net(d)].forEach((n,j)=>tr.cells[j+6].classList.add(number(n)>0?'pos':number(n)<0?'neg':'neutral'));tr.cells[3].classList.add('entry-cell');}
  $('pageInfo').textContent=`Página ${page+1} de ${maxPage+1} · ${snapshot.deals_total} registros`;
  $('previous').disabled=page===0;$('next').disabled=page===maxPage;
}
function journalPhaseCell(journal,phase){
  const td=document.createElement('td');td.className='reason-cell';
  const info=phaseDetails(journal,phase);
  const paragraph=(text,className='')=>{const p=document.createElement('p');p.textContent=text;p.className=className;return p;};
  if(info.reason){td.append(paragraph('Motivo registrado','reason-source'),paragraph(info.reason,'reason-text'));}
  for(const comment of info.comments){td.append(paragraph(comment.source,'reason-source native-source'),paragraph(comment.text,'reason-text'));}
  if(!info.reason&&!info.comments.length){
    td.append(paragraph(info.events.length?'Motivo pendiente':phase==='opening'?'Sin apertura recibida':'Sin cierre recibido','muted'));
  }
  if(editor.active()&&info.events.length){const button=document.createElement('button');button.className='btn reason-edit';button.textContent=info.reason?'Editar motivo':'Completar motivo';button.addEventListener('click',()=>editor.edit(journal,phase));td.append(button);}
  if(info.events.length){
    const details=document.createElement('details'),summary=document.createElement('summary');
    summary.textContent=`Datos de ${phase==='opening'?'apertura':'cierre'} · ${info.events.length} ${info.events.length===1?'ejecución':'ejecuciones'}`;
    details.append(summary);
    for(const event of info.events){
      details.append(paragraph(`${brokerDate(event.deal_time)} · ${event.deal_type} · ${price(event.volume)} lotes · ${price(event.price)}${event.deal_entry==='INOUT'?' · Reversión':''}`,'muted'));
    }
    if(!info.comments.length)details.append(paragraph(info.received?'MT5 no incluyó comentarios.':'Comentarios de MT5 no recibidos.','muted'));
    td.append(details);
  }
  return td;
}
function protectionCell(j){
  const td=document.createElement('td');td.className='reason-cell';
  const groups=j.protections||[];
  if(!groups.length){td.textContent='Sin cambios observados';return td;}
  for(const g of groups){
    const d=document.createElement('details'),summary=document.createElement('summary');
    summary.textContent=`${g.changes} cambio(s) · ${utc(g.first_observed_at)}`;d.append(summary);
    const levels=document.createElement('p');levels.textContent=`SL: ${price(g.old_sl)} → ${price(g.new_sl)} · TP: ${price(g.old_tp)} → ${price(g.new_tp)} (0 = sin nivel)`;
    const reason=document.createElement('p');reason.className='reason-text';reason.textContent=g.reason||'Motivo pendiente';d.append(levels,reason);
    if(editor.active()){const b=document.createElement('button');b.className='btn reason-edit';b.textContent=g.reason?'Editar motivo':'Completar motivo';b.addEventListener('click',()=>editor.edit(g,'protection'));d.append(b);}
    td.append(d);
  }
  if(j.protections_total>groups.length){const p=document.createElement('p');p.className='muted';p.textContent=`Se muestran ${groups.length} de ${j.protections_total} grupos más recientes.`;td.append(p);}
  return td;
}
function labelCards(){
  for(const id of ['positions','deals','journals']){
    const tbody=$(id),table=tbody.closest('table');table.classList.add('mobile-cards');
    const labels=[...table.querySelectorAll('thead th')].map(x=>x.textContent);
    for(const tr of tbody.rows)for(const [i,td] of [...tr.cells].entries())if(td.colSpan===1)td.dataset.label=labels[i];
  }
}
function renderJournals(){
  const journals=Array.isArray(snapshot.journals)?snapshot.journals:[];
  const max=Math.max(0,Math.ceil(snapshot.journals_total/10)-1);
  $('journalCoverage').textContent=`${journals.length} de ${snapshot.journals_total??journals.length} operaciones · Más recientes primero`;
  const rows=journals.map(j=>{
    const tr=document.createElement('tr'),identity=document.createElement('td');identity.className='journal-identity';
    const symbol=document.createElement('strong');symbol.textContent=[...new Set((j.events||[]).map(e=>e.symbol))].join(', ')||'Símbolo no recibido';
    const ref=document.createElement('p');ref.textContent=String(j.id).slice(0,8);ref.className='mono muted';
    identity.append(symbol,ref);
    if(j.events_total>(j.events||[]).length){const warning=document.createElement('p');warning.className='muted';warning.textContent='Ejecuciones anteriores fuera del límite';identity.append(warning);}
    tr.append(identity,journalPhaseCell(j,'opening'),journalPhaseCell(j,'closing'),protectionCell(j));
    ['Operación','Apertura','Cierre','Cambios de SL/TP'].forEach((label,i)=>tr.children[i].dataset.label=label);return tr;
  });
  $('journals').replaceChildren(...(rows.length?rows:[emptyRow('No hay operaciones recibidas para la bitácora.',4)]));
  $('journalPageInfo').textContent=`Página ${journalPage+1} de ${max+1}`;
  $('journalPrevious').disabled=journalPage===0;$('journalNext').disabled=journalPage===max;
}
function renderChart(id,type,labels,datasets,extra={}){
  if(charts[id])charts[id].destroy();
  charts[id]=new Chart($(id),{type,data:{labels,datasets},options:{responsive:true,maintainAspectRatio:false,animation:false,
    plugins:{legend:{display:false},tooltip:{callbacks:{label:ctx=>money(ctx.parsed.y)}}},
    scales:{y:{beginAtZero:true,ticks:{callback:n=>formatter.format(n)},title:{display:true,text:snapshot.account.currency},grid:{color:'#edf0f4'}},x:{grid:{display:false},ticks:{maxTicksLimit:6,maxRotation:0}}},...extra}});
}
function renderHistory(){
  const f=filters();
  $('to').setCustomValidity(f.from&&f.to&&f.from>f.to?'La fecha final debe ser igual o posterior a la inicial.':'');
  selected=selectDeals(snapshot.deals,f);
  const m=summarize(selected);
  const dateRange=selected.length?`${brokerDate(selected[0].deal_time)} — ${brokerDate(selected.at(-1).deal_time)} (hora broker)`:'Sin fechas en la selección';
  $('filterSummary').textContent=`${snapshot.deals_total} registros en todo el filtro. Gráficos y exportación: ${selected.length} registros de esta página · ${dateRange}`;
  for(const id of ['net','profit','commission','swap'])value(id,snapshot.summary?.[id]??m[id],{signed:true});
  $('historyEmpty').hidden=selected.length>0;$('charts').hidden=selected.length===0;
  if(selected.length&&globalThis.Chart){
    const labels=selected.map((_,i)=>`Deal ${i+1}`);
    renderChart('cumulative','line',labels,[{label:'Neto acumulado',data:m.sequence,borderColor:'#2563eb',backgroundColor:'#eff6ff',fill:true,borderWidth:2,pointRadius:selected.length>100?0:3,pointHoverRadius:5,tension:0,spanGaps:false}]);
    renderChart('symbolsChart','bar',m.bySymbol.map(x=>x.symbol),[{label:'Neto registrado',data:m.bySymbol.map(x=>x.net),backgroundColor:m.bySymbol.map(x=>x.net>=0?'#059669':'#e11d48'),borderRadius:4,maxBarThickness:64}]);
    $('symbolSummary').textContent=m.bySymbol.map(x=>`${x.symbol}: ${money(x.net)}`).join(' · ');
  }
  renderTable();$('export').disabled=false;
}
async function refresh(forceHistory=true){
  if(pending){refreshAgain=true;return;}pending=true;$('refresh').disabled=true;
  try{
    if(!config){const response=await fetch('./config.json',{cache:'no-store',signal:AbortSignal.timeout(15000)});if(!response.ok)throw new Error('configuration');config=await response.json();}
    const includeHistory=forceHistory||!snapshot||Date.now()-lastHistory>=120000;
    const f=filters();
    const response=await fetch(`${config.supabaseUrl}/rest/v1/rpc/mt5_public_dashboard_page`,{method:'POST',headers:{apikey:config.publishableKey,'Content-Type':'application/json'},body:JSON.stringify({p_deal_page:page,p_journal_page:journalPage,p_symbol:f.symbol==='all'?null:f.symbol,p_entry:f.entry==='all'?null:f.entry,p_from:f.from||null,p_to:f.to||null,p_history:includeHistory}),cache:'no-store',signal:AbortSignal.timeout(15000)});
    if(!response.ok)throw new Error('request');
    const data=await response.json();
    if(JSON.stringify(f)!==JSON.stringify(filters())){refreshAgain=true;return;}
    if(data.version!==2||!Array.isArray(data.deals))throw new Error('schema');
    if(!data.account){snapshot=null;selected=[];$('content').hidden=true;$('export').disabled=true;$('status').textContent='Sin cuenta demo publicada';$('freshness').textContent='Consulta cada 30 segundos';$('error').hidden=true;return;}
    snapshot=includeHistory?data:{...snapshot,account:data.account,swap_rates:data.swap_rates,generated_at:data.generated_at};if(includeHistory)lastHistory=Date.now();requestFailed=false;$('error').hidden=true;$('content').hidden=false;
    if(includeHistory){
      kpiStats=null;
      $('kpiCoverage').textContent='Consultando operaciones completas…';
      try{
        const result=await fetch(`${config.supabaseUrl}/rest/v1/rpc/mt5_public_dashboard_kpis`,{method:'POST',headers:{apikey:config.publishableKey,'Content-Type':'application/json'},body:JSON.stringify({p_symbol:f.symbol==='all'?null:f.symbol,p_direction:f.direction==='all'?null:f.direction,p_from:f.from||null,p_to:f.to||null}),cache:'no-store',signal:AbortSignal.timeout(15000)});
        if(!result.ok)throw new Error('kpis');
        const stats=await result.json();if(stats?.version!==1)throw new Error('kpi-schema');
        if(JSON.stringify(f)!==JSON.stringify(filters())){refreshAgain=true;return;}kpiStats=stats;
        $('kpiCoverage').textContent=`${stats.count} operaciones completas · ${stats.excluded} excluidas · Todo el período por fecha de cierre (hora broker).${stats.unlinked_deals?` ${stats.unlinked_deals} ejecuciones sin posición en el histórico de la cuenta.`:''}`;
      }catch{$('kpiCoverage').textContent='Sin datos de rendimiento: no se pudo consultar las estadísticas. Pulsa Actualizar para reintentar.';}
    }
    renderKpis($('kpiCards'),snapshot.account,kpiStats);
    if(includeHistory)renderPerformance(kpiStats,snapshot.account.currency);
    renderAccount();if(includeHistory){renderJournals();renderHistory();}labelCards();
    if(!globalThis.Chart){$('error').textContent='No se pudo cargar el motor de gráficos. Las cifras y tablas siguen disponibles.';$('error').hidden=false;}
  }catch{
    requestFailed=true;$('error').textContent='No se pudo actualizar la telemetría. Reintenta con «Actualizar». No se han generado datos de ejemplo.';$('error').hidden=false;
    if(snapshot)updateFreshness();else $('status').textContent='Conexión no disponible';
  }finally{pending=false;$('refresh').disabled=false;if(refreshAgain){refreshAgain=false;refresh();}}
}
for(const id of ['symbol','entry','from','to','direction'])$(id).addEventListener('change',()=>{page=0;kpiStats=null;if(snapshot){renderKpis($('kpiCards'),snapshot.account,null);renderPerformance(null,snapshot.account.currency);$('kpiCoverage').textContent='Actualizando filtros…';refresh();}});
$('reset').addEventListener('click',()=>{for(const id of ['symbol','entry','direction'])$(id).value='all';for(const id of ['from','to'])$(id).value='';page=0;kpiStats=null;if(snapshot){renderKpis($('kpiCards'),snapshot.account,null);renderPerformance(null,snapshot.account.currency);refresh();}});
$('refresh').addEventListener('click',()=>refresh());
$('previous').addEventListener('click',()=>{page--;refresh();});$('next').addEventListener('click',()=>{page++;refresh();});
$('journalPrevious').addEventListener('click',()=>{journalPage--;refresh();});$('journalNext').addEventListener('click',()=>{journalPage++;refresh();});
$('export').addEventListener('click',()=>{
  const data={author:'QRT Solutions',source:'MT5 telemetry via Supabase mt5_public_dashboard()',fetched_at:snapshot.generated_at,
    exported_at:new Date().toISOString(),currency:snapshot.account.currency,grain:'deal',time_basis:'broker wall time; not normalized to UTC',
    filters:filters(),deals_total:snapshot.deals_total,deals_limit:snapshot.deals_limit,deals:selected,metrics:summarize(selected)};
  const url=URL.createObjectURL(new Blob([JSON.stringify(data,null,2)],{type:'application/json'}));
  const a=document.createElement('a');a.href=url;a.download='qrt-mt5-seleccion.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
});
document.addEventListener('visibilitychange',()=>{if(!document.hidden)refresh();});
setInterval(()=>{if(!document.hidden)refresh(false);},30000);setInterval(()=>{if(!document.hidden)updateFreshness();},1000);
refresh();
