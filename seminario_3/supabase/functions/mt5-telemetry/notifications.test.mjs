// Author: QRT Solutions. Offline queue delivery; no messages are sent.
import test from 'node:test';
import assert from 'node:assert/strict';
import {deliverOpeningNotifications} from './notifications.mjs';
const row={id:'1',lease_token:'lease',reference:'abcd1234',chat_id:42,symbol:'EURUSD',direction:'BUY',volume:0.1,price:1.1};
test('opening prompt requests a direct reply and stores Telegram message id',async()=>{
  const sent=[],finished=[];
  await deliverOpeningNotifications('demo',{claim:async()=>[row],send:async x=>{sent.push(x);return {message_id:101};},finish:async(...x)=>finished.push(x)});
  assert.equal(sent[0].reply_markup.force_reply,true);assert.equal(sent[0].chat_id,42);
  assert.match(sent[0].text,/EURUSD/);assert.deepEqual(finished,[['1','lease',101]]);
});
test('failed send releases for retry, empty queue sends nothing',async()=>{
  const finished=[];
  await deliverOpeningNotifications('demo',{claim:async()=>[row],send:async()=>{throw Error('private upstream');},finish:async(...x)=>finished.push(x)});
  assert.deepEqual(finished,[['1','lease',null]]);
  await deliverOpeningNotifications('demo',{claim:async()=>[],send:async()=>assert.fail('no send'),finish:async()=>assert.fail('no finish')});
});
test('closing requests closing reason without treating the exit direction as a new position',async()=>{
  const sent=[];
  await deliverOpeningNotifications('demo',{claim:async()=>[{...row,phase:'closing',direction:'SELL'}],send:async x=>{sent.push(x);return {message_id:102};},finish:async()=>{}});
  assert.match(sent[0].text,/Cierre registrado/);assert.match(sent[0].text,/Salida ejecutada mediante venta/);
  assert.match(sent[0].text,/cerrar esta operación o reducir su volumen/);
  assert.equal(sent[0].reply_markup.input_field_placeholder,'Escribe tu razón de cierre');
  assert.doesNotMatch(sent[0].text,/Nueva apertura/);
});

test('grouped protection prompt carries old and new levels and bounded callback buttons',async()=>{
 const sent=[],finished=[];
 await deliverOpeningNotifications('demo',{claim:async()=>[{id:'3',lease_token:'lease',phase:'protection',protection_id:'11111111-2222-4333-8444-555555555555',chat_id:42,symbol:'TEST',reference:'abcd1234',old_sl:90,new_sl:0,old_tp:120,new_tp:130,changes:3}],send:async x=>{sent.push(x);return {message_id:9};},finish:async(...x)=>finished.push(x)});
 assert.match(sent[0].text,/90 → Sin nivel/);assert.match(sent[0].text,/3 cambio/);
 assert.ok(sent[0].reply_markup.inline_keyboard.flat().every(x=>Buffer.byteLength(x.callback_data)<=64));
 assert.equal(finished[0][2],9);
});
