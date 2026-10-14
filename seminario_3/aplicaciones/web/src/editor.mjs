// Author: QRT Solutions. Session stays in memory; only human journal reasons are editable.
export function createEditor({getConfig,onChange,onSaved}){
 const $=id=>document.getElementById(id);
 let token=null,expires=0,selected=null,version=null,requestId=null,saving=false,loading=false,authenticating=false;
 const active=()=>Boolean(token)&&Date.now()<expires;
 function state(){if(!active())token=null;$('editorLogin').hidden=active();$('editorLogout').hidden=!active();$('editorStatus').textContent=active()?'Edición autorizada · Sesión de una hora':'Lectura pública';onChange();}
 async function api(action,data={}){
  const config=getConfig();if(!config)throw new Error('Todavía no se cargó la conexión. Pulsa Actualizar.');
  const response=await fetch(`${config.supabaseUrl}/functions/v1/mt5-dashboard-editor`,{method:'POST',headers:{'Content-Type':'application/json',apikey:config.publishableKey,...(token?{Authorization:`Bearer ${token}`}:{})},body:JSON.stringify({action,...data}),cache:'no-store',signal:AbortSignal.timeout(15000),redirect:'error'});
  const result=await response.json();
  if(!response.ok){
   if(response.status===401&&action!=='login'){token=null;state();}
   const messages={unauthorized:action==='login'?'Código inválido, vencido o utilizado. Envía /dashboard de nuevo.':'La sesión venció o fue revocada. Vuelve a entrar; tu borrador sigue aquí.',conflict:'El motivo cambió en otra ventana o en Telegram. Carga la versión actual y compara antes de guardar.',not_found:'Esta operación no está disponible para tu usuario.',group_pending:'Se están agrupando los cambios de este minuto. Espera y carga la versión actual.',phase_unavailable:'Todavía no se recibió una ejecución de esta fase.',invalid_input:'Revisa el motivo: entre 1 y 1000 caracteres.',origin_denied:'Este sitio no está habilitado para editar.'};
   const error=new Error(messages[result.error]||'No se pudo confirmar la operación. Puedes reintentar.');error.code=result.error;throw error;
  }
  return result;
 }
 async function login(){
  $('loginError').textContent='';$('loginCode').value='';$('botLink').hidden=true;
  if(!$('loginDialog').open)$('loginDialog').showModal();
  try{const c=await api('config');if(/^[a-zA-Z0-9_]{5,32}$/.test(c.bot_username)){$('botLink').href=`https://t.me/${c.bot_username}`;$('botLink').hidden=false;}}catch(e){$('loginError').textContent=e.message;}
 }
 $('editorLogin').addEventListener('click',login);$('editorReauth').addEventListener('click',login);
 $('loginCancel').addEventListener('click',()=>{if(!authenticating)$('loginDialog').close();});
 $('loginDialog').addEventListener('cancel',e=>{if(authenticating)e.preventDefault();});
 $('loginSubmit').addEventListener('click',async()=>{
  if(authenticating)return;authenticating=true;$('loginSubmit').disabled=true;$('loginError').textContent='';
  try{const r=await api('login',{code:$('loginCode').value.trim()});token=r.token;expires=Date.parse(r.expires_at);$('loginCode').value='';$('loginDialog').close();state();if(selected)$('editError').textContent='Sesión iniciada. Puedes continuar con tu borrador.';}
  catch(e){$('loginError').textContent=e.message;}finally{authenticating=false;$('loginSubmit').disabled=false;}
 });
 $('editorLogout').addEventListener('click',async()=>{
  $('editorLogout').disabled=true;
  try{await api('logout');token=null;state();}catch(e){$('editorStatus').textContent=e.message;}finally{$('editorLogout').disabled=false;}
 });
 function history(rows){
  const elements=rows.map(h=>{
   const li=document.createElement('li'),meta=document.createElement('p'),text=document.createElement('p');
   meta.className='muted';meta.textContent=`${new Date(h.recorded_at).toLocaleString('es-CL')} · ${h.phase==='protection'?'Cambio SL/TP':h.phase==='opening'?'Apertura':'Cierre'} · ${h.source==='web'?'Dashboard · cambio aplicado':h.phase==='protection'?'Telegram · cambio aplicado':'Telegram · solicitud recibida'}`;
   text.textContent=h.reason;text.className='reason-text';li.append(meta,text);
   if(h.source==='web'){const before=document.createElement('p');before.className='muted reason-text';before.textContent=`Anterior: ${h.previous_reason??'Sin motivo'}`;li.append(before);}return li;
  });
  if(!elements.length){const li=document.createElement('li');li.textContent='Sin cambios registrados.';elements.push(li);}
  $('reasonHistory').replaceChildren(...elements);
 }
 async function load(preserve=false){
  if(loading)return;loading=true;$('editSave').disabled=true;$('editReload').disabled=true;$('editError').textContent='Cargando motivo actual…';
  try{const r=await api(selected.phase==='protection'?'protection':'journal',{journal_id:selected.id});version=r.journal.updated_at;
   const current=r.journal[`${selected.phase}_reason`]||'';$('currentReason').textContent=current||'Sin motivo registrado';
   if(!preserve)$('editReason').value=current;
   history(r.history);requestId=null;$('editError').textContent=preserve?'Versión actual cargada. Tu borrador se conserva; revísalo antes de guardar.':'';$('editSave').disabled=false;
  }catch(e){version=null;$('editError').textContent=e.message;}finally{loading=false;$('editReload').disabled=false;}
 }
 async function edit(journal,phase){
  selected={id:journal.id,phase};version=null;requestId=null;$('editReason').value='';$('currentReason').textContent='';$('reasonHistory').replaceChildren();
  $('editTitle').textContent=`Motivo de ${phase==='protection'?'cambio de SL/TP':phase==='opening'?'apertura':'cierre'} · ${journal.id.slice(0,8)}`;
  $('editDialog').showModal();await load();
 }
 $('editReason').addEventListener('input',()=>{requestId=null;});
 $('editReload').addEventListener('click',()=>load(true));
 $('editCancel').addEventListener('click',()=>{if(!saving&&!loading){$('editDialog').close();selected=null;}});
 $('editDialog').addEventListener('cancel',e=>{if(saving||loading)e.preventDefault();else selected=null;});
 $('editSave').addEventListener('click',async()=>{
  if(saving||loading||!selected||!version)return;
  const reason=$('editReason').value.trim();if(!reason||[...reason].length>1000){$('editError').textContent='Escribe entre 1 y 1000 caracteres.';return;}
  saving=true;$('editSave').disabled=true;$('editReason').disabled=true;$('editReload').disabled=true;$('editError').textContent='Guardando…';
  requestId??=crypto.randomUUID();
  try{await api(selected.phase==='protection'?'save_protection':'save',{journal_id:selected.id,phase:selected.phase,reason,expected_updated_at:version,request_id:requestId});$('editDialog').close();selected=null;await onSaved();}
  catch(e){$('editError').textContent=e.message;if(e.code==='conflict')version=null;}
  finally{saving=false;$('editReason').disabled=false;$('editReload').disabled=false;$('editSave').disabled=!version;}
 });
 setInterval(()=>{if(token&&!active())state();},1000);
 return {active,edit};
}
