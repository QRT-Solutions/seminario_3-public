// Author: QRT Solutions. Local demonstration only; no Supabase or Vercel clients.
import React, {useState} from 'react';
import {DataComponent,DataTable,EvidenceChart,useDataApp} from '../../data-app-public.jsx';
import {tradeStatistics,accountStatistics,selectTrades,definitions} from './engine.mjs';
import logo from '../assets/pepperstone.png';
import './dashboard.css';
const format=(value,unit)=>value===null?'No disponible':unit==='percent'?`${(value*100).toLocaleString('es-CL',{minimumFractionDigits:2,maximumFractionDigits:2})}%`:unit==='count'?String(value):value.toLocaleString('es-CL',{minimumFractionDigits:2,maximumFractionDigits:2});
export function DashboardContent(){
  const {queries}=useDataApp();
  const allTrades=queries.trades.rows,allDays=queries.daily.rows;
  const [period,setPeriod]=useState('all'),[symbol,setSymbol]=useState('all'),[side,setSide]=useState('all');
  const from=period==='empty'?'2027-01-01':period==='all'?'':allDays.slice(-Number(period))[0].date;
  const to=allDays.at(-1).date;
  const selected=selectTrades(allTrades,{symbol,side,from,to}),t=tradeStatistics(selected);
  const daily=allDays.filter(d=>(!from||d.date>=from)&&d.date<=to),a=accountStatistics(daily);
  const scopeTrade=[`Símbolo: ${symbol==='all'?'Todos':symbol}`,`Dirección: ${side==='all'?'Todas':side}`,`Cierres: ${from||allDays[0].date} a ${to}`];
  const scopeDaily=[`Cuenta completa · ${from||allDays[0].date} a ${to}`];
  const renderCard=d=>{
    const account=d.scope==='account',stats=account?a:t,rows=account?daily:selected,v=stats.values[d.key];
    const reason=stats.reasons?.[d.key]||stats.reason||'No hay operaciones analizables';
    return <DataComponent key={d.key} id={`lab-${d.key}`} queryId={account?'daily':'trades'} kind="metric" title={d.title} variant="card" displayRows={[{metric:d.title,value:v}]} sourceRows={rows} scopeFilters={account?scopeDaily:scopeTrade}>
      <div className="lab-reading" data-reviewed-rows><span className="lab-basis">{account?'CUENTA · DIARIO':'OPERACIONES · PRECIO'}</span><div className="lab-value">{format(v,d.unit)}</div><p className="lab-description">{v===null?reason:d.help}</p></div>
      <details className="lab-method"><summary>Cómo se calcula</summary><p>{d.formula}</p></details>
    </DataComponent>;
  };
  const curve=a.series.map(d=>({...d,'Retorno acumulado (%)':(d.index-1)*100,'Drawdown (%)':d.drawdown*100}));
  const groups=['BUY','SELL'].map(direction=>{
    const x=tradeStatistics(selected.filter(t=>t.side===direction));
    return {direction:direction==='BUY'?'Compras':'Ventas',count:x.count,winRate:format(x.values.win_rate,'percent'),mean:format(x.values.expectancy,'percent'),factor:format(x.values.profit_factor,'ratio')};
  });
  const shown=t.series.map(d=>({id:d.id,symbol:d.symbol,side:d.side,date:d.close_at.slice(0,10),ret:format(d.return_fraction,'percent')}));
  return <article className="lab-page">
    <div className="lab-intro"><img src={logo} alt="Pepperstone" width="50" height="50"/><div><strong>Laboratorio estadístico · Seminario 3</strong><p>Muestra local con datos simulados · Integración pendiente para la clase</p></div><span className="lab-badge">10 KPI preparados</span></div>
    <div className="lab-controls">
      <label>Periodo<select value={period} onChange={e=>setPeriod(e.target.value)}><option value="all">40 sesiones</option><option value="20">Últimas 20 sesiones</option><option value="5">Últimas 5 sesiones</option><option value="empty">Periodo sin datos</option></select></label>
      <label>Símbolo · operaciones<select value={symbol} onChange={e=>setSymbol(e.target.value)}><option value="all">Todos</option>{[...new Set(allTrades.map(t=>t.symbol))].map(s=><option key={s}>{s}</option>)}</select></label>
      <label>Dirección · operaciones<select value={side} onChange={e=>setSide(e.target.value)}><option value="all">Todas</option><option value="BUY">Compras</option><option value="SELL">Ventas</option></select></label>
      <button onClick={()=>{setPeriod('all');setSymbol('all');setSide('all');}}>Restablecer</button>
    </div>
    <div className="lab-heading"><h2>Estadísticas por operación</h2><span data-reviewed-rows>{t.count} analizables · {t.excluded} incompletas excluidas · {t.wins} ganadoras / {t.losses} perdedoras / {t.neutral} neutras</span></div>
    <p className="lab-note">Retorno del precio, sin costes ni apalancamiento. Los filtros usan el cierre de la operación; una apertura previa al periodo sigue siendo necesaria.</p>
    <div className="lab-grid lab-trades">{definitions.filter(d=>d.scope==='trade').map(renderCard)}</div>
    <div className="lab-heading"><h2>Estadísticas de la cuenta</h2><span data-reviewed-rows>{a.count} sesiones · Cuenta completa del periodo</span></div>
    <p className="lab-note">Serie diaria simulada independiente de los trades. Sharpe y Sortino: anualización de 252 sesiones, referencia y objetivo 0%. El drawdown diario puede omitir caídas intradía.</p>
    <div className="lab-grid lab-account">{definitions.filter(d=>d.scope==='account').map(renderCard)}</div>
    <div className="lab-charts">
      <EvidenceChart id="lab-equity" queryId="daily" title="Retorno acumulado de la cuenta simulada" variant="card" spec={{type:'line',x:'date',y:'Retorno acumulado (%)',showXAxisLabel:false,yLabel:'Retorno acumulado (%)',colors:{'Retorno acumulado (%)':'var(--chart-1)'},valueDecimals:2}} rows={curve} sourceRows={daily} scopeFilters={scopeDaily} height={260}/>
      <EvidenceChart id="lab-drawdown" queryId="daily" title="Caídas desde el máximo previo" variant="card" spec={{type:'line',x:'date',y:'Drawdown (%)',showXAxisLabel:false,yLabel:'Drawdown (%)',colors:{'Drawdown (%)':'var(--negative)'},valueDecimals:2}} rows={curve} sourceRows={daily} scopeFilters={scopeDaily} height={260}/>
    </div>
    <DataComponent id="lab-directions" queryId="trades" title="Compras frente a ventas" variant="card" kind="table" displayRows={groups} sourceRows={selected} scopeFilters={scopeTrade}><DataTable rows={groups} searchable={false} columns={[{key:'direction',label:'Dirección'},{key:'count',label:'Operaciones'},{key:'winRate',label:'Acierto'},{key:'mean',label:'Retorno medio'},{key:'factor',label:'Profit Factor %'}]}/></DataComponent>
    <div className="lab-evidence"><DataComponent id="lab-trade-records" queryId="trades" title="Operaciones simuladas analizadas" variant="card" kind="table" displayRows={shown} sourceRows={selected} scopeFilters={scopeTrade}><DataTable rows={shown} columns={[{key:'id',label:'Operación'},{key:'date',label:'Cierre UTC'},{key:'symbol',label:'Símbolo'},{key:'side',label:'Dirección'},{key:'ret',label:'Retorno del precio'}]}/></DataComponent></div>
    <footer className="lab-footer">© QRT Solutions · <a href="https://www.qrtsolutions.com">www.qrtsolutions.com</a><span>Prototipo local · Datos simulados</span></footer>
  </article>;
}
