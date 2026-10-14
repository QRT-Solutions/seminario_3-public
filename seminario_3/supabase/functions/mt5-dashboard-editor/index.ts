// Author: QRT Solutions. Secrets never reach the browser or logs.
import {makeHandler} from './core.mjs';
const base=Deno.env.get('SUPABASE_URL')||'';
const keys=JSON.parse(Deno.env.get('SUPABASE_SECRET_KEYS')||'{}');
const key=keys.default||Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')||'';
const headers:Record<string,string>={apikey:key,'Content-Type':'application/json'};
if(!keys.default)headers.Authorization=`Bearer ${key}`;
async function rest(path:string,body?:unknown){
 if(!key)throw new Error('unavailable');
 const response=await fetch(`${base}/rest/v1/${path}`,{method:body===undefined?'GET':'POST',headers,body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(8000),redirect:'error'});
 if(!response.ok)throw new Error('database_unavailable');return response.json();
}
Deno.serve(makeHandler({
 configuration:async()=>(await rest('mt5_dashboard_web_config?singleton=eq.true&select=origin,bot_username&limit=1'))[0],
 rpc:(action:string,hash:string,data:unknown)=>rest('rpc/mt5_dashboard_editor',{p_action:action,p_hash:hash,p_data:data}),
}));
