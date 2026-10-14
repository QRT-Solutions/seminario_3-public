// Author: QRT Solutions. Run with: node --test core.test.mjs
import test from 'node:test';
import assert from 'node:assert/strict';
import {makeHandler} from './core.mjs';

const token = 'mt5_' + 'a'.repeat(64); // Synthetic fixture, never provisioned remotely.
const grant = {login:'101',broker:'Example Broker',server:'Demo',account_id:'101_Example_Broker',
  project_name:'classroom',active:true,expires_at:'2099-01-01T00:00:00Z'};
const account = {login:grant.login,broker:grant.broker,server:grant.server};
const swap = {broker:grant.broker,symbol:'EURUSD',swap_long:-1,swap_short:0.5,swap_mode:1,triple_swap_day:3,updated_at:'2026-10-07T12:00:00Z'};
const deal = {deal_ticket:'18446744073709551615',order_ticket:'12',position_id:'34',account_id:grant.account_id,
  login:grant.login,broker:grant.broker,project_name:grant.project_name,symbol:'EURUSD',deal_type:'BUY',deal_entry:'OUT',
  volume:0.01,price:1.1,profit:5,commission:-1,swap:0,deal_time:'2026-10-07T12:00:00Z',approval_status:'APPROVED'};
const snapshot = {account_id:grant.account_id,login:grant.login,broker:grant.broker,server:grant.server,
  currency:'USD',account_type:'DEMO',margin_mode:'HEDGING',leverage:30,balance:100,equity:100,margin:0,
  margin_free:100,margin_level:0,profit_floating:0,open_positions_count:0,positions_json:[],
  updated_at:'2026-10-07T12:00:00Z',project_name:grant.project_name,terminal_closed_profit:0,
  terminal_total_deals:0,today_closed_profit:0,today_trades_count:0};
function setup(activeGrant=grant) {
  const writes=[]; const hashes=[];
  const handler=makeHandler({lookup:async hash => {hashes.push(hash); return activeGrant;},
    upsert:async (...args)=>writes.push(args),now:()=>new Date('2026-10-08T00:00:00Z')});
  const send=(payload,headers={},method='POST')=>handler(new Request('https://example.test/mt5-telemetry',{
    method,headers:{'Content-Type':'application/json','x-mt5-token':token,...headers},
    ...(method==='POST'?{body:typeof payload==='string'?payload:JSON.stringify(payload)}:{}),
  }));
  return {send,writes,hashes};
}
const payload=(resource='mt5_swap_rates',records=[swap])=>({resource,account:{...account},records});

test('rejects missing, malformed, unknown, revoked and expired credentials before writing',async()=>{
  for(const header of ['', 'wrong']) {
    const s=setup(); assert.equal((await s.send(payload(),{'x-mt5-token':header})).status,401);
    assert.equal(s.writes.length,0); assert.equal(s.hashes.length,0);
  }
  for(const g of [null,{...grant,active:false},{...grant,expires_at:'2000-01-01T00:00:00Z'}]) {
    const s=setup(g); assert.equal((await s.send(payload())).status,401); assert.equal(s.writes.length,0);
  }
});
test('checks envelope login, broker and server, and each record identity',async()=>{
  for(const field of ['login','broker','server']) {
    const s=setup(), p=payload(); p.account[field]='other';
    assert.equal((await s.send(p)).status,403); assert.equal(s.writes.length,0);
  }
  for(const field of ['account_id','login','broker','project_name']) {
    const s=setup(); const d={...deal,[field]:field==='login'?'999':'other'};
    assert.equal((await s.send(payload('mt5_deals',[d]))).status,403); assert.equal(s.writes.length,0);
  }
});
test('accepts three resources and preserves full uint64 ticket string',async()=>{
  for(const [table,row] of [['mt5_accounts_snapshot',snapshot],['mt5_deals',deal],['mt5_swap_rates',swap]]) {
    const s=setup(); const r=await s.send(payload(table,[row])); assert.equal(r.status,200);
    assert.equal(s.writes[0][0],table); assert.equal(s.writes[0][2][0].received_at,'2026-10-08T00:00:00.000Z');
    assert.match(s.hashes[0],/^[a-f0-9]{64}$/); assert.notEqual(s.hashes[0],token);
    if(table==='mt5_deals') assert.equal(s.writes[0][2][0].deal_ticket,deal.deal_ticket);
  }
});
test('rejects arbitrary tables, commands, injected columns, unsafe IDs and invalid data',async()=>{
  const cases=[payload('mt5_commands'),payload('__proto__'),payload('mt5_swap_rates',[{...swap,active:true}]),
    payload('mt5_deals',[{...deal,deal_ticket:9007199254740992}]),payload('mt5_swap_rates',[{...swap,swap_long:'NaN'}]),
    payload('mt5_accounts_snapshot',[{...snapshot,positions_json:[{ticket:'1'}]}])];
  for(const p of cases) { const s=setup(); assert.equal((await s.send(p)).status,400); assert.equal(s.writes.length,0); }
});
test('deduplicates a batch and fixes conflict keys independently of client input',async()=>{
  const s=setup(); const r=await s.send(payload('mt5_deals',[deal,{...deal,profit:7}]));
  assert.equal((await r.json()).accepted,1); assert.equal(s.writes[0][1],'deal_ticket');
  assert.equal(s.writes[0][2][0].profit,7);
});
test('rejects malformed JSON, oversized bodies, unsupported methods and large batches',async()=>{
  const s=setup();
  assert.equal((await s.send('{')).status,400);
  assert.equal((await s.send(' '.repeat(524289))).status,413);
  assert.equal((await s.send(null,{},'GET')).status,405);
  assert.equal((await s.send(payload(),{'Content-Type':'text/plain'})).status,415);
  assert.equal((await s.send(payload('mt5_swap_rates',Array(101).fill(swap)))).status,400);
  assert.equal(s.writes.length,0);
});
test('does not disclose database errors or tokens',async()=>{
  const handler=makeHandler({lookup:async()=>{throw new Error('private database details');},upsert:async()=>{}});
  const r=await handler(new Request('https://example.test',{method:'POST',headers:{'x-mt5-token':token},body:'{}'}));
  assert.equal(r.status,503); assert.deepEqual(await r.json(),{error:'temporarily_unavailable'});
});
test('accepts original comments, precise magic and close-by without inventing reasons',async()=>{
  const s=setup(); const journal={...deal,deal_entry:'OUT_BY',deal_comment:'EA "ruptura"\nTP',order_comment:'señal α',deal_reason:'DEAL_REASON_TP',magic:'18446744073709551615'};
  assert.equal((await s.send(payload('mt5_deals',[journal]))).status,200);
  assert.equal(s.writes[0][2][0].deal_comment,journal.deal_comment);
  for(const patch of [{magic:123},{deal_comment:'x'.repeat(1025)},{deal_reason:'invented'},{opening_reason:'Injected manual reason'}]){
    const bad=setup();assert.equal((await bad.send(payload('mt5_deals',[{...journal,...patch}]))).status,400);assert.equal(bad.writes.length,0);
  }
  const missing=setup();assert.equal((await missing.send(payload('mt5_deals',[{...deal,deal_comment:'partial'}]))).status,400);
});

test('stable position identifier is optional for old EAs and validated exactly for new EAs',async()=>{
 const position={ticket:'22',position_id:'18446744073709551615',symbol:'TEST',type:'BUY',volume:1,open_price:1,current_price:1,sl:0,tp:2,profit:0,swap:0};
 for(const id of ['18446744073709551615','0','not-an-id',22]){
  const p={...position,position_id:id};const s=setup();
  const r=await s.send(payload('mt5_accounts_snapshot',[{...snapshot,open_positions_count:1,positions_json:[p]}]));
  assert.equal(r.status,id==='18446744073709551615'?200:400);
 }
 delete position.position_id;
 assert.equal((await setup().send(payload('mt5_accounts_snapshot',[{...snapshot,open_positions_count:1,positions_json:[position]}]))).status,200);
});
