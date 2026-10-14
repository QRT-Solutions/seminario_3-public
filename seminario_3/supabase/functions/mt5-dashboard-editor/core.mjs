// Author: QRT Solutions. Custom single-use-code authentication; server-bound scope.
export async function hash(value){return [...new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(value)))].map(x=>x.toString(16).padStart(2,'0')).join('');}
const random=()=>[...crypto.getRandomValues(new Uint8Array(32))].map(x=>x.toString(16).padStart(2,'0')).join('');
const hex=/^[a-f0-9]{64}$/;
const uuid=/^[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}$/i;
async function readBody(req){
 const reader=req.body?.getReader();if(!reader)throw new Error('body');let size=0,text='';const decoder=new TextDecoder();
 for(;;){const {done,value}=await reader.read();if(done)break;size+=value.length;if(size>16384){await reader.cancel();throw new RangeError('body');}text+=decoder.decode(value,{stream:true});}
 return JSON.parse(text+decoder.decode());
}
export function makeHandler({configuration,rpc}){return async req=>{
 let headers={'Content-Type':'application/json','Cache-Control':'no-store','Vary':'Origin','X-Content-Type-Options':'nosniff'};
 const reply=(data,status=200)=>new Response(JSON.stringify(data),{status,headers});
 try{
  const config=await configuration(),origin=req.headers.get('origin');
  if(!config||origin!==config.origin)return reply({error:'origin_denied'},403);
  headers={...headers,'Access-Control-Allow-Origin':origin,'Access-Control-Allow-Methods':'POST, OPTIONS','Access-Control-Allow-Headers':'content-type, authorization, apikey'};
  if(req.method==='OPTIONS')return new Response(null,{status:204,headers});
  if(req.method!=='POST')return reply({error:'method_not_allowed'},405);
  let body;try{body=await readBody(req);}catch(e){return reply({error:'invalid_input'},e instanceof RangeError?413:400);}
  if(!body||typeof body!=='object'||Array.isArray(body))return reply({error:'invalid_input'},400);
  const {action}=body;
  if(action==='config')return reply({bot_username:config.bot_username});
  if(!['login','session','journal','save','protection','save_protection','logout'].includes(action))return reply({error:'invalid_input'},400);
  let credential,data={},session;
  if(action==='login'){
   if(typeof body.code!=='string'||!hex.test(body.code))return reply({error:'unauthorized'},401);
   credential=body.code;session=random();data.session_hash=await hash(session);
  }else{
   credential=req.headers.get('authorization')?.replace(/^Bearer /,'');
   if(!credential||!hex.test(credential))return reply({error:'unauthorized'},401);
   if(['journal','save','protection','save_protection'].includes(action)){
    if(typeof body.journal_id!=='string'||!uuid.test(body.journal_id))return reply({error:'invalid_input'},400);
    data.journal_id=body.journal_id;
   }
   if(action==='save'||action==='save_protection'){
    if(!(action==='save_protection'?body.phase==='protection':['opening','closing'].includes(body.phase))||typeof body.reason!=='string'||![...body.reason.trim()].length||[...body.reason.trim()].length>1000||!uuid.test(body.request_id||'')||typeof body.expected_updated_at!=='string'||body.expected_updated_at.length>50)return reply({error:'invalid_input'},400);
    data={...data,phase:body.phase,reason:body.reason.trim(),request_id:body.request_id,expected_updated_at:body.expected_updated_at};
   }
  }
  const result=await rpc(action,await hash(credential),data);
  if(result.error)return reply({error:result.error},{unauthorized:401,conflict:409,not_found:404,phase_unavailable:422,group_pending:422,invalid_input:400}[result.error]||500);
  return reply(session?{...result,token:session}:result);
 }catch{return reply({error:'unavailable'},503);}
};}
