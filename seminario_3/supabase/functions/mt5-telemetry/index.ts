// Author: QRT Solutions. Custom device authentication is enforced in core.mjs.
import {makeHandler} from './core.mjs';
import {deliverOpeningNotifications} from './notifications.mjs';
declare const EdgeRuntime: {waitUntil(promise:Promise<unknown>):void};

const base = Deno.env.get('SUPABASE_URL')!;
const keys = JSON.parse(Deno.env.get('SUPABASE_SECRET_KEYS') || '{}');
const modernKey = keys.default;
const key = modernKey || Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
const headers: Record<string, string> = {'Content-Type': 'application/json', apikey: key};
if (!modernKey) headers.Authorization = `Bearer ${key}`;

async function rest(path: string, init: RequestInit = {}) {
  const result = await fetch(`${base}/rest/v1/${path}`, {
    ...init, headers: {...headers, ...init.headers},
    signal: AbortSignal.timeout(8000), redirect: 'error',
  });
  if (!result.ok) throw new Error('database_unavailable');
  return result;
}

Deno.serve(makeHandler({
  afterWrite: async (account: string) => {
    const token=Deno.env.get('TELEGRAM_BOT_TOKEN');
    if(!token) return;
    const rpc=async (name:string,body:unknown)=>(await rest(`rpc/${name}`,{method:'POST',body:JSON.stringify(body)})).json();
    EdgeRuntime.waitUntil(deliverOpeningNotifications(account,{
      claim:(id:string)=>rpc('mt5_claim_opening_notifications',{p_account_id:id}),
      finish:(id:string,lease:string,message:number|null)=>rpc('mt5_finish_opening_notification',{p_id:id,p_lease:lease,p_message_id:message}),
      send:async (body:unknown)=>{
        const r=await fetch(`https://api.telegram.org/bot${token}/sendMessage`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body),signal:AbortSignal.timeout(5000),redirect:'error'});
        const data=await r.json();if(!r.ok || !data.ok)throw new Error('telegram_unavailable');return data.result;
      },
    }).catch(()=>{}));
  },
  lookup: async (hash: string) => {
    const select = 'login,broker,server,account_id,project_name,active,expires_at';
    const result = await rest(`mt5_ingest_credentials?token_sha256=eq.${hash}&select=${select}&limit=1`);
    return (await result.json())[0] ?? null;
  },
  upsert: async (table: string, conflict: string, records: unknown[]) => {
    await rest(`${table}?on_conflict=${encodeURIComponent(conflict)}`, {
      method: 'POST', headers: {Prefer: 'resolution=merge-duplicates,return=minimal'},
      body: JSON.stringify(records),
    });
  },
}));
