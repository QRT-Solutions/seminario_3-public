# Integración con Telegram

Autoría: QRT Solutions.

## Qué construimos

Telegram es el canal para escribir; una Edge Function de Supabase valida el mensaje
y registra el motivo en la bitácora. El dashboard en Vercel consulta esos datos.
El bot no modifica comentarios del broker ni ejecuta compras, ventas o cierres.
`/cierre` significa **documentar una salida que ya fue recibida desde MT5**.

Diseño aprobado: chat privado autorizado, una cuenta vinculada por chat, un bot por
proyecto y motivos de apertura/cierre por identificador de posición. Los cierres
parciales comparten el motivo de cierre de esa posición; no son notas individuales
por deal. Las horas históricas siguen en hora del broker, no UTC normalizado.

Estado al 8 de octubre de 2026: código y SQL incluidos, receptor desplegado en el
entorno docente, webhook confirmado por Telegram y chat del propietario vinculado.
Avisos automáticos de apertura y respuesta directa verificados con una operación
demo nueva del propietario; medición y alcance en la [bitácora](../../supabase/BITACORA.md).
La aplicación web incorpora columnas de apertura y cierre, con comentarios de MT5
y motivos humanos separados. Desplegar este receptor no despliega la aplicación
web ni recompila el EA: seguir también la [guía web](../../aplicaciones/web/README.md).

## 1. Crear tu bot

1. Abre el [BotFather oficial](https://t.me/BotFather), con insignia de verificación.
2. Pulsa **Iniciar** y envía `/newbot`.
3. Introduce un nombre visible, por ejemplo `Bitácora de Trading`.
4. Elige un usuario disponible que termine en `bot`, sin espacios, por ejemplo
   `bitacora_tu_alias_bot`. Un nombre ocupado requiere elegir otro.
5. Guarda el token en un gestor de contraseñas. No lo pegues en el chat del agente,
   capturas, repositorio, EA ni dashboard.
6. Abre el enlace de tu bot y pulsa **Iniciar** o envía `/start`. Antes de conectar
   el receptor puede no responder; eso no indica que la creación falló.

Si ya tienes un bot para este proyecto, reutilízalo. Antes de cambiar un webhook,
comprobar si otro proceso lo utiliza. No ejecutar a la vez `getUpdates` y un webhook.
Documentación: [BotFather](https://core.telegram.org/bots/features#botfather).

## 2. Guardar la credencial en el proyecto correcto

En Supabase abre **tu proyecto → Edge Functions → Secrets**. Compara nombre y
referencia del proyecto con la instalación MT5; no basta con estar en la organización.

| Campo | Valor |
|---|---|
| Name | `TELEGRAM_BOT_TOKEN` |
| Value | Token completo entregado por BotFather |

Pulsa **Save** y comprueba que aparezca en **Custom secrets**. `TLG_BOT_TOKEN` es
otro nombre: este receptor solo lee `TELEGRAM_BOT_TOKEN`. La función usa los secretos
administrativos incorporados por Supabase exclusivamente en el servidor.

La credencial del webhook se deriva dentro del servidor mediante HMAC-SHA256,
usando el token del bot como clave y el contexto fijo
`QRT Solutions:mt5-telegram:webhook:v1`. No es el token del bot ni se expone en la
URL. Telegram la entrega en `X-Telegram-Bot-Api-Secret-Token`; la función la exige
antes de leer el mensaje. Rotar el token requiere volver a configurar el webhook.
Consulta [Supabase Secrets](https://supabase.com/docs/guides/functions/secrets) y
[setWebhook](https://core.telegram.org/bots/api#setwebhook).

## 3. Preparar la base y probar el código

El agente debe leer el [protocolo Supabase](../../supabase/AGENTS.md) y comprobar
esquema, migraciones y cuenta existentes. Aplicar solo las diferencias necesarias:

1. [bitacora_trades.sql](../../supabase/sql/bitacora_trades.sql): comentarios
   originales, motivos separados, editores autorizados, auditoría y consulta pública.
2. [telegram_bitacora.sql](../../supabase/sql/telegram_bitacora.sql): códigos de
   vinculación y consulta restringida de motivos pendientes. Ambas son referencias
   SQL para aplicar una vez; no son scripts idempotentes.
3. Ejecutar desde la raíz:

```sh
node --test seminario_3/supabase/functions/mt5-telegram/core.test.mjs
```

La función pública del dashboard solo publica la demo expresamente habilitada.
Un dashboard público también hará públicos los motivos humanos cuando los muestre;
el chat privado no convierte esas notas en información privada.

## 4. Instalar el receptor y registrar el webhook

La función [mt5-telegram](../../supabase/functions/mt5-telegram/index.ts) no requiere
librerías externas. El agente descubre la herramienta de despliegue disponible.
Si usa CLI, consultar primero la versión y ayuda vigentes, sin suponer comandos.
El destino es el proyecto del alumno; nombre de función `mt5-telegram` y
`verify_jwt=false` porque Telegram usa la credencial de webhook validada por el código.
Nunca desactivar JWT en una función que no valide otra credencial.

Para instalar sin sacar el token de Supabase, se incluye un instalador temporal:

```sh
python3 seminario_3/integraciones/telegram/preparar_instalacion.py \
  --bot-username TU_USUARIO_BOT \
  --output .local/telegram-setup/instalacion-1
```

El directorio debe ser nuevo y estar ignorado por Git. Se generan una clave aleatoria
privada y su hash, con vigencia de 15 minutos. No contienen el token de Telegram.

| Despliegue | Entrada | Archivos que se envían |
|---|---|---|
| Temporal | `setup.ts` | `setup.ts`, `runtime.ts`, `core.mjs`, `deno.jsonc` y el archivo generado `setup.private.json` |
| Definitivo | `index.ts` | Solo `index.ts`, `runtime.ts`, `core.mjs`, `deno.jsonc` |

Los archivos fuente están en `seminario_3/supabase/functions/mt5-telegram/`.
En el despliegue temporal se envía el contenido del JSON privado bajo el nombre
`setup.private.json`, sin copiarlo a una carpeta pública del repositorio.

Después del despliegue temporal:

```sh
python3 seminario_3/integraciones/telegram/configurar_webhook.py \
  --project-ref TU_PROJECT_REF \
  --installation .local/telegram-setup/instalacion-1
```

El instalador verifica el nombre del bot con `getMe`, rechaza reemplazar un webhook
de otra URL, registra la URL canónica `https://TU_PROJECT_REF.supabase.co/functions/v1/mt5-telegram`,
conserva mensajes pendientes y configura el menú. El resultado se guarda localmente.
No imprime ni devuelve el token, las claves administrativas o el secreto del webhook.

**Desplegar inmediatamente la versión definitiva**, incluso si la instalación
falla. Eliminar del paquete remoto `setup.ts` y `setup.private.json`; no basta con
ocultar el enlace. El receptor definitivo carece de ruta administrativa. Si falla,
corregir el motivo y generar otra instalación temporal con otra clave y vencimiento.
La ruta temporal también caduca por sí sola.

## 5. Vincular al propietario

El agente obtiene `account_id` de los registros del proyecto y confirma que
corresponde a la cuenta elegida. No reutiliza la cuenta ni el chat del docente.

```sh
python3 seminario_3/integraciones/telegram/crear_vinculo.py \
  --account-id TU_ACCOUNT_ID \
  --output .local/telegram-setup/vinculo-1
```

Revisar y ejecutar el `register.sql` generado en el proyecto propio. Debe devolver
exactamente una fecha de vencimiento; cero filas significa cuenta no encontrada.
La base guarda solo SHA-256 del código. El agente entrega el código del archivo
privado únicamente al propietario por el canal de la tarea:

```text
/vincular CODIGO_PRIVADO
```

El propietario lo envía a su bot en chat privado. Caduca una hora después de
registrarlo y queda consumido por el primer usuario que lo canjea. No compartirlo:
es una autorización. La base comprueba que chat y usuario coincidan y asocia esa
identidad a la cuenta del código. `/start` por sí solo **no autoriza** a nadie.
Se rechazan grupos y mensajes reenviados como sustituto de identidad: el emisor
del mensaje actual debe ser el usuario del chat privado.

## 6. Uso y prueba real

### Avisos automáticos de apertura y cierre

El flujo recomendado ya no requiere copiar referencias: cuando llega un **nuevo
deal de apertura por evento**, el bot envía «Nueva apertura», símbolo, dirección,
volumen y precio, y solicita la razón. El usuario pulsa **Responder** sobre ese
mensaje y escribe su motivo verdadero. Telegram suele abrir automáticamente el
campo de respuesta gracias a `ForceReply`.

Cuando llega una salida, el bot envía **«Cierre registrado»** y pide la razón
para cerrar o reducir volumen. Responder directamente a ese aviso guarda el motivo
de cierre; responder al de apertura guarda el motivo de entrada. La confirmación
indica la fase correspondiente y nunca sobrescribe el motivo de la otra fase.

El servidor resuelve el mensaje original por su identificador almacenado y por
el chat autorizado, no por texto citado que pueda falsificarse. Confirma el
guardado y permite consultarlo con `/ver REFERENCIA`. Las correcciones también
pueden enviarse como otra respuesta al mismo aviso. No se interpretan mensajes
sueltos como motivos de la última operación: así no se asignan a un trade equivocado.

Para activar este flujo en el proyecto del alumno:

1. Aplicar [telegram_alertas_apertura.sql](../../supabase/sql/telegram_alertas_apertura.sql)
   después de las migraciones de bitácora y vinculación y luego
   [telegram_alertas_cierre.sql](../../supabase/sql/telegram_alertas_cierre.sql).
   No generan alertas antiguas. En una instalación activa, desplegar primero las
   funciones que distinguen la fase y después aplicar la extensión de cierre.
2. Desplegar también `mt5-telemetry` con `index.ts`, `core.mjs`, `notifications.mjs`
   y `deno.jsonc`; desplegar `mt5-telegram` con sus cuatro archivos definitivos.
3. Verificar en el EA activo `InpEventDrivenSync=true`, `InpExportDeals=true`
   y `InpEnableKillSwitch=false`. El EA v3.20 dispone del envío por evento requerido.
4. Vincular primero el chat y esperar la confirmación del agente de que está activo.
5. Si el propietario decide abrir una operación demo, comprobar recepción del deal,
   envío del mensaje y guardado de su respuesta. El agente no abre trades de prueba.

La alerta se prepara por cada posición, usuario y fase al insertar un deal BUY/SELL
con `approval_status=PENDING`, la marca usada por el exportador en `OnTradeTransaction`.
`IN` pide apertura; `OUT` y `OUT_BY` piden cierre; `INOUT` permite ambas fases.
No significa aprobación humana. Los lotes históricos `APPROVED` y deals ya existentes
no generan avisos. Una posición tiene como máximo una solicitud por fase y usuario:
los aumentos de volumen y cierres parciales posteriores no generan otra solicitud.
El primer cierre parcial ya puede pedir motivo; el mensaje no afirma que toda la
posición haya quedado cerrada. Esta versión conserva un motivo de salida por posición.

La extensión mantiene los nombres RPC originales que contienen `opening` para
permitir el despliegue sin interrumpir la telemetría; ahora la cola devuelve `phase`
y selecciona el motivo pendiente de esa fase. No basta con cambiar solo el texto
del mensaje: también deben ampliarse el CHECK, el trigger y la consulta de la cola.
Un aviso omitido antes de activar esta extensión puede recuperarse administrativamente
para una operación identificada y verificada, sin reencolar todo el historial.

La cola `mt5_telegram_notifications` se inserta dentro de la transacción del deal.
El receptor inicia la entrega en segundo plano con `EdgeRuntime.waitUntil`, sin
hacer esperar al EA por Telegram. Una reserva temporal evita envíos simultáneos;
el identificador de mensaje devuelto por Telegram queda asociado a la posición.
Si falla, las siguientes recepciones de telemetría reintentan la cola, con espera
mínima de 30 segundos. Si MT5 deja de enviar, esos reintentos también esperan.
No hay un cron independiente ni una garantía de latencia o entrega exactamente
una vez: un timeout después de enviar y antes de guardar el recibo puede duplicar
el aviso. La respuesta escrita se deduplica mediante `update_id`.

En condiciones normales se espera el aviso en segundos; la medición de una prueba
real debe documentarse. Si MT5 pierde el evento de apertura o cierre antes de enviarlo, esta
cola no puede recuperar ese evento. No activar trading ni DLL para intentar resolverlo.

### Comandos alternativos

| Comando | Resultado |
|---|---|
| `/ayuda` | Explica la bitácora y sus límites |
| `/pendientes` | Hasta 20 operaciones recientes con motivos humanos pendientes para fases recibidas |
| `/ver REFERENCIA` | Consulta motivos actuales |
| `/apertura REFERENCIA motivo` | Guarda o corrige la razón de entrada |
| `/cierre REFERENCIA motivo` | Guarda o corrige la razón de salida ya recibida; no opera en MT5 |

La referencia son los primeros ocho caracteres del UUID de la bitácora. La base
rechaza referencias ambiguas. Los motivos admiten de 1 a 1000 caracteres; no se
interpretan como HTML, SQL ni instrucciones. Esta versión recibe texto, no voz.
Las ediciones posteriores del mensaje en Telegram se ignoran: para corregir un
motivo, enviar otro comando completo. Los comentarios nativos se conservan aparte.

`/pendientes` también puede incluir operaciones de EA: no se inventa una explicación
humana a partir del Magic Number ni se copia automáticamente un comentario ambiguo.
No muestra motivos pendientes de una fase que aún no haya llegado a Supabase.

Después de vincular:

1. Enviar `/pendientes` y elegir una referencia real.
2. Registrar un motivo verdadero para una fase existente; no inventar razones para
   probar ni abrir/cerrar operaciones de prueba.
3. Consultar `/ver REFERENCIA` y verificar el motivo en base y en el dashboard.
4. Ejecutar [verificar_telegram.sql](../../supabase/sql/verificar_telegram.sql).
   Debe haber RLS y ningún permiso anon/authenticated sobre las RPC de Telegram.
5. Una petición HTTP sin secreto al receptor debe devolver 401 sin escribir datos.

Cada cambio conserva una auditoría con `update_id`. Reintentos del mismo mensaje
no duplican cambios y un mensaje atrasado no sobrescribe otro más reciente.
La escritura y su auditoría son atómicas; la respuesta de Telegram no forma parte
de esa transacción. Si Telegram falla después de guardar, reintenta y puede repetir
la confirmación. No se promete entrega de respuestas exactamente una vez.

## 7. Revocación y resolución de problemas

### Comprobar la conexión sin modificar motivos

Consultar `getMe` y `getWebhookInfo` desde un entorno autorizado que conserve el
token en privado. Comparar el bot y la URL con la instalación propia; comprobar
`allowed_updates` (debe incluir `message` y `callback_query`),
`pending_update_count` y los campos de último error. No ejecutar `setWebhook`
ni descartar mensajes para una comprobación de solo lectura. Véase
[getWebhookInfo](https://core.telegram.org/bots/api#getwebhookinfo).

Una cola vacía y una función activa no demuestran que un motivo se haya guardado.
El propietario puede enviar `/ver REFERENCIA` de una operación existente y
comprobar la respuesta, después contrastar los motivos y su auditoría en Supabase.
La versión actual ignora silenciosamente el texto que no sea comando ni respuesta
directa al aviso del bot: escribir debajo del aviso no establece esa asociación.
La ausencia en una consulta de logs tampoco demuestra por sí sola que Telegram
no haya entregado el mensaje.

Si para inspeccionar el webhook se usa un diagnóstico temporal en la función,
respaldar primero los archivos desplegados; protegerlo con credencial aleatoria,
caducidad breve y métodos de lectura fijos, sin devolver secretos. Conservar el
handler normal y restaurar después exactamente los archivos originales,
verificándolos por lectura remota. No dejar una ruta administrativa instalada.

| Síntoma | Comprobación |
|---|---|
| No responde antes del despliegue | Crear el bot no instala su programa |
| HTTP 503 | Nombre exacto del secreto, credencial válida y disponibilidad de Telegram/base |
| Instalador 401 | Clave temporal incorrecta o vencida; generar una nueva instalación |
| Instalador 409 | Bot distinto o webhook existente de otra integración; revisar antes de reemplazar |
| Código inválido | Caducó, se copió mal o lo consumió otro usuario |
| Motivo rechazado | Referencia ambigua/inexistente, fase no recibida, texto vacío/largo o chat revocado |
| Guardado pero no visible en web | Revisar por separado la consulta pública, publicación de la demo y versión del dashboard |

Para revocar un editor, el administrador pone `active=false` en su fila exacta
de `mt5_telegram_editors`; no borra el historial. Para reautorizarlo, emite otro código.
Un código ya consumido no reactiva una autorización revocada. Cambiar de bot exige
revisar el espacio de `update_id`: esta versión admite **un bot por proyecto**.

RLS sin políticas es deliberado para estas tablas sin acceso directo de clientes.
Los asesores pueden seguir avisando de la RPC pública SECURITY DEFINER del dashboard;
no se extiende ese permiso a las RPC de Telegram. Revisar su
[aviso de seguridad](https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable)
y conservar la publicación limitada a la demo autorizada.

## Mensaje para el agente del alumno

```text
Configura mi bot de Telegram como bitácora de mi cuenta MT5 en mi proyecto Supabase.
Lee AGENTS.md, seminario_3/supabase/AGENTS.md y esta guía completa. Descubre qué está
instalado y aplica solo lo necesario. Ayúdame a crear el bot o reutiliza el mío;
no me pidas el token en el chat: lo guardaré como TELEGRAM_BOT_TOKEN en Secrets.
Prueba y despliega el receptor, comprueba el bot y webhook sin reemplazar otra
integración y retira el instalador temporal. Emite un código para mi cuenta,
espera a que yo lo envíe al bot y verifica la vinculación y un motivo real.
Documenta resultados y pendientes sin secretos ni identificadores privados.
No operes en MT5 ni actives cierre remoto. No hagas commits o publicaciones Git.
```

[Volver al seminario 3](../../README.md).

## Acceso al editor web

El comando `/dashboard`, enviado desde el chat privado autorizado, entrega un
código de un solo uso que vence en cinco minutos. Se pega en **Entrar con Telegram**
en la web del alumno. Un comando nuevo invalida el código anterior; no modifica
la vinculación de la cuenta. La sesión de edición dura una hora y permite cambiar
solo motivos humanos. No ejecuta órdenes ni cierra posiciones.

El procedimiento de instalación, control de versiones, historial y pruebas está
[documentado con el dashboard](../../aplicaciones/web/EDICION.md). El comando escrito
funciona aunque el menú de una instalación anterior todavía no lo incluya; el
instalador actualizado lo registra al configurar un bot nuevo.

## Cambios de SL/TP y razones

Aplicar las referencias 9 y 10 del [orden SQL](../../supabase/sql/README.md).
Actualizar receptor, bot, editor y EA v3.40. Repetir el instalador temporal con
`allowed_updates: [message, callback_query]`; retirar `setup.ts` y su configuración
privada al terminar. No cambiar de bot, token ni vinculación por esta actualización.

Cada aviso agrupa cambios observados de una posición durante un minuto. Los
botones **Reducir riesgo** y **Cambio de estructura** guardan esa razón; **Noticia**
y **Otro** piden responder al aviso original con texto (y enlace opcional).
**Después** deja el grupo pendiente, sin crear un recordatorio nuevo.

- `/protecciones`: hasta veinte grupos pendientes, con ID y comando para responder.
- `/proteccion ID explicación`: completar o corregir un grupo, guardando revisiones.
- Responder al aviso original: se utiliza su asociación en base, no el texto citado.
- En web: entrar con Telegram y abrir **Cambios de SL / TP → Completar/Editar motivo**.

Los comandos de apertura y cierre existentes se mantienen. Un botón o un mensaje
nunca modifica SL/TP en MT5. No enviar secretos como parte de las razones públicas.
