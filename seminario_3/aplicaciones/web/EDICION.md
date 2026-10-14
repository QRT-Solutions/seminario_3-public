# Editar motivos desde el dashboard

Autoría: QRT Solutions.

La web sigue siendo pública para lectura. El propietario autorizado en el bot puede
completar o corregir los **motivos humanos** de apertura y cierre. La edición vive
en Vercel; el guardado, los permisos y el historial viven en Supabase.
Los comentarios originales del EA/broker, precios, volúmenes, fechas y resultados
recibidos de MT5 no se editan desde esta función. El cierre remoto permanece desactivado.

## Uso del propietario

1. Abre tu dashboard y pulsa **Entrar con Telegram**.
2. Abre el bot indicado y envía `/dashboard` en el chat privado ya vinculado.
   Puedes escribir el comando aunque todavía no figure en el menú del bot.
3. Copia el código de la respuesta y pégalo únicamente en el dashboard. Dura
   **cinco minutos**, sirve una vez y un nuevo `/dashboard` invalida el anterior.
   No es el token de BotFather ni el código `/vincular`.
4. Pulsa **Entrar**. Aparecen **Editar motivo** o **Completar motivo** en cada
   fase recibida de las operaciones. Una fase sin ejecuciones todavía no se edita.
5. Escribe entre 1 y 1000 caracteres y pulsa **Guardar motivo**. El texto será
   visible para los visitantes porque esta bitácora es pública.
6. Abre **Historial** dentro del editor para consultar los últimos 50 registros.
   Los cambios web incluyen el valor anterior. Las solicitudes de Telegram se
   presentan como solicitudes recibidas: el historial antiguo no identifica si
   una petición atrasada llegó a reemplazar el valor vigente.
7. Usa **Salir de edición** al terminar. La sesión dura una hora. Recargar o cerrar
   la página descarta la credencial del navegador; no la guarda en cookies ni en
   almacenamiento persistente. El registro servidor expira como máximo en una hora.

Si Telegram u otra ventana cambian el motivo mientras escribes, el guardado se
rechaza para evitar perder esa modificación. Pulsa **Cargar versión actual**,
compara el motivo vigente con tu borrador (se conserva) y vuelve a guardar cuando
corresponda. **Renovar acceso** permite iniciar sesión sin perder el borrador.
El historial conserva las versiones; restaurar una versión consiste en copiar su
texto y guardarlo como una modificación nueva, sin borrar registros anteriores.

## Muestras didácticas autorizadas

Si el propietario pide completar una demo con ejemplos, marcar cada motivo como
`Ejemplo didáctico` y aclarar cuando la intención sea ficticia. No deducir señales
de soporte, tendencia o noticias solamente por la hora o el resultado del trade.
Conservar los motivos existentes y los comentarios originales del broker; llenar
únicamente fases que tengan ejecuciones recibidas. Los ejemplos no sirven como
evidencia de la decisión real ni deben mezclarse con motivos reales al analizarlos.

El propietario pidió después abreviar los 199 textos de esta muestra y retirar
el prefijo visible. Ahora muestran el efecto buscado, por ejemplo «Capturar rebote
alcista en soporte» y «Reducir exposición». Su origen continúa siendo sintético:
las revisiones conservan el texto anterior etiquetado en `previous_reason` y la
bitácora registra la solicitud. Una frase sin etiqueta visible no acredita una
intención real; para análisis de motivos se debe consultar esa procedencia.

En la muestra del 8 de octubre se agruparon aperturas del mismo símbolo, dirección
y tipo de ejecución con separación máxima de cinco segundos y duración máxima
de treinta segundos por grupo. Los cierres se agruparon por proximidad temporal
y tipo de ejecución, incluso entre símbolos. Cada grupo comparte exactamente el
mismo texto. Esta es una convención de la muestra, no una prueba de señal común.

La carga administrativa autorizada añadió 199 motivos en 100 operaciones y
conservó cinco motivos previos: las 102 operaciones quedaron completas. Se guardó
respaldo privado, se ensayó con ROLLBACK y se registraron las 199 revisiones en
`mt5_web_reason_audit` con `actor_user_id=0`, identificador administrativo de esta
carga; no representa a un usuario de Telegram. El historial actual las presenta
con origen `web` por reutilizar esa tabla, aunque se cargaron mediante SQL
administrativo. La bitácora documenta esta diferencia. No se emitieron sesiones
ni mensajes del bot. Los alumnos no deben ejecutar esta carga automáticamente
en sus cuentas: cada muestra requiere autorización y datos propios.

## Instalación reproducible con tu agente

Primero completa la [conexión del bot](../../integraciones/telegram/README.md),
la [bitácora de operaciones](../../supabase/CONTRATO_DATOS.md) y la publicación de
este [dashboard](README.md). Cada alumno usa sus propios proyectos, bot y cuenta;
ninguna credencial del docente forma parte del clon.

1. El agente confirma el proyecto Supabase destino, la URL pública de Vercel y el
   `username` del bot. Revisa tablas y migraciones existentes para aplicar solo
   lo que falta. No reutiliza identificadores del docente.
2. Aplica como administrador [dashboard_editor.sql](../../supabase/sql/dashboard_editor.sql)
   **una vez**, después de las migraciones de bitácora y Telegram. Crea cuatro
   tablas privadas y dos funciones accesibles únicamente por `service_role`.
3. Configura el origen exacto y el bot con los valores del alumno. Ejemplo ilustrativo:

   ```sql
   -- Autor: QRT Solutions. Sustituir ambos ejemplos antes de ejecutar.
   insert into public.mt5_dashboard_web_config(singleton,origin,bot_username)
   values (true,'https://mi-dashboard.vercel.app','mi_bitacora_bot')
   on conflict(singleton) do update
     set origin=excluded.origin,bot_username=excluded.bot_username;
   ```

   El origen no lleva barra final, ruta ni parámetros. Se permite un origen HTTPS.
   Los despliegues Preview y localhost no obtienen permiso de edición por defecto.
   Para probar toda la integración, usa un proyecto separado con su propio origen.
4. Despliega la carpeta [mt5-dashboard-editor](../../supabase/functions/mt5-dashboard-editor/index.ts)
   con `index.ts`, `core.mjs` y `deno.jsonc`. Usa su
   [configuración de ejemplo](../../supabase/functions/mt5-dashboard-editor/config.example.toml).
   `verify_jwt=false` corresponde a autenticación propia en el código: **no** hace
   públicas las escrituras. Nunca desactivar la comprobación de sesión.
5. Despliega la versión actual de [mt5-telegram](../../supabase/functions/mt5-telegram/index.ts),
   incluyendo `runtime.ts`, `core.mjs` y `deno.jsonc`. Ya utiliza el secreto
   `TELEGRAM_BOT_TOKEN` guardado en Supabase; no se necesita copiarlo a Vercel.
   El comando `/dashboard` requiere un editor activo y un chat privado previamente
   vinculado. Una instalación nueva con `setup.ts` también lo añade al menú.
6. Publica la aplicación web con `npm ci` y `npm run build`, directorio `dist`.
   Incluye `src/editor.mjs` al desplegar fuentes. Conserva únicamente las variables
   públicas `PUBLIC_SUPABASE_URL` y `PUBLIC_SUPABASE_PUBLISHABLE_KEY` de la guía web.
7. Ejecuta las pruebas siguientes y verifica visualmente acceso, edición de una
   razón real autorizada, consulta pública y salida. No inventes motivos para
   probar en datos de alumnos o del docente.

## Verificación y límites

Desde la raíz del repositorio:

```bash
node --test seminario_3/supabase/functions/mt5-dashboard-editor/core.test.mjs seminario_3/supabase/functions/mt5-telegram/core.test.mjs
npm --prefix seminario_3/aplicaciones/web test
npm --prefix seminario_3/aplicaciones/web run build
```

[verificar_dashboard_editor.sql](../../supabase/sql/verificar_dashboard_editor.sql)
comprueba códigos, consumo único, guardado, concurrencia, auditoría, revocación,
expiración y permisos dentro de una transacción con `ROLLBACK`. Necesita al menos
un editor activo y una apertura recibida. No deja razones de prueba publicadas.

El navegador recibe una sesión aleatoria; Supabase conserva solo su hash. La
cuenta y la identidad se resuelven en el servidor, nunca desde campos enviados
por el navegador. Cada guardado comprueba además la autorización activa y la
existencia de la fase. La clave de reintento impide duplicar un mismo guardado.
La versión utiliza el `updated_at` original con toda su precisión, sin redondearlo
con `Date` en JavaScript. Los textos se muestran literalmente mediante `textContent`.

Este acceso utiliza códigos privados enviados por el bot; no requiere instalar
el widget OAuth/OIDC de Telegram. Quien tenga un código aún válido puede consumirlo:
trátalo como una credencial temporal. El token del bot y la clave de servicio
nunca se envían al navegador. No hay permisos de trading asociados a esta sesión.

Para revocar el acceso, desactiva la fila correspondiente de
`mt5_telegram_editors` siguiendo la guía de Telegram: las sesiones existentes
fallan en su próxima operación. Los registros de códigos consumidos y sesiones
expiradas se conservan para diagnóstico; esta versión no instala limpieza programada.

Los avisos informativos de RLS sin políticas corresponden a tablas sin acceso
directo de clientes. Las advertencias de ejecución pública de
`mt5_public_dashboard()` son anteriores y corresponden a la lectura demo autorizada;
las nuevas funciones de edición no tienen permisos para `anon` o `authenticated`.
Consulta la [explicación oficial de RLS sin políticas](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy)
y la [advertencia de funciones públicas](https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable).

## Motivos de protección

La extensión [protecciones_bitacora.sql](../../supabase/sql/protecciones_bitacora.sql)
añade las acciones autenticadas `protection` y `save_protection`. Reutiliza la
sesión de una hora y valida propiedad, identificador, idempotencia y versión
actual antes de guardar. Cada revisión conserva anterior/nuevo y actor; solo el
motivo vigente se publica. No permite editar niveles ni comentarios del broker.
