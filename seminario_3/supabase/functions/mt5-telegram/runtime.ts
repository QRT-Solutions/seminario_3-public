// Author: QRT Solutions. Credentials remain inside Supabase Edge secrets.
import {makeHandler,webhookSecret,equalSecret,sha256} from './core.mjs';
const base=Deno.env.get('SUPABASE_URL') || '';
const token=Deno.env.get('TELEGRAM_BOT_TOKEN') || '';
const keys=JSON.parse(Deno.env.get('SUPABASE_SECRET_KEYS') || '{}');
const key=keys.default || Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
const headers:Record<string,string>={'Content-Type':'application/json',apikey:key};
if(!keys.default) headers.Authorization=`Bearer ${key}`;

async function rest(path:string,body?:unknown) {
  const r=await fetch(`${base}/rest/v1/${path}`,{method:body===undefined?'GET':'POST',headers,
    ...(body===undefined?{}:{body:JSON.stringify(body)}),signal:AbortSignal.timeout(8000),redirect:'error'});
  if(!r.ok) {
    const data=await r.json().catch(()=>({}));
    const error=new Error('database_request_failed');
    if(['22023','42501'].includes(data.code)) error.name='InputError';
    throw error;
  }
  return r.json();
}
export async function telegram(method:string,body:unknown={}) {
  if(!token) throw new Error('missing_bot_token');
  const r=await fetch(`https://api.telegram.org/bot${token}/${method}`,{method:'POST',
    headers:{'Content-Type':'application/json'},body:JSON.stringify(body),signal:AbortSignal.timeout(8000),redirect:'error'});
  const result=await r.json(); if(!r.ok || !result.ok) throw new Error('telegram_request_failed');
  return result.result;
}
export const secret=token?await webhookSecret(token):'';
export const webhookURL=`${base}/functions/v1/mt5-telegram`;
let username='';
export async function handle(req:Request) {
  // Authenticate before contacting Telegram or the database.
  if(!token || !key) return new Response('unavailable',{status:503});
  if(req.method!=='POST') return new Response('method_not_allowed',{status:405});
  if(!equalSecret(req.headers.get('x-telegram-bot-api-secret-token'),secret)) return new Response('unauthorized',{status:401});
  try {
    if(!username) username=(await telegram('getMe')).username;
    return await makeHandler({secret,botUsername:username,
      lookup:(user:number,chat:number)=>rest(`mt5_telegram_editors?user_id=eq.${user}&chat_id=eq.${chat}&active=eq.true&select=account_id&limit=2`),
      claim:(hash:string,user:number,chat:number)=>rest('rpc/mt5_claim_telegram_pairing',{p_hash:hash,p_user_id:user,p_chat_id:chat}),
      journals:(account:string,user:number,chat:number,reference:string|null)=>rest('rpc/mt5_telegram_journals',{p_account_id:account,p_user_id:user,p_chat_id:chat,p_reference:reference}),
      issueWebCode:async(account:string,user:number,chat:number,update:number)=>{
        // Deterministic HMAC makes Telegram retries return the same code, without storing plaintext.
        const encoder=new TextEncoder();
        const signingKey=await crypto.subtle.importKey('raw',encoder.encode(token),{name:'HMAC',hash:'SHA-256'},false,['sign']);
        const context=JSON.stringify(['QRT Solutions:dashboard-code:v1',account,user,chat,update]);
        const code=[...new Uint8Array(await crypto.subtle.sign('HMAC',signingKey,encoder.encode(context)))].map(x=>x.toString(16).padStart(2,'0')).join('');
        const result=await rest('rpc/mt5_issue_dashboard_code',{p_hash:await sha256(code),p_account:account,p_user:user,p_chat:chat,p_update:update});
        return {...result,code};
      },
      protections:(body:unknown)=>rest('rpc/mt5_telegram_protections',body),
      answerCallback:(id:string,text:string)=>telegram('answerCallbackQuery',{callback_query_id:id,text}),
      record:(body:unknown)=>rest('rpc/mt5_record_trade_reason',body),
      promptReference:(account:string,user:number,chat:number,message:number)=>rest('rpc/mt5_telegram_prompt_reference',{p_account_id:account,p_user_id:user,p_chat_id:chat,p_message_id:message}),
      reply:(chat:number,text:string)=>telegram('sendMessage',{chat_id:chat,text,link_preview_options:{is_disabled:true}}),
    })(req);
  }catch {return new Response('temporarily_unavailable',{status:503});}
}
