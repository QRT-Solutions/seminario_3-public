// Author: QRT Solutions. No real Telegram messages or database writes.
import test from 'node:test';
import assert from 'node:assert/strict';
import {makeHandler,sha256,webhookSecret} from './core.mjs';
const secret='a'.repeat(64);
function fixture(overrides={}) {
  const calls=[],answers=[];
  const deps={secret,botUsername:'test_bot',
    lookup:async(...a)=>{calls.push(['lookup',...a]);return [{account_id:'demo'}];},
    claim:async(...a)=>{calls.push(['claim',...a]);return true;},
    journals:async(...a)=>{calls.push(['journals',...a]);return [{reference:'abcd1234',symbols:'EURUSD',has_opening:true,has_closing:false}];},
    record:async a=>{calls.push(['record',a]);return {ok:true};},
    reply:async(...a)=>{answers.push(a);},...overrides};
  const handler=makeHandler(deps);
  const send=(text='/ayuda',patch={},auth=secret)=>handler(new Request('https://example.test',{method:'POST',headers:{'x-telegram-bot-api-secret-token':auth},body:JSON.stringify({update_id:4,message:{chat:{id:42,type:'private'},from:{id:42,is_bot:false},text},...patch})}));
  return {handler,send,calls,answers};
}
test('rejects missing/invalid webhook auth before database and replies',async()=>{
  const f=fixture();assert.equal((await f.send('/pendientes',{},'wrong')).status,401);
  assert.equal(f.calls.length,0);assert.equal(f.answers.length,0);
  assert.equal((await fixture({secret:''}).send()).status,503);
});
test('ignores groups, edited messages, unsafe ids and wrong bot commands',async()=>{
  for(const message of [undefined,{chat:{id:-1,type:'group'},from:{id:42},text:'/pendientes'},
    {chat:{id:43,type:'private'},from:{id:42},text:'/pendientes'}]) {
    const f=fixture();assert.equal((await f.send('',{message})).status,200);assert.equal(f.calls.length,0);
  }
  const f=fixture();await f.send('/pendientes@other_bot');assert.equal(f.calls.length,0);
});
test('unlinked users cannot read or write reasons',async()=>{
  const f=fixture({lookup:async()=>[]});await f.send('/apertura abcd1234 motivo');await f.send('/pendientes');
  assert.equal(f.calls.length,0);assert.equal(f.answers.length,0);
  await f.send('/start');assert.match(f.answers[0][1],/vincular/);
});
test('pairing passes only SHA256 and private identity',async()=>{
  const f=fixture(),code='b'.repeat(32);await f.send(`/vincular ${code}`);
  assert.deepEqual(f.calls[0],['claim',await sha256(code),42,42]);
  await f.send('/vincular invalid');assert.equal(f.calls.length,1);
});
test('opening and closing preserve literal reason and use bound account',async()=>{
  const f=fixture();await f.send('/apertura abcd1234 Ruptura <b>real</b>\nSin inventar.');
  const record=f.calls.find(x=>x[0]==='record')[1];
  assert.deepEqual(record,{p_account_id:'demo',p_reference:'abcd1234',p_phase:'opening',p_reason:'Ruptura <b>real</b>\nSin inventar.',p_user_id:42,p_chat_id:42,p_update_id:4});
  await f.send('/cierre abcd1234 Salida manual');assert.equal(f.calls.at(-1)[1].p_phase,'closing');
});
test('bad reference, empty or oversized reason never writes',async()=>{
  for(const command of ['/cierre unknown reason','/apertura abcd1234','/cierre abcd1234 '+ 'x'.repeat(1001)]) {
    const f=fixture();await f.send(command);assert.equal(f.calls.filter(x=>x[0]==='record').length,0);
  }
});
test('pending and detail use server-bound account and requested phase exists',async()=>{
  const f=fixture();await f.send('/pendientes');assert.match(f.answers[0][1],/Falta: apertura/);
  await f.send('/ver abcd1234');assert.match(f.answers[1][1],/Sin ejecución de cierre recibida/);
  assert.deepEqual(f.calls.at(-1),['journals','demo',42,42,'abcd1234']);
});
test('duplicate write reports duplicate; transient failure retries without leaking',async()=>{
  const f=fixture({record:async()=>({duplicate:true})});await f.send('/cierre abcd1234 razón');assert.match(f.answers[0][1],/ya fue procesado/);
  const failed=fixture({lookup:async()=>{throw new Error('SECRET');}});
  const r=await failed.send();assert.equal(r.status,503);assert.doesNotMatch(await r.text(),/SECRET/);
});
test('invalid JSON and oversized streams are rejected',async()=>{
  const f=fixture();for(const [body,status] of [['{',400],['x'.repeat(65537),413]]) {
    const r=await f.handler(new Request('https://example.test',{method:'POST',headers:{'x-telegram-bot-api-secret-token':secret},body}));assert.equal(r.status,status);
  }assert.equal(f.calls.length,0);
});
test('derived webhook secret is deterministic, domain-separated and rotates with token',async()=>{
  const a=await webhookSecret('test-token');assert.match(a,/^[a-f0-9]{64}$/);
  assert.equal(a,await webhookSecret('test-token'));assert.notEqual(a,await webhookSecret('other-token'));
  assert.notEqual(a,await sha256('test-token'));
});
test('direct reply resolves stored prompt ownership instead of trusting quoted text',async()=>{
  const f=fixture({promptReference:async(...args)=>{assert.deepEqual(args,['demo',42,42,101]);return {reference:'abcd1234',phase:'opening'};}});
  await f.send('',{message:{chat:{id:42,type:'private'},from:{id:42},text:'Ruptura confirmada',reply_to_message:{message_id:101,from:{is_bot:true,username:'test_bot'},text:'untrusted arbitrary text'}}});
  const r=f.calls.find(x=>x[0]==='record')[1];assert.equal(r.p_reason,'Ruptura confirmada');assert.equal(r.p_reference,'abcd1234');
});
test('unknown prompt and revoked user cannot save direct reply',async()=>{
  const message={chat:{id:42,type:'private'},from:{id:42},text:'Motivo',reply_to_message:{message_id:101,from:{is_bot:true,username:'test_bot'}}};
  const f=fixture();await f.send('',{message});assert.equal(f.calls.filter(x=>x[0]==='record').length,0);
  const g=fixture({lookup:async()=>[],promptReference:async()=>assert.fail('revoked lookup')});await g.send('',{message});
  assert.equal(g.calls.length,0);
});
test('reply to closing prompt writes closing phase and confirms closing',async()=>{
  const f=fixture({promptReference:async()=>({reference:'abcd1234',phase:'closing'})});
  await f.send('',{message:{chat:{id:42,type:'private'},from:{id:42},text:'Salida por invalidación',reply_to_message:{message_id:102,from:{is_bot:true,username:'test_bot'}}}});
  const record=f.calls.find(x=>x[0]==='record')[1];
  assert.equal(record.p_phase,'closing');assert.equal(record.p_reason,'Salida por invalidación');
  assert.match(f.answers[0][1],/Razón de cierre registrada/);
});
test('dashboard code requires exactly one active binding and stays in private reply',async()=>{
 let issued=0;const issueWebCode=async(...args)=>{issued++;assert.deepEqual(args,['demo',42,42,4]);return {valid:true,code:'c'.repeat(64)};};
 const denied=fixture({lookup:async()=>[],issueWebCode});await denied.send('/dashboard');assert.equal(issued,0);
 const allowed=fixture({issueWebCode});await allowed.send('/dashboard');assert.equal(issued,1);assert.match(allowed.answers[0][1],/c{64}/);assert.match(allowed.answers[0][1],/cinco|5 minutos/);
});

const protection='11111111-2222-4333-8444-555555555555';
test('protection replies use stored group ownership and preserve free text',async()=>{
 const saved=[];const f=fixture({promptReference:async()=>({phase:'protection',protection_id:protection,reference:'abcd1234'}),protections:async p=>{saved.push(p);return {ok:true};}});
 await f.send('',{message:{chat:{id:42,type:'private'},from:{id:42},text:'Noticia: dato publicado; https://example.test',reply_to_message:{message_id:11,from:{is_bot:true,username:'test_bot'}}}});
 assert.equal(saved[0].p_id,protection);assert.match(saved[0].p_reason,/Noticia:/);assert.equal(saved[0].p_account,'demo');
});
test('protection callback cannot select a different group or another chat',async()=>{
 let writes=0;const f=fixture({promptReference:async()=>({protection_id:'other'}),protections:async()=>{writes++;return {ok:true};}});
 const callback_query={id:'callback',from:{id:42},message:{message_id:5,chat:{type:'private',id:42}},data:`p:${protection}:risk`};
 await f.send('',{callback_query});assert.equal(writes,0);
 callback_query.message.chat.id=43;await f.send('',{callback_query});assert.equal(writes,0);
});
test('risk button writes the selected reason; news and later never invent reasons',async()=>{
 const saved=[],acked=[];const f=fixture({promptReference:async()=>({protection_id:protection}),protections:async p=>{saved.push(p);return {ok:true};},answerCallback:async(...a)=>acked.push(a)});
 for(const kind of ['risk','news','later'])await f.send('',{callback_query:{id:'cb',from:{id:42},message:{message_id:5,chat:{type:'private',id:42}},data:`p:${protection}:${kind}`}});
 assert.equal(saved.length,1);assert.equal(saved[0].p_reason,'Reducir riesgo');assert.equal(acked.length,3);assert.match(f.answers[0][1],/noticia/);
});
test('protection command is scoped and permits a corrected explanation',async()=>{
 const saved=[];const f=fixture({protections:async p=>{saved.push(p);return {ok:true};}});
 await f.send(`/proteccion ${protection} Corrección de mi explicación`);assert.equal(saved[0].p_id,protection);
 await f.send('/proteccion invalid texto');assert.equal(saved.length,1);
});
