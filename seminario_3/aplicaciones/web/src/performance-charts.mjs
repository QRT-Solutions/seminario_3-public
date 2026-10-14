// Author: QRT Solutions. Server aggregates share the KPI population and never use a deal page.
import {number} from './metrics.mjs';
const format=new Intl.NumberFormat('es-CL',{maximumFractionDigits:6});
const display=n=>number(n)===null?'Sin datos':format.format(number(n));
const colors={total:'#2563eb',long:'#b45309',short:'#64748b'};
const range=b=>b.lower===b.upper?display(b.lower):`${display(b.lower)} a ${display(b.upper)}`;

export function performanceModels(stats,currency='USD'){
  if(!stats?.charts||stats.charts.version!==1||!Array.isArray(stats.charts.curve)||!stats.count)return [];
  const c=stats.charts,curve=c.curve;
  const points=key=>[{x:0,y:0},...curve.map(p=>({x:p.trade_to,y:number(p[key])}))];
  const line=(label,key,color,dash=[])=>({label,data:points(key),borderColor:color,backgroundColor:color,borderDash:dash,borderWidth:2,pointRadius:curve.length<40?2:0,pointHoverRadius:5,tension:0,spanGaps:false,fill:false});
  const histogram=(id,title,bins,unit)=>({id,title,type:'bar',unit,rows:bins,
    labels:bins.map(b=>new Intl.NumberFormat('es-CL',{maximumFractionDigits:unit==='%'?3:2}).format((b.lower+b.upper)/2)),
    datasets:[{label:'Operaciones',data:bins.map(b=>b.count),backgroundColor:bins.map(b=>b.upper<=0&&b.lower<0?colors.long:b.lower>=0&&b.upper>0?colors.total:colors.short),borderWidth:0,barPercentage:1,categoryPercentage:1}],
    columns:['Desde','Hasta','Operaciones'],table:bins.map(b=>[`${display(b.lower)} ${unit}`,`${display(b.upper)} ${unit}`,String(b.count)])});
  return [
    {id:'returnCurve',title:'Retorno puro acumulado',type:'line',unit:'%',rows:curve,
      datasets:[line('Total','cumulative_return_pct',colors.total),line('Compras','cumulative_long_pct',colors.long,[7,4]),line('Ventas','cumulative_short_pct',colors.short,[2,4])],
      columns:['Cierres desde / hasta','Hora broker desde / hasta','Total %','Compras %','Ventas %'],
      table:curve.map(p=>[`${p.trade_from} / ${p.trade_to}`,`${p.closed_from} / ${p.closed_to}`,display(p.cumulative_return_pct),display(p.cumulative_long_pct),display(p.cumulative_short_pct)])},
    {id:'netCurve',title:'Beneficio neto acumulado',type:'line',unit:currency,rows:curve,
      datasets:[line('Neto','cumulative_net',colors.total)],
      columns:['Cierres desde / hasta','Hora broker desde / hasta',`Neto acumulado ${currency}`],
      table:curve.map(p=>[`${p.trade_from} / ${p.trade_to}`,`${p.closed_from} / ${p.closed_to}`,display(p.cumulative_net)])},
    histogram('returnHistogram','Distribución del retorno por operación',c.histogram_return||[],'%'),
    histogram('netHistogram','Distribución del resultado monetario',c.histogram_net||[],currency)
  ];
}

export function createPerformanceCharts(){
  const instances=new Map();
  return function render(stats,currency){
    for(const chart of instances.values())chart.destroy();instances.clear();
    const models=performanceModels(stats,currency),grid=document.getElementById('performanceGrid'),status=document.getElementById('performanceStatus');
    grid.hidden=!models.length;
    if(!models.length){status.textContent=stats?.count===0?'Sin operaciones completas para los filtros seleccionados.':'Sin datos de gráficos. Actualiza para consultar el historial completo.';return;}
    const curve=stats.charts.curve,grouped=curve.some(p=>p.trade_to>p.trade_from);
    status.textContent=`${stats.count} operaciones completas · ${stats.excluded} excluidas · Todo el filtro.${grouped?` Curvas agrupadas en ${curve.length} puntos; los movimientos dentro de cada grupo no se muestran.`:' Cada punto representa un cierre completo.'} Los histogramas cuentan todas las operaciones.`;
    for(const m of models){
      const host=document.getElementById(`${m.id}Data`);host.replaceChildren();
      const table=document.createElement('table'),caption=document.createElement('caption'),head=document.createElement('thead'),body=document.createElement('tbody');
      caption.textContent=`Datos de ${m.title.toLowerCase()}`;caption.className='sr-only';
      const header=document.createElement('tr');for(const label of m.columns){const th=document.createElement('th');th.scope='col';th.textContent=label;header.append(th);}head.append(header);
      for(const values of m.table){const tr=document.createElement('tr');for(const value of values){const td=document.createElement('td');td.textContent=value;tr.append(td);}body.append(tr);}
      table.append(caption,head,body);host.append(table);
      if(!globalThis.Chart)continue;
      const isLine=m.type==='line';
      const config={type:m.type,data:{labels:m.labels,datasets:m.datasets},options:{responsive:true,maintainAspectRatio:false,animation:false,
        interaction:{mode:'index',intersect:false},
        plugins:{legend:{display:isLine&&m.datasets.length>1,position:'top',labels:{usePointStyle:true,font:{size:12}}},tooltip:{callbacks:{
          title:items=>{const index=items[0].dataIndex;
            if(!isLine)return `Intervalo: ${range(m.rows[index])} ${m.unit}`;
            if(index===0)return 'Base cero · Inicio de la selección';
            const p=m.rows[index-1];return `Cierres ${p.trade_from}–${p.trade_to} · ${p.closed_to.replace('T',' ')} (broker)`;
          },label:ctx=>isLine?`${ctx.dataset.label}: ${display(ctx.parsed.y)} ${m.unit}`:`${ctx.parsed.y} operaciones`,
          footer:()=>isLine?'':m.rows.length===1?'Todos los resultados tienen el mismo valor.':'Límite inferior incluido; superior excluido, salvo el último intervalo.'
        }}},
        scales:{x:{type:isLine?'linear':'category',min:isLine?0:undefined,max:isLine?stats.count:undefined,
          title:{display:true,text:isLine?'Operaciones completas · Orden de cierre':`Resultado por operación (${m.unit})`},
          grid:{display:false},ticks:{maxTicksLimit:6,maxRotation:0,font:{size:12},precision:isLine?0:undefined}},
          y:{beginAtZero:true,title:{display:true,text:isLine?m.unit:'Número de operaciones'},
            ticks:{precision:isLine?undefined:0,maxTicksLimit:6,font:{size:12},callback:n=>display(n)},
            grid:{color:ctx=>ctx.tick.value===0?'#94a3b8':'#edf0f4'}}}}};
      instances.set(m.id,new Chart(document.getElementById(m.id),config));
    }
    if(!globalThis.Chart)status.textContent+=' El motor de gráficos no está disponible; consulta las tablas de datos.';
  };
}
