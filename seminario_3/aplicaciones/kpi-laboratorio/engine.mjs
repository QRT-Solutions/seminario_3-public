// Author: QRT Solutions. Staged pure calculations; no network or platform operations.
const finite = x => typeof x === 'number' && Number.isFinite(x);
const average = a => a.length ? a.reduce((s,x)=>s+x,0)/a.length : null;
const deviation = a => {
  if(a.length<2)return null;
  const mean=average(a);
  return Math.sqrt(a.reduce((s,x)=>s+(x-mean)**2,0)/(a.length-1));
};
export function priceReturn(t) {
  if (t.is_closed!==true || t.coverage_complete!==true || !['BUY','SELL'].includes(t.side)) return null;
  if (![t.entry_price,t.exit_price,t.open_volume,t.closed_volume].every(finite) ||
      t.entry_price<=0 || t.exit_price<=0 || t.open_volume<=0 ||
      Math.abs(t.open_volume-t.closed_volume)>1e-8) return null;
  if(typeof t.open_at!=='string'||typeof t.close_at!=='string'||!t.open_at.endsWith('Z')||!t.close_at.endsWith('Z'))return null;
  const start=Date.parse(t.open_at), end=Date.parse(t.close_at);
  if (!Number.isFinite(start)||!Number.isFinite(end)||end<start) return null;
  const value=(t.side==='BUY'?1:-1)*(t.exit_price-t.entry_price)/t.entry_price;
  return value===0?0:value;
}
export function selectTrades(trades,{symbol='all',side='all',from='',to=''}={}) {
  return trades.filter(t=>(symbol==='all'||t.symbol===symbol)&&(side==='all'||t.side===side)&&
    (!from||t.close_at.slice(0,10)>=from)&&(!to||t.close_at.slice(0,10)<=to));
}
export function tradeStatistics(trades) {
  const ordered=[...trades].sort((a,b)=>a.close_at.localeCompare(b.close_at)||a.id.localeCompare(b.id));
  if(new Set(ordered.map(t=>t.id)).size!==ordered.length) throw new Error('Duplicate trade identity');
  const valid=ordered.map(t=>({trade:t,r:priceReturn(t)})).filter(t=>t.r!==null);
  const r=valid.map(t=>t.r), wins=r.filter(x=>x>0), losses=r.filter(x=>x<0), neutral=r.filter(x=>x===0);
  const sorted=[...r].sort((a,b)=>a-b), n=r.length;
  let streak=0,maxStreak=0;
  // Unknown outcomes cannot bridge two loss sequences into an invented streak.
  for(const trade of ordered){const x=priceReturn(trade);streak=x!==null&&x<0?streak+1:0;maxStreak=Math.max(maxStreak,streak);}
  const sum=a=>a.reduce((s,x)=>s+x,0);
  return {
    count:n, excluded:ordered.length-n, wins:wins.length, losses:losses.length, neutral:neutral.length,
    values:{win_rate:n?wins.length/n:null,profit_factor:losses.length?sum(wins)/-sum(losses):null,
      payoff:wins.length&&losses.length?average(wins)/-average(losses):null,
      expectancy:average(r),median:n?(sorted[Math.floor(n/2)]+sorted[Math.ceil(n/2)-1])/2:null,
      deviation:deviation(r),max_loss_streak:n?maxStreak:null},
    series:valid.map(({trade,r})=>({...trade,return_fraction:r})),
    reasons:{profit_factor:losses.length?null:'Sin pérdidas; denominador cero',
      payoff:wins.length&&losses.length?null:'Requiere ganancias y pérdidas',
      deviation:n>=2?null:'Requiere al menos dos operaciones'}
  };
}
export function accountStatistics(daily,{from='',to='',annualRiskFree=0,annualTarget=0,periodsPerYear=252}={}) {
  if(!finite(annualRiskFree)||annualRiskFree<=-1||!finite(annualTarget)||annualTarget<=-1||!finite(periodsPerYear)||periodsPerYear<=0) throw new Error('Invalid ratio parameters');
  const rows=[...daily].filter(d=>(!from||d.date>=from)&&(!to||d.date<=to)).sort((a,b)=>a.date.localeCompare(b.date));
  // Rows must be normalized daily returns; a missing observation is never coerced to zero.
  const complete=rows.length>0 && new Set(rows.map(d=>d.date)).size===rows.length &&
    rows.every(d=>/^\d{4}-\d{2}-\d{2}$/.test(d.date)&&Number.isFinite(Date.parse(d.date))&&
      new Date(d.date).toISOString().slice(0,10)===d.date&&finite(d.return_fraction)&&d.return_fraction>-1&&d.coverage_complete===true);
  const empty={max_drawdown:null,sharpe:null,sortino:null};
  if(!complete) return {count:rows.length,values:empty,series:[],reason:'Serie vacía, duplicada o incompleta'};
  let index=1,peak=1,maxDrawdown=0;
  const series=rows.map(d=>{index*=1+d.return_fraction;peak=Math.max(peak,index);const drawdown=index/peak-1;maxDrawdown=Math.max(maxDrawdown,-drawdown);return {...d,index,drawdown};});
  const rf=(1+annualRiskFree)**(1/periodsPerYear)-1,target=(1+annualTarget)**(1/periodsPerYear)-1;
  const excess=rows.map(d=>d.return_fraction-rf), relative=rows.map(d=>d.return_fraction-target);
  const sd=deviation(excess), downside=Math.sqrt(relative.reduce((s,x)=>s+Math.min(0,x)**2,0)/rows.length);
  return {count:rows.length,values:{max_drawdown:maxDrawdown,
    sharpe:sd>0?Math.sqrt(periodsPerYear)*average(excess)/sd:null,
    sortino:rows.length>=2&&downside>0?Math.sqrt(periodsPerYear)*average(relative)/downside:null},series,
    reasons:{sharpe:sd>0?null:'Requiere dos observaciones y variación',sortino:rows.length>=2&&downside>0?null:'Requiere dos observaciones y desviación bajo el objetivo'}};
}
export const definitions=[
  {key:'win_rate',title:'Tasa de acierto',unit:'percent',scope:'trade',formula:'Ganadores / operaciones analizables',help:'Incluye trades neutros en el denominador.'},
  {key:'profit_factor',title:'Profit Factor %',unit:'ratio',scope:'trade',formula:'Suma de retornos positivos / |suma de retornos negativos|',help:'Se calcula sobre el retorno del precio; sin pérdidas no hay cociente finito.'},
  {key:'payoff',title:'Payoff Ratio %',unit:'ratio',scope:'trade',formula:'Retorno medio ganador / |retorno medio perdedor|',help:'Compara el tamaño medio de ganancias y pérdidas.'},
  {key:'expectancy',title:'Expectativa por trade',unit:'percent',scope:'trade',formula:'Suma de retornos / número de operaciones',help:'Promedio histórico observado; no es una predicción.'},
  {key:'median',title:'Mediana del retorno',unit:'percent',scope:'trade',formula:'Valor central de los retornos ordenados',help:'Para una muestra par, media de los dos valores centrales.'},
  {key:'deviation',title:'Desviación estándar',unit:'percent',scope:'trade',formula:'√[Σ(r − media)² / (n − 1)]',help:'Desviación muestral de los retornos por trade.'},
  {key:'max_drawdown',title:'Drawdown máximo',unit:'percent',scope:'account',formula:'Máximo de 1 − índice ajustado / máximo previo',help:'Caída sobre una curva diaria ajustada por flujos. El muestreo diario omite caídas intradía.'},
  {key:'sharpe',title:'Ratio de Sharpe',unit:'ratio',scope:'account',formula:'√252 × media(r diario − rf diario) / desviación muestral',help:'Anualizado. Referencia libre de riesgo: 0% anual en esta muestra.'},
  {key:'sortino',title:'Ratio de Sortino',unit:'ratio',scope:'account',formula:'√252 × media(r diario − objetivo) / √media[min(r − objetivo, 0)²]',help:'Anualizado. Objetivo: 0% anual. El denominador incluye todos los días.'},
  {key:'max_loss_streak',title:'Máxima racha de pérdidas',unit:'count',scope:'trade',formula:'Mayor secuencia observada de retornos negativos consecutivos',help:'Orden por cierre UTC e ID. Neutros e incompletas interrumpen el conteo; con exclusiones es una racha observada.'}
];
