// Author: QRT Solutions. Synthetic fixtures used ONLY in automated tests.
import {test} from 'node:test';
import assert from 'node:assert/strict';
import {number,net,summarize,selectDeals,freshness} from '../src/metrics.mjs';
const deals=[
 {symbol:'A',deal_entry:'OUT',deal_time:'2026-01-01T09:00:00',profit:10,commission:-2,swap:-1},
 {symbol:'B',deal_entry:'OUT',deal_time:'2026-01-02T09:00:00',profit:-5,commission:-1,swap:0},
 {symbol:'A',deal_entry:'IN',deal_time:'2026-01-03T09:00:00',profit:0,commission:-.5,swap:0}
];
test('includes entry commission without pretending entry is a closed trade',()=>{
 const m=summarize(deals);assert.equal(m.count,3);assert.equal(m.net,.5);assert.deepEqual(m.sequence,[7,1,.5]);assert.deepEqual(m.bySymbol,[{symbol:'A',net:6.5},{symbol:'B',net:-6}]);
 assert.equal(m.profit+m.commission+m.swap,m.net);
});
test('intersects symbol, execution and inclusive broker dates consistently',()=>{
 const selected=selectDeals(deals,{symbol:'A',entry:'OUT',from:'2026-01-01',to:'2026-01-02'});
 assert.equal(selected.length,1);assert.equal(summarize(selected).net,7);
 assert.equal(selectDeals(deals,{from:'2026-02-01'}).length,0);
});
test('missing financial values remain unavailable, real zero remains zero',()=>{
 assert.equal(number(null),null);assert.equal(number(''),null);assert.equal(number(false),null);assert.equal(number('0'),0);
 assert.equal(net({...deals[0],commission:null}),null);
 const m=summarize([deals[0],{...deals[1],profit:null},deals[2]]);
 assert.equal(m.net,null);assert.deepEqual(m.sequence,[7,null,null]);
 assert.equal(summarize([]).net,0);
});
test('stale receiver is distinguished from a successful dashboard fetch',()=>{
 assert.equal(freshness('2026-01-01T00:00:00Z',Date.parse('2026-01-01T00:01:00Z')).fresh,true);
 assert.equal(freshness('2026-01-01T00:00:00Z',Date.parse('2026-01-01T00:02:01Z')).fresh,false);
 assert.equal(freshness('invalid').fresh,false);
});
