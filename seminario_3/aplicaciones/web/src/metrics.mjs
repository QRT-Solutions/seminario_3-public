// Author: QRT Solutions. The unit is a DEAL (execution), not a completed position.
export function number(value) {
  if (value === null || value === undefined || value === '' || typeof value === 'boolean') return null;
  const n=Number(value); return Number.isFinite(n)?n:null;
}
export function net(deal) {
  const values=['profit','commission','swap'].map(k=>number(deal[k]));
  return values.every(v=>v!==null)?values.reduce((s,v)=>s+v,0):null;
}
export function selectDeals(deals, {symbol='all',entry='all',from='',to=''}={}) {
  return deals.filter(d=>(symbol==='all'||d.symbol===symbol)&&(entry==='all'||d.deal_entry===entry)&&
    (!from||d.deal_time.slice(0,10)>=from)&&(!to||d.deal_time.slice(0,10)<=to));
}
export function summarize(deals) {
  const sum=key=>deals.every(d=>number(d[key])!==null)?deals.reduce((s,d)=>s+number(d[key]),0):null;
  const values=deals.map(net);
  let cumulative=0;
  const sequence=values.map(value=>{cumulative=value===null||cumulative===null?null:cumulative+value;return cumulative;});
  const bySymbol=new Map();
  deals.forEach(d=>{const prev=bySymbol.get(d.symbol)??{total:0,valid:true};const n=net(d);bySymbol.set(d.symbol,{total:prev.total+(n??0),valid:prev.valid&&n!==null});});
  return {count:deals.length,profit:sum('profit'),commission:sum('commission'),swap:sum('swap'),
    net:values.every(v=>v!==null)?values.reduce((s,v)=>s+v,0):null,sequence,
    bySymbol:[...bySymbol].map(([symbol,v])=>({symbol,net:v.valid?v.total:null}))};
}
export function freshness(receivedAt, now=Date.now()) {
  const stamp=Date.parse(receivedAt);
  if(!Number.isFinite(stamp)) return {fresh:false,label:'Fecha no disponible'};
  const seconds=Math.max(0,Math.floor((now-stamp)/1000));
  return {fresh:seconds<=120,label:seconds<60?`hace ${seconds} s`:seconds<3600?`hace ${Math.floor(seconds/60)} min`:`hace ${Math.floor(seconds/3600)} h`};
}
// Author: QRT Solutions. Journal phases retain all partial executions and reversals.
export function phaseDetails(journal,phase) {
  const codes=phase==='opening'?['IN','INOUT']:['OUT','OUT_BY','INOUT'];
  const events=(journal.events||[]).filter(e=>codes.includes(e.deal_entry));
  const comments=[];
  for(const event of events){
    const deal=typeof event.deal_comment==='string'?event.deal_comment:'';
    const order=typeof event.order_comment==='string'?event.order_comment:'';
    if(deal) comments.push({source:deal===order?'MT5 · Ejecución y orden':'MT5 · Ejecución',text:deal});
    if(order&&order!==deal) comments.push({source:'MT5 · Orden',text:order});
  }
  const unique=comments.filter((c,i)=>comments.findIndex(x=>x.source===c.source&&x.text===c.text)===i);
  return {events,reason:journal[`${phase}_reason`]||null,comments:unique,
    received:events.some(e=>typeof e.deal_comment==='string'||typeof e.order_comment==='string')};
}
