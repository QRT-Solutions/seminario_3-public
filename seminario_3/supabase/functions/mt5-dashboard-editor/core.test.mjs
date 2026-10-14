// Author: QRT Solutions. No network calls or real credentials.
import test from 'node:test';import assert from 'node:assert/strict';
import {makeHandler,hash} from './core.mjs';
const origin='https://dashboard.example',code='a'.repeat(64),id='12345678-1234-4321-1234-123456789abc';
function fixture(result={ok:true,expires_at:'2099-01-01T00:00:00Z'}){
 const calls=[];const handler=makeHandler({configuration:async()=>({origin,bot_username:'test_bot'}),rpc:async(...args)=>{calls.push(args);return result;}});
 const send=(body,headers={},method='POST')=>handler(new Request('https://edge.example',{method,headers:{origin,'Content-Type':'application/json',...headers},body:method==='POST'?JSON.stringify(body):undefined}));return {calls,send,handler};
}
test('only configured origin and methods; preflight never authenticates',async()=>{
 const f=fixture();assert.equal((await f.send({action:'config'},{origin:'https://evil.example'})).status,403);
 assert.equal((await f.send({}, {},'OPTIONS')).status,204);assert.equal((await f.send({}, {},'GET')).status,405);assert.equal(f.calls.length,0);
});
test('login sends hashes only; session is random; no-store response',async()=>{
 const f=fixture();const r=await f.send({action:'login',code});const a=await r.json();
 assert.equal(r.headers.get('cache-control'),'no-store');assert.match(a.token,/^[a-f0-9]{64}$/);assert.notEqual(a.token,code);
 assert.deepEqual(f.calls[0],['login',await hash(code),{session_hash:await hash(a.token)}]);
});
test('anonymous, malformed credentials, unsupported and oversized input cannot call RPC',async()=>{
 const f=fixture();assert.equal((await f.send({action:'save'})).status,401);
 assert.equal((await f.send({action:'login',code:'1234'})).status,401);
 assert.equal((await f.send({action:'close_trade'})).status,400);
 assert.equal((await f.send({action:'config',large:'x'.repeat(17000)})).status,413);assert.equal(f.calls.length,0);
});
test('only whitelisted reason fields reach database; account and actor cannot be spoofed',async()=>{
 const f=fixture();const body={action:'save',journal_id:id,phase:'closing',reason:'  <literal>理由  ',request_id:id,expected_updated_at:'2026-10-08T00:00:00.123456Z',account_id:'victim',user_id:999,profit:999};
 assert.equal((await f.send(body,{Authorization:`Bearer ${code}`})).status,200);
 assert.deepEqual(f.calls[0],['save',await hash(code),{journal_id:id,phase:'closing',reason:'<literal>理由',request_id:id,expected_updated_at:body.expected_updated_at}]);
 for(const patch of [{phase:'price'},{reason:''},{reason:'x'.repeat(1001)},{request_id:'bad'}])assert.equal((await f.send({...body,...patch},{Authorization:`Bearer ${code}`})).status,400);
});
test('auth revocation and conflicts propagate without exposing internal errors',async()=>{
 assert.equal((await fixture({error:'unauthorized'}).send({action:'session'},{Authorization:`Bearer ${code}`})).status,401);
 assert.equal((await fixture({error:'conflict'}).send({action:'journal',journal_id:id},{Authorization:`Bearer ${code}`})).status,409);
 const f=makeHandler({configuration:async()=>{throw new Error('secret');},rpc:async()=>{}});const r=await f(new Request('https://edge.example'));assert.equal(r.status,503);assert.doesNotMatch(await r.text(),/secret/);
});

test('protection editing keeps session auth, rejects price changes and reports unfinished groups',async()=>{
 const f=fixture();const b={action:'save_protection',journal_id:id,phase:'protection',reason:'Reducir riesgo',request_id:id,expected_updated_at:'2026-10-08T00:00:00Z',new_sl:99};
 assert.equal((await f.send(b)).status,401);
 assert.equal((await f.send(b,{Authorization:`Bearer ${code}`})).status,200);
 assert.equal(f.calls[0][0],'save_protection');assert.equal('new_sl' in f.calls[0][2],false);
 assert.equal((await f.send({...b,phase:'closing'},{Authorization:`Bearer ${code}`})).status,400);
 assert.equal((await fixture({error:'group_pending'}).send(b,{Authorization:`Bearer ${code}`})).status,422);
});
