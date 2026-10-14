// Author: QRT Solutions. Synthetic full-filter server payloads.
import {test} from 'node:test';
import assert from 'node:assert/strict';
import {performanceModels} from '../src/performance-charts.mjs';
const stats={count:3,excluded:1,charts:{version:1,curve:[
 {trade_from:1,trade_to:1,closed_from:'2026-01-01T10:00:00',closed_to:'2026-01-01T10:00:00',cumulative_return_pct:10,cumulative_long_pct:10,cumulative_short_pct:0,cumulative_net:8},
 {trade_from:2,trade_to:3,closed_from:'2026-01-02T10:00:00',closed_to:'2026-01-03T10:00:00',cumulative_return_pct:0,cumulative_long_pct:10,cumulative_short_pct:-10,cumulative_net:-7}],
 histogram_return:[{lower:-10,upper:0,count:1},{lower:0,upper:10,count:2}],
 histogram_net:[{lower:-12,upper:-2,count:2},{lower:-2,upper:8,count:1}]}};
test('four charts preserve full-filter results, a zero baseline, and original close order',()=>{
 const models=performanceModels(stats,'EUR');assert.equal(models.length,4);
 assert.deepEqual(models[0].datasets[0].data,[{x:0,y:0},{x:1,y:10},{x:3,y:0}]);
 assert.equal(models[1].unit,'EUR');assert.equal(models[1].datasets[0].data.at(-1).y,-7);
 assert.equal(models[0].datasets[1].data.at(-1).y+models[0].datasets[2].data.at(-1).y,models[0].datasets[0].data.at(-1).y);
 for(const m of models.slice(2))assert.equal(m.datasets[0].data.reduce((s,v)=>s+v,0),3);
 assert.equal(models[1].table[1][0],'2 / 3');
});
test('empty and older payloads cannot fabricate charts',()=>{
 for(const s of [null,{}, {count:3},{...stats,count:0}])assert.deepEqual(performanceModels(s),[]);
});
test('unavailable money stays null rather than zero; constant bins retain frequency',()=>{
 const s=structuredClone(stats);s.charts.curve[1].cumulative_net=null;
 s.charts.histogram_return=[{lower:0,upper:0,count:3}];
 const m=performanceModels(s);
 assert.equal(m[1].datasets[0].data.at(-1).y,null);assert.equal(m[1].table[1][2],'Sin datos');
 assert.deepEqual(m[2].labels,['0']);assert.deepEqual(m[2].datasets[0].data,[3]);
});
