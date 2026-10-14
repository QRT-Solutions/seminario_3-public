// Author: QRT Solutions. TEMPORARY entrypoint: deploy index.ts immediately after setup.
import {handle,telegram,secret,webhookURL} from './runtime.ts';
import {sha256,equalSecret} from './core.mjs';
// Generated locally, excluded from Git, contains a digest and expiry, not a token.
import config from './setup.private.json' with {type:'json'};
Deno.serve(async req=>{
  if(new URL(req.url).pathname.endsWith('/setup')) {
    if(req.method!=='POST') return new Response('method_not_allowed',{status:405});
    const supplied=req.headers.get('x-setup-key')||'';
    if(Date.now()>config.expiresAt || !equalSecret(await sha256(supplied),config.keyHash)) return new Response('unauthorized',{status:401});
    try {
      const me=await telegram('getMe');
      if(me.username!==config.botUsername) return new Response('wrong_bot',{status:409});
      const before=await telegram('getWebhookInfo');
      if(before.url && before.url!==webhookURL) return new Response('existing_other_webhook',{status:409});
      await telegram('setWebhook',{url:webhookURL,secret_token:secret,allowed_updates:['message','callback_query'],drop_pending_updates:false,max_connections:1});
      await telegram('setMyCommands',{commands:[{command:'protecciones',description:'Cambios de SL/TP con motivo pendiente'},{command:'proteccion',description:'Registrar o corregir motivo de cambio SL/TP'},{command:'dashboard',description:'Código privado para editar en la web'},{command:'ayuda',description:'Cómo usar la bitácora'},{command:'pendientes',description:'Ver motivos humanos pendientes'},{command:'ver',description:'Consultar los motivos de una operación'},{command:'apertura',description:'Documentar la razón de entrada'},{command:'cierre',description:'Documentar la razón de salida (no opera)'},{command:'vincular',description:'Autorizar este chat con un código privado'}]});
      const after=await telegram('getWebhookInfo');
      return Response.json({bot:me.username,url:after.url,pendingUpdates:after.pending_update_count});
    }catch {return new Response('setup_failed',{status:503});}
  }
  return handle(req);
});
