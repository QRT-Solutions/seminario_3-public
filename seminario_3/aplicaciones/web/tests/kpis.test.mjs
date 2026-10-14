// Author: QRT Solutions. Synthetic cases; no account data.
import {test} from 'node:test';
import assert from 'node:assert/strict';
import {accountRisk,buildKpis} from '../src/kpis.mjs';
const account={equity:1000,balance:900,currency:'USD',margin:100,positions:[],open_positions_count:0};
test('ten KPI cards distinguish account state, undefined ratios, and absent history',()=>{
 const cards=buildKpis(account,null),get=id=>cards.find(c=>c.id===id);
 assert.equal(cards.length,10);assert.equal(new Set(cards.map(c=>c.id)).size,10);
 assert.equal(get('risk').value,'0,00 %');assert.match(get('margin').value,/1.000,00 %/);
 for(const id of ['drawdown','return','net','pf','win','payoff','expectancy'])assert.equal(get(id).value,'Sin datos');
 assert.equal(buildKpis({...account,margin:0},null).find(c=>c.id==='margin').value,'Sin margen utilizado');
});
test('risk never invents monetary valuation from SL price distance',()=>{
 assert.equal(accountRisk({...account,open_positions_count:1}).value,null);
 assert.equal(accountRisk({...account,equity:0}).value,null);
 assert.match(accountRisk({...account,open_positions_count:1,positions:[{sl:0}]}).reason,/no acotado/);
 assert.equal(accountRisk({...account,open_positions_count:1,positions:[{sl:100,current_price:110}]}).value,null);
});
test('genuine zero and unavailable ratios retain distinct meanings',()=>{
 const cards=buildKpis(account,{count:2,excluded:1,net:0,cumulative_return_pct:0,win_rate_pct:0,profit_factor_pct:0,profit_factor_money:null,payoff_pct:null,expectancy_pct:0});
 assert.equal(cards.find(c=>c.id==='net').value,'0,00 USD');
 assert.equal(cards.find(c=>c.id==='pf').value,'0,00×');
 assert.equal(cards.find(c=>c.id==='payoff').value,'Sin datos');
 assert.match(cards.find(c=>c.id==='return').note,/2 operaciones completas · 1 excluidas/);
});
