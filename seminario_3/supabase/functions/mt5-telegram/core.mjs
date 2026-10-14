// Author: QRT Solutions. Telegram edits journal reasons only; no trading commands.
const encoder = new TextEncoder();
export async function sha256(text) {
  return [...new Uint8Array(await crypto.subtle.digest('SHA-256', encoder.encode(text)))].map(x => x.toString(16).padStart(2,'0')).join('');
}
export async function webhookSecret(token) {
  const key = await crypto.subtle.importKey('raw', encoder.encode(token), {name:'HMAC',hash:'SHA-256'},false,['sign']);
  return [...new Uint8Array(await crypto.subtle.sign('HMAC',key,encoder.encode('QRT Solutions:mt5-telegram:webhook:v1')))].map(x=>x.toString(16).padStart(2,'0')).join('');
}
export function equalSecret(a,b) {
  if (!a || !b || a.length!==b.length) return false;
  let diff=0; for(let i=0;i<a.length;i++) diff|=a.charCodeAt(i)^b.charCodeAt(i);
  return diff===0;
}
const UUID=/^[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}$/;
const HELP = 'Bitácora MT5\n/protecciones — cambios de SL/TP pendientes\n/proteccion ID motivo — completar o corregir un cambio\n/dashboard — código privado para editar en la web\n/pendientes — hasta 20 operaciones con motivos pendientes\n/ver REFERENCIA — consultar motivos\n/apertura REFERENCIA motivo\n/cierre REFERENCIA motivo\nLos motivos se publican si tu dashboard es público. /cierre documenta una salida; no cierra posiciones. No admite audios ni ejecuta órdenes.';
const ok = () => new Response('ok');
const positive = n => Number.isSafeInteger(n) && n>0;

async function bodyText(req) {
  const reader=req.body?.getReader(); if(!reader) throw new Error('invalid_body');
  const chunks=[]; let size=0;
  for(;;) { const {done,value}=await reader.read(); if(done) break;
    size+=value.length; if(size>65536) {await reader.cancel(); throw new RangeError('body_size');} chunks.push(value);
  }
  const bytes=new Uint8Array(size);let at=0;for(const chunk of chunks){bytes.set(chunk,at);at+=chunk.length;}
  return new TextDecoder().decode(bytes);
}

export function makeHandler({secret,botUsername,lookup,claim,journals,record,reply,issueWebCode,promptReference=async()=>null,protections=async()=>[],answerCallback=async()=>{}}) {
  return async req => {
    if(req.method!=='POST') return new Response('method_not_allowed',{status:405});
    if(!secret) return new Response('unavailable',{status:503});
    if(!equalSecret(req.headers.get('x-telegram-bot-api-secret-token'),secret)) return new Response('unauthorized',{status:401});
    let update;
    try {update=JSON.parse(await bodyText(req));} catch(e) {return new Response('invalid_body',{status:e instanceof RangeError?413:400});}
    if(!update || !Number.isSafeInteger(update.update_id) || update.update_id<0) return new Response('invalid_update',{status:400});
    const cb=update.callback_query;
    if(cb){
      const m=cb.message;
      if(!m||m.chat?.type!=='private'||!positive(cb.from?.id)||cb.from.is_bot||cb.from.id!==m.chat.id||typeof cb.id!=='string')return ok();
      try{
        const accounts=await lookup(cb.from.id,m.chat.id);
        const parts=typeof cb.data==='string'?cb.data.match(/^p:([a-f0-9-]{36}):(risk|structure|news|other|later)$/):null;
        if(accounts.length!==1||!parts||!UUID.test(parts[1])){await answerCallback(cb.id,'Acción no disponible.');return ok();}
        const target=await promptReference(accounts[0].account_id,cb.from.id,m.chat.id,m.message_id);
        if(target?.protection_id!==parts[1]){await answerCallback(cb.id,'Aviso no autorizado.');return ok();}
        const kind=parts[2];
        if(['risk','structure'].includes(kind)){
          const r=await protections({p_account:accounts[0].account_id,p_user:cb.from.id,p_chat:m.chat.id,p_id:parts[1],p_reason:kind==='risk'?'Reducir riesgo':'Cambio de estructura',p_update:update.update_id});
          await answerCallback(cb.id,r.error?'No se pudo guardar.':r.stale?'Respuesta antigua; motivo conservado.':'Motivo registrado.');
        }else{
          await answerCallback(cb.id,kind==='later'?'Queda pendiente en /protecciones.':'Responde al aviso con tu explicación.');
          if(kind!=='later')await reply(m.chat.id,`${kind==='news'?'Indica qué noticia influyó; puedes incluir un enlace.':'Escribe tu explicación.'} Responde al aviso original o envía:\n/proteccion ${parts[1]} TU EXPLICACIÓN`);
        }
        return ok();
      }catch{return new Response('temporarily_unavailable',{status:503});}
    }
    const m=update.message;
    if(!m || m.chat?.type!=='private' || !positive(m.from?.id) || m.from.is_bot || m.from.id!==m.chat.id) return ok();
    if(typeof m.text!=='string') return ok();
    const user=m.from.id,chat=m.chat.id;
    const match=m.text.trim().match(/^\/([a-z]+)(?:@([a-z0-9_]+))?(?:\s+([\s\S]*))?$/i);
    const replied=m.reply_to_message;
    const isPromptReply=positive(replied?.message_id) && replied.from?.is_bot
      && replied.from?.username?.toLowerCase()===botUsername.toLowerCase();
    if(!match && !isPromptReply) return ok();
    const command=match?.[1].toLowerCase()||'',args=(match?.[3]||'').trim();
    if(match?.[2] && match[2].toLowerCase()!==botUsername.toLowerCase()) return ok();
    try {
      if(command==='vincular') {
        const linked=/^[a-f0-9]{32}$/.test(args) && await claim(await sha256(args),user,chat);
        await reply(chat,linked?'Chat vinculado. Ya puedes usar /pendientes y /ayuda. Los motivos serán visibles si tu dashboard es público.':'Código inválido, vencido o ya utilizado por otro usuario. Solicita uno nuevo a tu agente.');
        return ok();
      }
      const accounts=await lookup(user,chat);
      if(accounts.length!==1) {
        if(command==='start' || command==='ayuda') await reply(chat,'Bot conectado. Falta autorizar tu chat: pide a tu agente el código y envía /vincular CODIGO.');
        return ok();
      }
      const account=accounts[0].account_id;
      if(!match && isPromptReply) {
        const target=await promptReference(account,user,chat,replied.message_id);
        if(!target) {await reply(chat,'Ese mensaje no corresponde a una solicitud de motivo de tu cuenta. Usa /pendientes.');return ok();}
        const reason=m.text.trim();
        if(!reason || [...reason].length>1000) {await reply(chat,'Responde al aviso original con un motivo de 1 a 1000 caracteres.');return ok();}
        const result=target.phase==='protection'
          ? await protections({p_account:account,p_user:user,p_chat:chat,p_id:target.protection_id,p_reason:reason,p_update:update.update_id})
          : await record({p_account_id:account,p_reference:target.reference,p_phase:target.phase,p_reason:reason,p_user_id:user,p_chat_id:chat,p_update_id:update.update_id});
        if(result.error||result.stale){await reply(chat,'No se reemplazó el motivo vigente. Consulta el dashboard antes de reintentar.');return ok();}
        await reply(chat,result.duplicate?'Esta respuesta ya fue procesada.':`Razón de ${target.phase==='protection'?'cambio de SL/TP':target.phase==='closing'?'cierre':'apertura'} registrada. ${target.phase==='protection'?'Puedes consultarla en el dashboard.':`Puedes consultarla con /ver ${target.reference}.`}`);
        return ok();
      }
      if(command==='protecciones'){
        const rows=await protections({p_account:account,p_user:user,p_chat:chat});
        await reply(chat,rows.length?`Cambios de SL/TP pendientes (hasta 20):\n\n${rows.map(r=>`${r.symbol} · ${r.reference} · ${r.changes} cambio(s)\n/proteccion ${r.id} TU EXPLICACIÓN`).join('\n\n')}`:'No hay cambios de SL/TP pendientes.');
      }else if(command==='proteccion'){
        const parts=args.match(/^([a-f0-9-]{36})\s+([\s\S]+)$/),reason=parts?.[2].trim();
        if(!parts||!UUID.test(parts[1])||!reason||[...reason].length>1000){await reply(chat,'Usa /proteccion ID motivo (1 a 1000 caracteres). Consulta /protecciones.');return ok();}
        const r=await protections({p_account:account,p_user:user,p_chat:chat,p_id:parts[1],p_reason:reason,p_update:update.update_id});
        await reply(chat,r.error||r.stale?'Se conservó el motivo vigente. Revisa el dashboard.':'Motivo de cambio de SL/TP registrado; se conserva el historial de revisiones.');
      }else if(command==='dashboard') {
        const issued=await issueWebCode(account,user,chat,update.update_id);
        await reply(chat,issued.valid?`Código privado de acceso al dashboard (un solo uso, vence en 5 minutos):\n\n${issued.code}\n\nPégalo en «Entrar con Telegram» en tu dashboard. La sesión dura una hora. No compartas este código.`:'Este código ya venció o fue usado. Envía /dashboard de nuevo.');
      } else if(command==='start' || command==='ayuda') await reply(chat,HELP);
      else if(command==='pendientes') {
        const rows=await journals(account,user,chat,null);
        const lines=rows.map(r=>`${r.reference} · ${r.symbols}\nFalta: ${[r.has_opening&&!r.opening_reason?'apertura':null,r.has_closing&&!r.closing_reason?'cierre':null].filter(Boolean).join(' y ')}`);
        await reply(chat,lines.length?`Hasta 20 operaciones recientes con motivos humanos pendientes (también puede haber operaciones de EA):\n\n${lines.join('\n\n')}\n\n/apertura REFERENCIA motivo\n/cierre REFERENCIA motivo`:'No hay motivos humanos pendientes para las fases recibidas.');
      } else if(command==='ver') {
        if(!/^[a-f0-9]{8}$/.test(args)) {await reply(chat,'Usa /ver REFERENCIA (8 caracteres).');return ok();}
        const rows=await journals(account,user,chat,args),r=rows[0];
        await reply(chat,r?`${r.reference} · ${r.symbols}\nApertura: ${r.opening_reason || (r.has_opening?'Pendiente':'Sin ejecución de apertura recibida')}\nCierre: ${r.closing_reason || (r.has_closing?'Pendiente':'Sin ejecución de cierre recibida')}`:'Referencia no disponible.');
      } else if(command==='apertura' || command==='cierre') {
        const parts=args.match(/^([a-f0-9]{8})\s+([\s\S]+)$/),reason=parts?.[2].trim();
        if(!parts || !reason || [...reason].length>1000) {await reply(chat,`Usa /${command} REFERENCIA motivo (1 a 1000 caracteres).`);return ok();}
        const result=await record({p_account_id:account,p_reference:parts[1],p_phase:command==='apertura'?'opening':'closing',p_reason:reason,p_user_id:user,p_chat_id:chat,p_update_id:update.update_id});
        await reply(chat,result.duplicate?'Este mensaje ya fue procesado.':`Solicitud procesada. Consulta /ver ${parts[1]} para ver el motivo vigente.`);
      } else await reply(chat,HELP);
      return ok();
    } catch(e) {
      if(e?.name==='InputError') {try {await reply(chat,'No se pudo registrar o consultar: comprueba la referencia y que esa fase de la operación haya llegado desde MT5.');return ok();}catch{ /* retry delivery below */ }}
      // No message content, identifiers, tokens or upstream errors are logged.
      return new Response('temporarily_unavailable',{status:503});
    }
  };
}
