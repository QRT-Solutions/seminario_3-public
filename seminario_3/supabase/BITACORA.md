# Bitácora pública del proceso Supabase

Autoría: QRT Solutions.

Registro sanitizado del entorno docente; repetir las comprobaciones en cada clon.
Fechas en America/Santiago.

## 2026-10-07 — Preparación y creación

| Acción | Evidencia observada | Alcance |
|---|---|---|
| Revisión del EA v3.10 | Inputs, endpoints y campos leídos de la fuente suministrada | Fuente fuera del clon público |
| Instalación y compilación | MetaEditor MCP: 0 errores y 0 advertencias; fuente y binario verificados | Equipo docente; no se adjuntó a un gráfico |
| Creación del proyecto | Panel y consulta MCP: estado saludable en `sa-east-1` | Proyecto docente, no un destino para alumnos |
| Esquema | Migración `create_mt5_telemetry_storage`; tres tablas y cero filas | Sin envío desde MT5 |
| Acceso | RLS activo; `anon` y `authenticated` sin permisos en las tres tablas | Almacenamiento cerrado a clientes |
| Corrección administrativa | Migración `restrict_rls_event_trigger_execution`; revisión posterior sin advertencias | Permisos de función de RLS automático existente |
| Avisos restantes | Tres avisos informativos de RLS sin políticas | Esperados antes de configurar acceso |
| Alcance elegido | Una cuenta de MT5 | Multiusuario no implementado |

Evidencia detallada en `.local/supabase-setup/` y `.local/telemetry-install-*/` en
el equipo que ejecutó las acciones. No se distribuye ni se exige al alumno.

## 2026-10-07 — Recorrido reproducible para alumnos

Incorporados configuración paso a paso, mensaje inicial para agentes, contrato
del EA, tres archivos SQL de referencia y protocolo de documentación continua.
El `AGENTS.md` raíz enlaza ese protocolo; los punteros existentes de Claude Code
y Gemini/Antigravity remiten a las mismas reglas. La conexión en cada cliente
debe comprobarse: no se ha certificado el recorrido completo en los tres IDEs.

Verificaciones: enlaces locales sin fallos, construcción MkDocs en modo estricto
sin advertencias y Ruff aprobado para el hook de documentación modificado. El
esquema publicado coincide con el SQL aplicado en la demostración; se comprobó
que los archivos nuevos no incluyen identificadores personales ni credenciales
de la conexión local. No se modificaron servicios remotos durante esta tarea.

## 2026-10-07 — Receptor y envío desde MT5

El usuario autorizó implementar el receptor, emitir una credencial restringida,
adaptar y recompilar el EA, verificar recepción y mantener el cierre remoto apagado.

| Acción | Verificación | Resultado |
|---|---|---|
| Registro de credenciales y hora de recepción | Migración `add_scoped_telemetry_receiver` | Hash protegido, alcance de cuenta/servidor y vencimiento |
| Receptor `mt5-telemetry` | Despliegue activo; autenticación propia en el código | Solo POST y tres recursos de telemetría |
| Pruebas locales del receptor | 7 grupos de pruebas: identidad, revocación, expiración, formatos, límites, tickets y errores | Aprobadas |
| Generación de credenciales | 3 pruebas offline: archivos privados, rechazo de sobrescritura y destino no ignorado | Aprobadas |
| Rechazos remotos | Credencial inválida: HTTP 401; otra cuenta: HTTP 403; comandos: HTTP 400 | Sin escrituras de prueba |
| EA v3.20 | Compilador nativo: 0 errores, 0 advertencias; binario y hash verificados | Instalado como `MT5_Telemetry_Exporter_Supabase.ex5` |
| Inputs efectivos | Lectura independiente del gráfico EURUSD M15 | Credencial, URL y parámetros coinciden; cierre remoto false |
| WebRequest | Falló inicialmente con 4014; el usuario añadió el dominio permitido | Reintento automático, HTTP 200 |
| Recepción | Consulta independiente a Supabase, contrastada con diarios del EA | 1 snapshot, 3 deals históricos y 1 swap del símbolo del gráfico |
| Continuidad | Varias respuestas HTTP 200 y avance de `received_at` | Una sola fila de estado; no se duplica en cada lectura |
| Seguridad | RLS en cuatro tablas, sin acceso anon/authenticated; asesores sin advertencias | Solo avisos informativos de RLS sin políticas de cliente |

La fuente adaptada y el receptor están incluidos en el clon. Las credenciales,
archivos `.set` con secretos, identidad personal y logs completos permanecen en
`.local/telemetry-receiver/`, excluido de Git. La vigencia emitida fue de 90 días.
Se conservó el binario anterior; se actualizó una instancia identificada del
exportador, sin cambiar los otros gráficos ni operar en la cuenta.

## Punto de continuación actual

Completado: creación, tablas, receptor, credencial restringida, fuente distribuible,
compilación y recepción real desde MT5. Repetir el recorrido en el proyecto de cada
alumno; no se certifica por esta prueba la instalación en todos los IDEs o sistemas.

Límites: una cuenta, snapshots de último estado, hora histórica del broker aún sin
normalizar a UTC, y ausencia de cola durable de todos los eventos del EA. La integración de Telegram y sus límites se registran en las entradas posteriores. La aplicación web se validó por separado
en la entrada del 8 de octubre.

## Cómo continuar el registro

Revisión del siguiente componente (2026-10-07): inspeccionado el dashboard HTML
del docente. Se documentaron su carga JSON/CSV, datos sintéticos iniciales y campos
faltantes para métricas porcentuales y excursiones. La propuesta de alojamiento y
lectura autenticada está en la [guía de aplicación web](../aplicaciones/web/README.md).
Esta revisión no modificó el HTML original, permisos de base ni despliegues.

Agregar fecha local, cambio, motivo, archivos, comprobación, resultado y límites.
Separar pruebas locales, acciones remotas y envío desde MT5. Registrar fallos y
recuperación; un plan o una compilación no demuestra recepción de datos.

No incluir contraseñas, claves, cabeceras de autorización, referencias personales
de proyecto, números de cuenta, operaciones reales ni rutas personales. Usar
ejemplos sintéticos e identificarlos como tales.

[Volver a Supabase](README.md).

## 2026-10-08 — Dashboard público de la cuenta demo

El usuario autorizó mostrar su demo públicamente y sin inicio de sesión. Se
adaptó la base visual del HTML facilitado; se retiraron el dataset aleatorio y
los valores de relleno. La aplicación muestra snapshots, posiciones, deals,
neto registrado por símbolo, filtros y exportación. Los porcentajes y excursiones
sin respaldo quedan no disponibles. El HTML original no fue modificado.

- Migración `add_opt_in_public_demo_dashboard`: publicación optativa de una sola
  cuenta DEMO y función sin parámetros de cuenta, con campos explícitos. Las
  cinco tablas mantienen RLS; anon no puede leer ni escribir directamente.
- Consulta anónima con clave publishable: HTTP 200. Lecturas directas de snapshots,
  deals, credenciales y publicación: HTTP 401. No se enviaron escrituras de prueba.
- Asesores: avisos informativos de RLS sin políticas y advertencias por función
  SECURITY DEFINER pública. Estas últimas son deliberadas y se explican en la guía;
  no se declara ausencia de advertencias.
- Cuatro pruebas de cálculo/filtros/nulos/frescura aprobadas. El primer render
  local detectó un error de sintaxis del módulo; fue corregido y comprobado con
  `node --check` antes del despliegue.
- Vercel: proyecto nuevo, build de producción READY, despliegue por lista de
  archivos sin commits, push ni conexión Git. Dominio de producción accesible
  sin sesión; las URL generadas mantienen la protección de Vercel.
- Lectura real en navegador: snapshot y 11 deals al comprobar; filtros y sumas
  coinciden con los registros. El número puede crecer con actividad de la demo.
- Revisión visual: tarjetas, gráficos, bitácora, estados sin registros, métricas
  no disponibles y tasas de swap; vistas de 390 y 1440 píxeles.

La guía [Aplicación web](../aplicaciones/web/README.md) incluye configuración,
publicación, retirada de acceso, despliegue, pruebas y prompt para el agente del
alumno. La URL concreta del docente y evidencia completa están en `.local/dashboard/`,
excluida de Git. El cierre remoto continúa desactivado y esta tarea no operó en MT5.

## 2026-10-08 — Bot privado y alertas de apertura

El propietario creó su bot con BotFather, guardó `TELEGRAM_BOT_TOKEN` en Secrets
del proyecto correcto e inició el chat. Se documentaron dos errores de configuración
evitables: elegir otro proyecto de la misma organización y usar `TLG_BOT_TOKEN`
en lugar del nombre que lee el receptor.

- Función `mt5-telegram` desplegada; webhook y nombre del bot comprobados desde el
  servidor sin extraer el token. Instalador temporal retirado del despliegue final.
- Código aleatorio de vinculación de un uso: hash y vencimiento en base, canje
  realizado por el propietario. Consulta independiente confirmó un editor activo
  y un código consumido. El usuario confirmó que `/pendientes` muestra operaciones.
- Comandos de consulta y registro, autoría por usuario y deduplicación por
  `update_id`. Las funciones de Telegram son ejecutables solo por el servidor.
- Pruebas transaccionales de vinculación, consulta, escritura, repetición y rechazo
  de otro usuario aprobadas con ROLLBACK, sin motivos ficticios persistentes.
- El usuario pidió un aviso al abrir un trade nuevo y responder directamente con
  su razón. Se añadió cola durable de avisos de apertura, entrega en segundo plano
  desde la telemetría y asociación del mensaje original con la posición y el chat.
- Pruebas transaccionales de exclusión de histórico, reserva de mensajes, recibos
  y aislamiento de chats aprobadas con ROLLBACK. La cola comenzó vacía.
- 22 pruebas offline aprobadas entre receptor de telemetría, bot y entrega de avisos.
- MCP nativo confirmó `InpEventDrivenSync=true`, heartbeat de 30 segundos y cierre
  remoto false. La telemetría seguía actualizándose tras el despliegue.
- Asesores: avisos informativos RLS sin políticas y las dos advertencias ya
  conocidas de la consulta pública del dashboard; las RPC de Telegram permanecen
  cerradas a anon/authenticated.

Prueba real completada: el propietario abrió una nueva operación demo. La cola
registró un aviso y Telegram devolvió su identificador de mensaje **1,07 segundos
después de la creación del aviso en Supabase**. Esta medición no representa la
latencia total desde MT5 ni garantiza la notificación push del teléfono. La respuesta
del propietario quedó guardada como motivo de apertura de la misma posición;
la auditoría y el motivo vigente coinciden. No se abrió ninguna operación desde
el agente. Los detalles del trade y el texto real no se incluyen en esta guía pública.
Enlaces sin fallos, MkDocs estricto y Ruff de los scripts de instalación aprobados.
La guía reproducible está en
[Telegram](../integraciones/telegram/README.md); evidencia privada en `.local/telegram-setup/`.

## 2026-10-08 — Columnas de comentarios publicadas

El dashboard incorpora una fila por posición con columnas de apertura y cierre.
Muestra motivos humanos de Telegram y comentarios originales de MT5 por separado,
con fechas, precios y volumen en detalles. No inventa razones para fases ausentes
ni confunde una ejecución de cierre con una explicación humana.

Siete pruebas de la aplicación aprobadas, build correcto y despliegue Vercel de
producción READY. Verificación visual en la URL pública: el motivo real del trade
de prueba aparece en apertura; cierre figura pendiente. Paginación comprobada y
revisión móvil a 390 píxeles con desplazamiento horizontal de la tabla. Las reglas
de alcance y límites están en la guía web. Sin cambios de permisos ni operaciones
en MT5. Evidencia visual privada en `.local/dashboard/comentarios-publicados.jpg`.

## 2026-10-08 — Solicitud automática del motivo de cierre

El usuario detectó que el cierre no solicitaba una razón. La implementación
anterior solo encolaba aperturas. Se añadió la migración incremental
`extend_telegram_prompts_to_closing_phase`, publicada como referencia en
[telegram_alertas_cierre.sql](sql/telegram_alertas_cierre.sql), sin alterar datos
de telemetría ni funciones de trading.

La cola ahora distingue `opening` y `closing`; `OUT` y `OUT_BY` solicitan cierre,
e `INOUT` permite ambas fases. Las respuestas directas guardan el motivo de la
fase del mensaje original y la confirmación usa el nombre correcto. Se conserva
una solicitud por posición, usuario y fase; el primer cierre parcial puede activarla.
Los reenvíos históricos no generan avisos ni motivos inventados.

Verificación: 16 pruebas offline del bot y envío aprobadas; pruebas SQL con ROLLBACK
de cierres, cierres por opuesta, reversiones, deduplicación y exclusión de histórico
aprobadas. Se desplegaron ambos receptores antes de ampliar el esquema para que
interpretaran correctamente la nueva fase. Asesores sin nuevas categorías de
avisos: persisten RLS sin políticas y las advertencias conocidas de la RPC pública.

Se recuperó únicamente el aviso omitido de la operación demo identificada por el
propietario. Telegram devolvió recibo en el primer intento; la base confirmó
`phase=closing` y `sent_at`. Al verificar el envío, el motivo de cierre aún estaba
pendiente de la respuesta del propietario. No se abrió ni cerró ninguna posición.
Guía Telegram y contrato actualizados; enlaces locales y MkDocs estricto verificados.

## 2026-10-08 — Editor web de motivos con acceso por Telegram

Se implementó `/dashboard` para emitir códigos privados de un solo uso, cinco
minutos de vigencia y sesiones de una hora. La cuenta se deriva de la vinculación
activa. El dashboard incorpora acceso, edición de motivos de apertura/cierre,
historial, cierre de sesión y conservación del borrador ante cambios simultáneos.
Los datos financieros y comentarios nativos de MT5 permanecen sin cambios.

Aplicada la migración `dashboard_reason_editor`; publicados el receptor nuevo y
la actualización del bot. El despliegue de Vercel alcanzó READY. Pasaron 19 pruebas
del receptor/bot, siete del dashboard y las verificaciones SQL con ROLLBACK, sin
persistir textos de prueba. HTTP confirmó configuración disponible, rechazo 401
sin sesión y rechazo 403 desde otro origen. Asesores: mismas categorías conocidas,
RLS sin políticas por diseño privado y avisos de la RPC pública de lectura; ninguna
RPC nueva de edición expuesta a roles cliente.

La [guía para alumnos](../aplicaciones/web/EDICION.md) distingue código de acceso,
credencial del bot, vinculación, instalación por agente y pruebas. La verificación
final del propietario consiste en obtener el código en su chat e iniciar sesión
para editar un motivo real; no se inventan razones en operaciones públicas.

Verificación adicional de interfaz en servidor local aislado: acceso, aparición
de botones, edición, conflicto simultáneo, conservación de borrador, recarga de
versión, guardado literal y salida aprobados. El servidor de prueba no realizó
escrituras en Supabase. La pantalla de acceso publicada se verificó contra el
receptor real; evidencia en `.local/dashboard/editor-telegram.jpg`.

## 2026-10-08 — Consolidación para distribución docente

Se consolidó el recorrido completo MT5 → Supabase → Vercel/Telegram en la guía del
alumno, con prompt para agentes, orden SQL, plantilla privada, ejercicios y guion.
Se corrigieron índices que aún marcaban Telegram como pendiente, referencias que
confundían la fuente v3.30 con la compilación acreditada v3.20 y la lista de archivos
a desplegar de la web. La instalación nueva exige las columnas de comentarios
antes de activar el exportador actual. El mapa SQL separa esquema, configuración
de datos, correcciones condicionales y comprobaciones.

Se ampliaron exclusiones para configuración privada de agentes, JSON de instalación
y accesos directos locales, preservando los archivos del equipo. MkDocs incorpora
la navegación completa y excluye archivos privados; ya no anuncia el sitio anterior
como destino de esta documentación. El remoto Git heredado no se ha modificado.

Verificación local de esta consolidación: 30 pruebas de funciones, 7 web, 3 de
credenciales, 63 de la skill y catálogo de 17 estrategias sin errores. Los escaneos
de publicación, enlaces y construcción se registran en la entrega final. No se
hicieron escrituras en servicios remotos ni se operó MT5 para editar documentación.
El primer acceso real al editor y la validación nativa de la fuente v3.30 continúan
como pendientes explícitos; no se sustituyen por pruebas locales.

Resultado final de consolidación: MkDocs estricto y enlaces sin fallos; escáner
propio y Gitleaks sin hallazgos en árbol distribuible e historia (16 commits).
No se encontraron archivos privados en el sitio generado. El
[registro de verificación](../pruebas/VERIFICACION.md) conserva el alcance y los
pendientes de validación y publicación.

## 8 de octubre de 2026 — ajustes simples aprobados

Autoría: QRT Solutions.

Se implementó el alcance de [Ajustes simples](../guias/AJUSTES_SIMPLES.md):
comparación de SL/TP observados, eventos con anterior/nuevo, preguntas agrupadas
por posición y minuto, razones con revisiones, tarjetas móviles y paginación.
Se mantuvo la demo pública, la edición restringida y el cierre remoto desactivado.

Aplicación remota verificada: referencias `protecciones_bitacora.sql` y
`dashboard_paginado.sql`, más la corrección incremental para finalizar los grupos
antes de editarlos. Las referencias públicas ya incluyen esa corrección para
instalaciones nuevas. No volver a aplicar el archivo completo a una instalación
existente: contrastar las migraciones y preparar solo diferencias.

Funciones remotas: telemetría v6, Telegram v8, editor v3. Webhook actualizado para
`message` y `callback_query`; el instalador temporal se retiró del paquete final.
La publicación Vercel se realizó mediante CLI autenticada del mismo equipo y
proyecto, tras un 403 del conector MCP. Producción READY; assets contrastados por
SHA-256 con el build local y lectura pública HTTP 200.

Evidencia: 37 pruebas Node de funciones y 7 web aprobadas; SQL con fixtures y
ROLLBACK aprobado en PostgreSQL local y Supabase; cero cuentas de fixture
persistentes. Navegador a 390 y 1440 px sin errores ni desbordamiento de página,
paginación y edición de protecciones verificadas con respuestas interceptadas
(sin escritura real). Producción móvil lee datos reales. Edición anónima HTTP
401, origen ajeno 403 y tabla privada 401. Los 17 registros de RLS sin políticas
son deliberados para tablas cerradas. Los asesores también señalan las dos RPC
públicas SECURITY DEFINER para `anon`/`authenticated`: acceso deliberado a una
proyección fija de la única demo habilitada, sin acceso directo a tablas ni IDs
privados. Revisar [advertencia de funciones públicas](https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable)
si cambia ese modelo.

Fuente EA v3.40 preparada y copiada mediante MCP nativo a un archivo nuevo en
Experts, con hash y contrato local. **Compilación e instalación activa pendientes:**
el terminal MCP responde, pero el endpoint configurado de MetaEditor no escucha.
No se sustituyó el EA activo ni se abrieron/modificaron/cerraron operaciones.
No se acredita todavía un cambio real SL/TP → aviso → motivo desde esa versión.


## 8 de octubre de 2026 — compilación nativa v3.40 completada

Autoría: QRT Solutions.

Tras habilitar MetaEditor, se redescubrió su compilador nativo y se comprobó
que la fuente en Experts coincide por SHA-256 con la del repositorio.
Compilación x64 con MetaEditor build 6230: **0 errores y 0 advertencias**.
Lectura posterior del binario por MCP: firma EX5 y 40 542 bytes. La evidencia
completa, el contrato y los hashes permanecen en el registro local excluido de Git.

El binario nuevo está disponible en `MQL5/Experts`. Para verlo sin reiniciar:
Navegador → Asesores Expertos → clic derecho → Actualizar. Compilar no sustituye
el EA del gráfico: su activación y la recepción de cambios SL/TP de v3.40 siguen
pendientes. El cierre remoto permanece desactivado.


## 8 de octubre de 2026 — textos de configuración y autoría

Autoría: QRT Solutions.

Se retiraron los ejemplos del rótulo «Nombre del Proyecto» del exportador.
Los metadatos muestran `QRT Solutions` y enlazan a `https://www.qrtsolutions.com`.
El valor predeterminado del proyecto y la lógica de telemetría se conservan.
La revisión v3.40 con fuente SHA-256 `2ad776d3c18b093e8e06ab7890c67d61368677360393787d0ce7774716d2de57`
se compiló mediante MCP nativo: 0 errores y 0 advertencias; binario de 40 866
bytes verificado por lectura posterior. Se generó en un archivo nuevo de Experts;
la activación en el gráfico sigue pendiente.


## 8 de octubre de 2026 — recepción de v3.40 confirmada

Autoría: QRT Solutions.

Se comprobó mediante MCP que la revisión v3.40 de autoría actualizada está activa
en el gráfico, con latido de 30 segundos y cierre remoto desactivado. El nombre
de proyecto inicialmente no coincidía con el autorizado y causaba HTTP 403 en
snapshots e historial. Tras corregirlo el propietario, ambos envíos devolvieron
HTTP 200. La consulta directa a Supabase confirmó un snapshot recibido 29 segundos
antes de la verificación (13:57 UTC). No se generaron operaciones de prueba.

Para los alumnos: copiar exactamente `InpProjectName` de la configuración
emitida, incluidos guiones y mayúsculas. Una credencial válida no autoriza otro
nombre de proyecto. La recepción de snapshots e historial no certifica todavía
el recorrido de un cambio real SL/TP → aviso Telegram → motivo registrado.


## 8 de octubre de 2026 — motivos de ejemplo solicitados por el propietario

Autoría: QRT Solutions.

Carga expresamente autorizada para la demo pública: 99 motivos de apertura y
100 de cierre, agrupados en 20 grupos de apertura y 14 de cierre. Cada texto lleva
«Ejemplo didáctico»; los motivos de intención se señalan como ficticios. Los dos
cierres simultáneos por TP comparten una descripción basada en su ejecución.

Se conservaron los cinco motivos previos y los datos nativos de MT5. La escritura
transaccional verificó cuenta DEMO publicada, fases existentes, campos vacíos y
versiones sin cambios concurrentes; ensayo con ROLLBACK antes del COMMIT.
Se guardaron respaldo y plan privados, y 199 entradas de auditoría con actor
administrativo 0 en `mt5_web_reason_audit`. El historial web muestra origen `web`
por la tabla reutilizada; estas entradas proceden de SQL administrativo autorizado,
no de Telegram ni de una sesión del propietario suplantada.

Consulta posterior: 102 operaciones, cero motivos de apertura/cierre pendientes,
34 grupos con textos idénticos por grupo y cinco motivos originales intactos.
La consulta HTTP pública usada por el dashboard verificó las 11 páginas y los
199 ejemplos. No se alteraron comentarios del broker, precios, resultados ni
operaciones de MT5. Véase [uso de muestras](../aplicaciones/web/EDICION.md).


## 8 de octubre de 2026 — motivos breves por solicitud del propietario

Autoría: QRT Solutions.

Se abreviaron los 199 motivos de la muestra, retirando el prefijo visible y las
explicaciones largas. Las frases indican el efecto buscado, como «Capturar
continuación tras ruptura alcista», «Reducir exposición» o «Salida por take profit».
Se mantuvieron los grupos y los cinco motivos previos del propietario. La fuente
de los 199 textos sigue siendo una muestra sintética, no intención real acreditada.

Carga transaccional con comparación del texto y versión anteriores, restringida
a la demo publicada. Se guardaron 199 revisiones nuevas con actor administrativo
0 y `previous_reason` conservando el texto didáctico original. Verificación HTTP
pública de las 11 páginas: 199 cambios correctos, cinco textos conservados, cero
motivos pendientes en las 102 operaciones revisadas. No se alteró MT5.


## 8 de octubre de 2026 — resumen de configuración y presentación

Autoría: QRT Solutions.

Se incorporaron el [resumen paso a paso](../guias/RESUMEN_CONFIGURACION.md) de
Supabase, credencial MT5, inputs, Telegram, Vercel y editor web, y la
[ayuda memoria docente](../material/AYUDA_MEMORIA.md) con recorrido de 15 minutos,
comandos, preguntas frecuentes y alternativas sin operar durante la clase.
Se enlazaron en índices y navegación MkDocs. Las guías actuales ahora reflejan
compilación y recepción v3.40 ya verificadas, el despliegue Vercel posterior por
CLI y el carácter sintético de los motivos de muestra. Se corrigió la tabla
partida del orden SQL para presentar las diez referencias juntas.

Se contrastaron los pasos con scripts locales y documentación oficial de Secrets,
claves Supabase, BotFather, webhook y configuración de builds Vercel. No se
reconfiguraron servicios, no se emitieron credenciales y no se publicó el repositorio.
El remoto Git heredado sigue pendiente de definir para la entrega del seminario 3.


## 8 de octubre de 2026 — dos guías HTML portables

Autoría: QRT Solutions.

Se generaron [Configuración](../material/html/configuracion.html) y
[Ayuda memoria](../material/html/ayuda-memoria.html) desde las fuentes Markdown.
Incluyen navegación, referencias directas desplegables, copia de comandos, modo
presentación, tablas móviles e impresión del contenido principal. Los dos
archivos se comparten juntos; su lectura no hace peticiones de red. Se incluyó
el generador reproducible `tools/build_seminario3_handouts.py`.

Verificados en navegador a 390 y 1440 px: sin desbordamientos, enlaces internos
rotos, IDs duplicados ni errores JavaScript. Comprobados copia de comandos,
referencias desplegables, modo presentación e impresión; revisión visual de
escritorio y celular. MkDocs estricto y enlaces internos aprobados. No se
desplegaron sitios ni se cambiaron servicios.

## 8 de octubre de 2026 — diagnóstico de conexión Telegram, 16:48 Chile

Autoría: QRT Solutions.

Se verificaron función receptora activa, editor autorizado y envío reciente de
avisos. Una consulta autenticada y temporal a `getMe` y `getWebhookInfo` confirmó
el bot esperado, URL canónica, recepción de `message` y `callback_query`, cero
actualizaciones pendientes y ausencia de campos de último error. No se cambió
el webhook ni se enviaron mensajes de prueba; tampoco se escribieron motivos.

El diagnóstico conservó el handler normal, usó clave aleatoria con caducidad de
diez minutos y devolvió solo estado. Se restauraron los tres archivos originales
del receptor y se comprobó igualdad exacta por lectura remota. Respaldo y evidencia
quedaron en almacenamiento local ignorado por Git; no se expuso el token del bot.

Los dos motivos de la última operación seguían vacíos al comprobarlos. El código
desplegado ignora texto suelto sin comando ni respuesta directa. Se solicitó al
propietario consultar una referencia existente con `/ver` para verificar una
interacción nueva completa; esa prueba sigue pendiente. Los logs disponibles no
permiten atribuir por sí solos una pérdida de entrega. Procedimiento incorporado
en la [guía Telegram](../integraciones/telegram/README.md).

Verificación documental: enlaces locales sin fallos. La construcción MkDocs
estricta se detuvo por una advertencia ajena a estos cambios: el factsheet de
`STRAT-20261008-BREAKOUT3_LONG-M5-v1.0` enlaza un `compile.log` que MkDocs no
incluye entre sus archivos. No se modificó la estrategia para resolverlo.
# Integración de diez KPI — 8 de octubre de 2026

Autoría: QRT Solutions.

- Solicitud: implementar los diez indicadores aprobados en el dashboard del
  seminario. Se confirmó el proyecto existente y la publicación ya habilitada de
  una demo; no se cambiaron cuenta, permisos de publicación, EA ni trading.
- Añadida `dashboard_kpis.sql`, aplicada remotamente como
  `add_public_demo_ten_kpis`. RPC agregada sobre todo el filtro de cierre, símbolo
  y dirección original, con conteos de operaciones completas y exclusiones.
  Admite parciales ponderados; excluye reversiones y secuencias no reconstruibles.
- Integradas diez tarjetas con fórmulas, selector de dirección y distinción entre
  muestra vacía, ratios indefinidos y cero real. Se mantienen el historial paginado,
  gráficos, exportación y editor de motivos. No se importaron fixtures del laboratorio.
- Verificado en PostgreSQL local con fixtures y ROLLBACK: BUY, SELL, parciales,
  comisiones de apertura, apertura anterior al filtro, neutros, muestra vacía,
  pérdidas únicamente, ausencia de pérdidas, exclusiones y bloqueo de cuentas
  reales/publicación deshabilitada. Diez pruebas Node aprobadas y build correcto.
- La lectura real produjo 108 operaciones completas, cero exclusiones, 71 compras
  y 37 ventas. El navegador mostró cifras concordantes con la RPC. Se verificaron
  filtros, restablecer, paginación sin cambio de KPI y apertura del diálogo de acceso.
  No se realizaron escrituras de motivos para probar el cambio.
- Producción Vercel READY y dominio estable comprobado sin sesión a 320, 390, 768 y
  1440 px: diez tarjetas, sin desbordamiento horizontal ni errores JavaScript.
- Las 17 tablas MT5 conservan RLS y ningún permiso directo de lectura/escritura para
  `anon`. Los asesores mantienen avisos esperados de
  [funciones públicas SECURITY DEFINER](https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable),
  [ejecución authenticated](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable)
  y [RLS sin políticas](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy).
  Las funciones exponen solo proyecciones de la demo autorizada; no se declara
  que el asesor esté libre de avisos.
- Límites: drawdown sin equity histórica ajustada; riesgo hasta SL solo puede ser
  cero cuando no hay posiciones y el snapshot es completo. Con posiciones falta
  valoración monetaria, y un SL ausente se informa como riesgo no acotado.
  Retornos/acierto son antes de costes; neto y PF monetario usan costes recibidos,
  sin cargos separados ausentes del contrato. Hora del broker aún sin normalizar.
- Guías, contrato, orden SQL, estado y diseño actualizados. Enlaces locales: cero
  fallos; se preservan las referencias históricas heredadas ya documentadas.
- La construcción documental estricta detecta un aviso ajeno a estos cambios:
  el factsheet BREAKOUT3 enlaza `compile.log`, excluido de los archivos publicados.
  La validación del dashboard y del SQL es independiente de ese aviso.

## 2026-10-08 — Republicación solicitada en Vercel

Autoría: QRT Solutions. Se reconstruyó la aplicación y se republicó sin caché en
el mismo proyecto de producción, con resultado READY. Diez pruebas Node y build
aprobados; dominio estable verificado a 320/390/768/1440 px, diez tarjetas, filtros
y paginación correctos, sin errores JavaScript. El MCP de Vercel rechazó el alcance
del equipo (403); la CLI autenticada permitió completar la misma acción en el
destino explícito. No se modificó la base de datos ni la configuración de MT5.

## 2026-10-08 — Distribuciones y curvas del filtro completo

Autoría: QRT Solutions.

- Añadidos cuatro gráficos: histogramas de retorno del precio y neto monetario,
  curva de retorno puro acumulado (total/compras/ventas) y curva de neto acumulado.
  Se usan operaciones completas de todo el filtro y el mismo conjunto de los KPI.
- Inspeccionada la función existente y su historial antes de aplicar
  `add_public_demo_result_distributions`, correspondiente a
  [dashboard_distribuciones.sql](sql/dashboard_distribuciones.sql). La RPC conserva
  sus campos y permisos y añade `charts`; no publica identificadores adicionales.
- Histogramas de doce intervalos iguales, con mínimo/máximo incluidos, celdas
  vacías a cero y un único intervalo para muestras constantes. Curvas con base
  cero, orden de cierre y hasta 400 puntos; agrupación explícita para más cierres.
  Tablas consultables por teclado, unidades visibles y horas del broker.
- PostgreSQL local: fixtures con ROLLBACK para muestras vacías, constantes,
  neutros, BUY/SELL, parciales, extremos de intervalos y 805 cierres; totales y
  límites verificados. Trece pruebas Node y build aprobados.
- Conciliación real: 108 operaciones; suma de frecuencias 108; último punto de las
  curvas coincide con retorno y neto de los KPI. La prueba del navegador contrasta
  la respuesta RPC con las cuatro series, filtros y cambio de página.
- Corregido el botón Actualizar: ahora llama `refresh()` sin pasar el objeto del
  evento como `p_history`. Error HTTP simulado solo en el navegador de pruebas:
  oculta gráficos antiguos y permite recuperar la lectura al reintentar.
- Producción Vercel READY, con comprobación sin sesión a 1440/390/320 px: cuatro
  gráficos, sin desbordamientos ni errores JavaScript; filtros y recuperación
  verificados. SQL, contrato, orden de instalación, guías y estado actualizados.
- Se conservan 17 tablas con RLS y sin acceso directo de `anon`. Asesores con los
  mismos avisos documentados de funciones públicas y RLS sin políticas. Sin cambios
  en la publicación habilitada, el EA, la cuenta o las operaciones de MT5.
- Enlaces: cero fallos. Documentación construida con el aviso previo del enlace
  `compile.log` en el factsheet BREAKOUT3. No se presenta ninguna curva como equity
  histórica; la agregación puede ocultar movimientos dentro de un grupo.

## 2026-10-13 — Preparación documental para distribución pública

Autoría: QRT Solutions.

- Consolidación y clarificación pedagógica del repositorio para la distribución
  pública a los alumnos.
- Incorporada la nueva guía [EMPIEZA_AQUI.md](../guias/EMPIEZA_AQUI.md) como punto de
  entrada accesible para alumnos sin conocimientos de programación, con un primer
  ejercicio reproducible basado en el laboratorio local de diez KPIs
  (`preview.html`), diferenciando estrictamente su muestra simulada (48 operaciones
  analizables, una excluida y 40 sesiones) frente a datos reales de cuenta.
- Clarificada la separación de dos rutas de aprendizaje: la Ruta Introductoria sin
  credenciales (inspección de KPIs, sin MT5 ni nube) y la Ruta Técnica completa
  (MT5, Supabase, Telegram y Vercel).
- Sincronizada la documentación de la versión del exportador EA a **v3.40**
  ([MT5_Telemetry_Exporter_Universal.mq5](../../MT5/MT5_Telemetry_Exporter_Universal.mq5))
  en el README raíz y guías de configuración. Se hace constar explícitamente que las
  pruebas previas registradas corresponden al entorno docente histórico y no certifican
  automáticamente despliegues en instalaciones nuevas de alumnos.
- Actualizada [docs/architecture.md](../../docs/architecture.md) para reflejar las
  tecnologías operativas reales (aplicación web en Vanilla HTML/CSS/JS + Chart.js,
  prototipo de laboratorio en React, 12 referencias SQL ordenadas y suites de tests Node).
- Reforzado [ENTREGA.md](../ENTREGA.md) con el checklist de contenido seleccionable,
  aislamiento estricto de archivos privados y advertencia sobre derechos de terceros
  en `base_de_conocimientos/` (50 libros con copyright de terceros donde no aplica MIT)
  y manuales importados en `MT5/knowledge/`.
- Resuelta la referencia diagnóstica del factsheet BREAKOUT3 vinculando a
  `compile-evidence.json` para evitar enlaces rotos en la documentación pública.
- Registrado el baseline de diffs y hashes en `.local/preparacion-publica-20261013/`.
  Sin commits, push, reset ni alteraciones de servicios remotos.

