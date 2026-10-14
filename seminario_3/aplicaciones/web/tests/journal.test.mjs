// Author: QRT Solutions. Synthetic data tests; not shown in the dashboard.
import test from 'node:test';
import assert from 'node:assert/strict';
import {phaseDetails} from '../src/metrics.mjs';
test('keeps partial exits and reversals in the correct phases',()=>{
 const j={events:[{deal_entry:'IN'},{deal_entry:'OUT'},{deal_entry:'OUT_BY'},{deal_entry:'INOUT'}]};
 assert.equal(phaseDetails(j,'opening').events.length,2);
 assert.equal(phaseDetails(j,'closing').events.length,3);
});
test('human reasons and original MT5 comments remain separate and literal',()=>{
 const j={opening_reason:'Ruptura <b>confirmada</b>',closing_reason:'Cierre manual',events:[{deal_entry:'IN',deal_comment:'EA entry',order_comment:'Order entry'},{deal_entry:'OUT',deal_comment:'[tp]',order_comment:'[tp]'}]};
 const a=phaseDetails(j,'opening'),c=phaseDetails(j,'closing');
 assert.equal(a.reason,'Ruptura <b>confirmada</b>');assert.equal(a.comments.length,2);
 assert.equal(c.comments.length,1);assert.equal(c.comments[0].text,'[tp]');assert.equal(c.reason,'Cierre manual');
});
test('does not infer a close or a reason from absent data; distinguishes missing vs blank comments',()=>{
 const j={events:[{deal_entry:'IN',deal_comment:null,order_comment:null}]};
 assert.equal(phaseDetails(j,'closing').events.length,0);assert.equal(phaseDetails(j,'opening').reason,null);
 assert.equal(phaseDetails(j,'opening').received,false);
 j.events[0].deal_comment='';assert.equal(phaseDetails(j,'opening').received,true);
});
