// Author: QRT Solutions. Deterministic fictional inputs for a disconnected classroom preview.
import {writeFile} from 'node:fs/promises';
const days=[];
for(let d=new Date('2026-08-10T00:00:00Z');days.length<40;d.setUTCDate(d.getUTCDate()+1)) {
  if(d.getUTCDay()!==0&&d.getUTCDay()!==6)days.push(d.toISOString().slice(0,10));
}
const pattern=[.006,.003,-.004,.008,-.002,.005,.001,-.006,-.003,-.002,.007,.004,0,.003,-.005,.009];
const equity=days.map((date,i)=>({date,return_fraction:pattern[i%pattern.length],coverage_complete:true}));
const tradePattern=[.004,-.003,.007,.002,-.004,-.002,-.001,0,.005,.008,-.002,.003];
const symbols=['XAUUSD','EURUSD','US500'];
const trades=Array.from({length:48},(_,i)=>{
  const day=days[Math.floor(i*days.length/48)],symbol=symbols[i%3],side=i%2?'SELL':'BUY',r=tradePattern[i%12];
  const entry_price=symbol==='XAUUSD'?2500:symbol==='EURUSD'?1.12:5500;
  return {id:`SIM-${String(i+1).padStart(3,'0')}`,symbol,side,entry_price,exit_price:entry_price*(1+(side==='BUY'?r:-r)),open_volume:1,closed_volume:1,is_closed:true,coverage_complete:true,
    open_at:`${day}T10:00:00Z`,close_at:`${day}T${i%4===0?'15':'12'}:00:00Z`};
});
trades.push({...trades[0],id:'SIM-INCOMPLETA',coverage_complete:false});
const fixture={schemaVersion:1,id:'qrt-seminario3-kpi-lab-20261008',surface:'dashboard',title:'Trackrecord & Bitácora de Trading',buildStatus:'creating',status:'fixture',generatedAt:'2026-10-08T00:00:00Z',
  queries:{trades:{rows:trades,source:{label:'Operaciones simuladas QRT Solutions',files:[{label:'generate-fixture.mjs'},{label:'engine.mjs'}],summary:'48 operaciones cerradas ficticias y una operación incompleta para comprobar exclusiones.',metricDefinitions:[{label:'Retorno del precio',definition:'Movimiento porcentual entre precios medios de entrada y salida; signo invertido para ventas. No incluye lotaje, costes ni apalancamiento.'}],caveats:['Datos simulados; no representan la cuenta del docente.','Las operaciones y la serie diaria de cuenta son ejemplos independientes. No se reconcilian entre sí.']}},
    daily:{rows:equity,source:{label:'Serie diaria simulada QRT Solutions',files:[{label:'generate-fixture.mjs'},{label:'engine.mjs'}],summary:'40 sesiones ficticias de lunes a viernes; retornos normalizados de una cuenta sin depósitos ni retiros.',metricDefinitions:[{label:'Serie ajustada',definition:'Índice inicial 100 multiplicado por 1 más el retorno diario de cada sesión.'}],caveats:['Muestreo diario; no mide drawdown intradía.','Sharpe y Sortino anualizados con 252 sesiones y referencia/objetivo anual cero.','Una muestra corta sirve para demostrar el cálculo; no acredita robustez estadística.']}}}};
await writeFile(new URL('fixture.json',import.meta.url),JSON.stringify(fixture,null,2)+'\n');
console.log('Generated disconnected fixture: 49 trade rows and 40 daily observations.');
