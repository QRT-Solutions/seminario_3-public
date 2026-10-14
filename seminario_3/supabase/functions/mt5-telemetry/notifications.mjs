// Author: QRT Solutions. Durable queue; retries may duplicate a delivered prompt after an uncertain timeout.
export async function deliverOpeningNotifications(account,{claim,send,finish}) {
  const rows=await claim(account);
  for(const row of rows) {
    try {
      const closing=row.phase==='closing';
      if(row.phase==='protection'){
        const level=v=>Number(v)===0?'Sin nivel':String(v);
        const text=`Cambio de SL/TP · ${row.symbol} · ${row.reference}\nSL: ${level(row.old_sl)} → ${level(row.new_sl)}\nTP: ${level(row.old_tp)} → ${level(row.new_tp)}\n${row.changes} cambio(s) observado(s), agrupados durante un minuto.\n\n¿Por qué cambiaste la protección? Elige una razón o responde a este mensaje. Se publicará si tu dashboard es público. Telegram no modifica MT5.`;
        const button=(text,kind)=>({text,callback_data:`p:${row.protection_id}:${kind}`});
        const message=await send({chat_id:row.chat_id,text,reply_markup:{inline_keyboard:[[button('Reducir riesgo','risk'),button('Cambio de estructura','structure')],[button('Noticia','news'),button('Otro','other'),button('Después','later')]]},link_preview_options:{is_disabled:true}});
        if(!Number.isSafeInteger(message?.message_id)||message.message_id<=0)throw new Error('invalid_telegram_receipt');
        await finish(row.id,row.lease_token,message.message_id);continue;
      }
      if(row.phase && !['opening','closing'].includes(row.phase))throw new Error('invalid_phase');
      const title=closing?'Cierre registrado':'Nueva apertura';
      const execution=closing?`Salida ejecutada mediante ${row.direction==='BUY'?'compra':'venta'}`:row.direction==='BUY'?'Compra':'Venta';
      const question=closing?'¿Cuál fue tu razón para cerrar esta operación o reducir su volumen?':'¿Cuál fue tu razón para abrir esta operación?';
      const text=`${title} · ${row.symbol}\n${execution} · ${row.volume} lotes · Precio ${row.price}\nReferencia: ${row.reference}\n\n${question}\nResponde a este mensaje con tu explicación. Se guardará en la bitácora y será pública si tu dashboard está publicado.`;
      const message=await send({chat_id:row.chat_id,text,reply_markup:{force_reply:true,selective:true,input_field_placeholder:`Escribe tu razón de ${closing?'cierre':'apertura'}`},link_preview_options:{is_disabled:true}});
      if(!Number.isSafeInteger(message?.message_id) || message.message_id<=0) throw new Error('invalid_telegram_receipt');
      await finish(row.id,row.lease_token,message.message_id);
    } catch {
      await finish(row.id,row.lease_token,null);
    }
  }
}
