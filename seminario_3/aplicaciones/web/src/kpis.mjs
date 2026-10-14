// Author: QRT Solutions. KPI presentation never substitutes page-level deal statistics.
import {number} from './metrics.mjs';
const fmt=new Intl.NumberFormat('es-CL',{minimumFractionDigits:2,maximumFractionDigits:2});
export function accountRisk(account){
  const equity=number(account?.equity), count=number(account?.open_positions_count), positions=account?.positions;
  if(equity===null||equity<=0||count===null||!Array.isArray(positions)||count!==positions.length)
    return {value:null,reason:'Falta un estado completo de posiciones y patrimonio positivo.'};
  if(count===0)return {value:0,reason:'Sin posiciones abiertas en el último estado recibido.'};
  if(positions.some(p=>number(p.sl)===0))return {value:null,reason:'Riesgo no acotado por stop: hay posiciones sin SL.'};
  return {value:null,reason:'Falta la valoración monetaria desde el precio actual hasta cada SL. Los deslizamientos pueden superar esa estimación.'};
}
export function buildKpis(account,stats){
  const money=n=>number(n)===null?'Sin datos':`${fmt.format(number(n))} ${account?.currency||''}`;
  const pct=n=>number(n)===null?'Sin datos':`${fmt.format(number(n))} %`;
  const ratio=n=>number(n)===null?'Sin datos':`${fmt.format(number(n))}×`;
  const risk=accountRisk(account), equity=number(account?.equity),margin=number(account?.margin);
  const n=number(stats?.count), sample=n===null?'Estadísticas pendientes de recepción.':`${n} operaciones completas · ${stats.excluded??0} excluidas.`;
  return [
    {id:'equity',title:'Patrimonio actual',value:money(equity),note:`Saldo: ${money(account?.balance)}. Cuenta completa.`,formula:'Equity reportada por MT5: patrimonio incluyendo posiciones abiertas.'},
    {id:'drawdown',title:'Drawdown actual / máximo',value:'Sin datos',note:'No se recibe equity histórica ajustada por depósitos y retiros.',formula:'100 × (máximo previo − equity) / máximo previo. Máximo: peor caída de la serie ajustada.'},
    {id:'risk',title:'Riesgo abierto hasta los stops',value:pct(risk.value),note:risk.reason,formula:'100 × pérdida adicional estimada desde precios actuales hasta los SL / equity.'},
    {id:'net',title:'Beneficio neto del período',value:money(stats?.net),note:'Cierres completos · Costes recibidos; pueden faltar cargos separados.',formula:'Suma de beneficio + comisión + swap de entradas y salidas de operaciones cerradas en el período. Excluye depósitos y retiros.'},
    {id:'return',title:'Retorno puro acumulado',value:pct(stats?.cumulative_return_pct),note:sample,formula:'Suma de 100 × signo × (precio medio de salida − precio medio de entrada) / precio medio de entrada. BUY: +1; SELL: −1. Precios ponderados por volumen. Antes de costes; no es rentabilidad de la cuenta.'},
    {id:'margin',title:'Nivel de margen',value:margin===0?'Sin margen utilizado':pct(margin>0&&equity!==null?100*equity/margin:null),note:'Cuenta completa · Garantías utilizadas frente al patrimonio.',formula:'100 × equity / margen utilizado. Con margen cero el cociente no se calcula.'},
    {id:'pf',title:'Profit Factor',value:ratio(stats?.profit_factor_pct),note:`Base: retorno del precio · Monetario: ${ratio(stats?.profit_factor_money)}`,formula:'Suma de ganancias / valor absoluto de la suma de pérdidas. Sin pérdidas el ratio no está definido; no se muestra infinito.'},
    {id:'win',title:'Tasa de acierto',value:pct(stats?.win_rate_pct),note:'Según retorno del precio · Incluye neutros en el total.',formula:'100 × operaciones con retorno del precio positivo / todas las operaciones completas. Un ganador antes de costes puede perder dinero tras comisiones.'},
    {id:'payoff',title:'Ganancia / pérdida media',value:ratio(stats?.payoff_pct),note:'Base: retorno del precio · Requiere ganadores y perdedores.',formula:'Media de retornos positivos / valor absoluto de la media de retornos negativos.'},
    {id:'expectancy',title:'Esperanza por operación',value:pct(stats?.expectancy_pct),note:sample,formula:'Suma de retornos del precio / número de operaciones completas, incluidos neutros. Describe esta muestra; no garantiza resultados futuros.'}
  ];
}
export function renderKpis(container,account,stats){
  container.replaceChildren(...buildKpis(account,stats).map(k=>{
    const card=document.createElement('article');card.className='hero-card';card.dataset.kpi=k.id;
    const title=document.createElement('h3');title.className='label';title.textContent=k.title;
    const value=document.createElement('p');value.className='val';value.textContent=k.value;
    const note=document.createElement('p');note.className='subtext';note.textContent=k.note;
    const details=document.createElement('details'),summary=document.createElement('summary'),formula=document.createElement('p');
    summary.textContent='Cómo se calcula';formula.textContent=k.formula;details.append(summary,formula);
    card.append(title,value,note,details);return card;
  }));
}
