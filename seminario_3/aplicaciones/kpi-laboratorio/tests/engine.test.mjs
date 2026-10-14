// Author: QRT Solutions. Independent known-value and edge-case checks.
import test from 'node:test';
import assert from 'node:assert/strict';
import {priceReturn,tradeStatistics,accountStatistics,selectTrades} from '../engine.mjs';
const close=(r,id='1')=>({id,symbol:'XAUUSD',side:'BUY',entry_price:100,exit_price:100*(1+r),open_volume:1,closed_volume:1,is_closed:true,coverage_complete:true,open_at:'2026-09-01T10:00:00Z',close_at:`2026-09-0${id}T11:00:00Z`});
const near=(a,b)=>assert.ok(Math.abs(a-b)<1e-10,`${a} != ${b}`);
test('Directional price returns and incomplete/partial trade exclusion',()=>{
  near(priceReturn(close(.02)),.02);near(priceReturn({...close(.02),side:'SELL'}),-.02);
  assert.equal(Object.is(priceReturn({...close(0),side:'SELL'}),-0),false);
  for(const patch of [{coverage_complete:false},{closed_volume:.5},{entry_price:null},{exit_price:''},{is_closed:false},{close_at:'2026-08-01'},{side:'OTHER'}]) assert.equal(priceReturn({...close(.02),...patch}),null);
});
test('Known four-trade statistics include a neutral',()=>{
  const x=tradeStatistics([close(.04,'1'),close(-.02,'2'),close(0,'3'),close(.02,'4')]);
  near(x.values.win_rate,.5);near(x.values.profit_factor,3);near(x.values.payoff,1.5);
  near(x.values.expectancy,.01);near(x.values.median,.01);near(x.values.deviation,Math.sqrt(.002/3));
  assert.equal(x.values.max_loss_streak,1);assert.equal(x.neutral,1);
});
test('Empty/constant/one-sided samples never invent ratios',()=>{
  assert.ok(Object.values(tradeStatistics([]).values).every(x=>x===null));
  assert.equal(tradeStatistics([close(.01)]).values.profit_factor,null);
  assert.equal(tradeStatistics([close(.01)]).values.deviation,null);
  assert.equal(tradeStatistics([close(-.01)]).values.profit_factor,0);
  assert.equal(tradeStatistics([close(-.01)]).values.payoff,null);
});
test('Streak chronological ordering, neutral reset and duplicate rejection',()=>{
  const x=tradeStatistics([close(-.01,'4'),close(-.01,'2'),close(-.02,'1'),close(0,'3')]);
  assert.equal(x.values.max_loss_streak,2);
  assert.equal(tradeStatistics([close(-.01,'1'),{...close(-.01,'2'),coverage_complete:false},close(-.01,'3')]).values.max_loss_streak,1);
  assert.throws(()=>tradeStatistics([close(.01),close(.02)]));
});
test('Known daily drawdown includes the initial baseline; ratios annualize daily',()=>{
  const x=accountStatistics([{date:'2026-09-01',return_fraction:.1,coverage_complete:true},{date:'2026-09-02',return_fraction:-.1,coverage_complete:true}]);
  near(x.values.max_drawdown,.1);near(x.values.sharpe,0);near(x.values.sortino,0);
  near(x.series.at(-1).index,.99);
  near(accountStatistics([{date:'2026-09-01',return_fraction:-.2,coverage_complete:true}]).values.max_drawdown,.2);
});
test('Missing daily returns stay unavailable; zero downside and zero variance guarded',()=>{
  assert.equal(accountStatistics([{date:'2026-09-01',return_fraction:null,coverage_complete:true}]).values.max_drawdown,null);
  const d=[{date:'2026-09-01',return_fraction:.01,coverage_complete:true},{date:'2026-09-02',return_fraction:.01,coverage_complete:true}];
  assert.equal(accountStatistics(d).values.sharpe,null);assert.equal(accountStatistics(d).values.sortino,null);
  assert.throws(()=>accountStatistics(d,{annualRiskFree:-1}));
});
test('Date and segment filters reconcile selected trade population',()=>{
  assert.equal(selectTrades([close(.01,'1'),{...close(.02,'2'),symbol:'EURUSD'}],{symbol:'EURUSD'}).length,1);
  assert.equal(selectTrades([close(.01,'1'),close(.02,'2')],{from:'2026-09-02',to:'2026-09-02'}).length,1);
});
test('Nonzero daily mean verifies Sharpe, downside normalization, and annualization',()=>{
  const rows=[.01,-.02,.03].map((r,i)=>({date:`2026-09-0${i+1}`,return_fraction:r,coverage_complete:true}));
  const x=accountStatistics(rows);
  near(x.values.sharpe,Math.sqrt(252)*(1/150)/Math.sqrt(19/30000));
  near(x.values.sortino,Math.sqrt(252)*(1/150)/Math.sqrt(.0004/3));
  assert.equal(accountStatistics([{...rows[0],date:'2026-02-31'}]).values.max_drawdown,null);
});
