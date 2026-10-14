# Configuración resumida — Supabase, Telegram y Vercel

Autoría: QRT Solutions · [www.qrtsolutions.com](https://www.qrtsolutions.com)  
Actualizado: 8 de octubre de 2026.

[Abrir versión HTML](../material/html/configuracion.html) · Lista para navegador e impresión.

Este es el paso a paso abreviado para reproducir la instalación con tu agente.
Cada alumno usa su propia cuenta demo, proyecto Supabase, bot y proyecto Vercel.
Para presentar el recorrido sin reinstalarlo, usa la
[ayuda memoria de la presentación](../material/AYUDA_MEMORIA.md).

## El mapa que conviene explicar primero

| Pieza | Qué hace | Dónde vive |
|---|---|---|
| EA de MT5 | Lee cuenta, posiciones y ejecuciones; envía telemetría | Computador con MT5 abierto |
| Supabase | Guarda los datos y ejecuta los receptores | Nube: base de datos y Edge Functions |
| Telegram | Pide y recibe motivos; entrega acceso temporal al editor | Bot conectado al receptor de Supabase |
| Vercel | Publica la interfaz para computador y celular | Nube: dashboard estático |

**El dashboard vive en Vercel y consulta los datos de Supabase.** Los motivos
escritos desde Telegram o el dashboard terminan en la misma bitácora.
El cierre remoto permanece desactivado; ningún comando del bot modifica trades.

## 1. Preparar el repositorio y los accesos

1. Clona la URL entregada por el docente y abre la raíz del repositorio.
2. Entrega al agente el [prompt de instalación](PROMPT_AGENTE.md). Debe revisar
   qué existe y aplicar solo lo que falta, conservando tus configuraciones.
3. Comprueba acceso a Supabase y Vercel, Telegram disponible y MT5 con cuenta demo.
4. Descubre ambos MCP nativos: terminal en `127.0.0.1:22346` y MetaEditor en
   `127.0.0.1:22345`. El agente lee cuenta, broker y servidor; no los adivina.

**Comprobación:** cuenta demo identificada y ambos conectores responden.
Detalle: [preparación del alumno](README.md) y [MT5](../integraciones/metatrader/README.md).

## 2. Crear Supabase y preparar la base

1. En Supabase, crea o selecciona un proyecto de tu organización. Revisa región,
   plan y condiciones antes de crearlo. Guarda la contraseña de base en tu gestor.
2. Espera a que el proyecto esté disponible y registra su **Project URL** y
   **Project Ref**. Verifica que todas las pantallas y herramientas apunten allí.
3. Conecta el agente mediante el conector Supabase disponible en tu cliente.
   Comprueba el proyecto con una consulta de lectura antes de hacer cambios.
4. En una instalación nueva, aplica las **diez referencias SQL en el
   [orden documentado](../supabase/sql/README.md)**. Si ya existen tablas, compara
   las migraciones y aplica diferencias; no repitas los archivos completos.
5. Comprueba las 17 tablas `mt5_` esperadas para el recorrido completo, RLS y
   permisos. Crear la estructura de publicación todavía no hace pública la cuenta.

**Comprobación:** tablas preparadas, acceso directo público a tablas bloqueado y
proyecto correcto. Detalle: [configuración Supabase](../supabase/CONFIGURACION.md).

## 3. Desplegar el receptor y generar la credencial del EA

Las funciones son los pequeños programas que reciben y validan cada petición:

| Función | Trabajo | Archivos del paquete definitivo |
|---|---|---|
| `mt5-telemetry` | Recibe datos de MT5 y entrega avisos pendientes | `index.ts`, `core.mjs`, `notifications.mjs`, `deno.jsonc` |
| `mt5-telegram` | Recibe mensajes del bot | `index.ts`, `runtime.ts`, `core.mjs`, `deno.jsonc` |
| `mt5-dashboard-editor` | Valida códigos y guarda motivos desde la web | `index.ts`, `core.mjs`, `deno.jsonc` |

Están en `seminario_3/supabase/functions/`. El agente prueba y despliega primero
`mt5-telemetry`; Telegram y el editor se completan en los pasos siguientes.
Los tres ejemplos usan `verify_jwt=false` porque **su código valida su propia
credencial**. Es una configuración de estos receptores, no una regla para otras funciones.

La credencial `mt5_…` se genera con el script del repositorio, no desde API Keys
de Supabase ni desde el broker. Desde la raíz, sustituyendo los marcadores:

```sh
# Autor: QRT Solutions. Sustituir por los datos verificados del alumno.
uv run --locked python seminario_3/supabase/scripts/crear_credencial.py \
  --project-ref TU_PROJECT_REF \
  --login TU_LOGIN \
  --broker "TU_BROKER" \
  --server "TU_SERVIDOR" \
  --project-name "Seminario-3"
```

1. El script crea una clave aleatoria y archivos privados en
   `.local/supabase-setup/device/`; no imprime el secreto.
2. El agente revisa y ejecuta **`register.sql`** de esa carpeta en tu proyecto.
   Registra la huella SHA-256 y la identidad autorizada, no el token en texto claro.
3. Abre **`connection.json`** localmente y copia únicamente el valor de `token`.
   También está como `InpSupabaseKey` en `parameters.json` y en el archivo `.set`.
4. La vigencia predeterminada es **90 días**. Para renovar, genera en un directorio
   nuevo con `--output`, registra, verifica el envío y después revoca la anterior.

**Comprobación:** generar la clave y registrar su hash son dos pasos distintos;
sin registro no funciona. Detalle: [receptor y credencial](../supabase/RECEPTOR.md).

## 4. Configurar MT5 y comprobar recepción

1. El agente compila la fuente del clon mediante MetaEditor MCP y verifica el
   `.ex5`, los errores y las advertencias. Versión del recorrido: **3.40**.
2. En MT5 abre **Herramientas → Opciones → Asesores Expertos**. Activa WebRequest
   y añade la URL base `https://TU_PROJECT_REF.supabase.co`, conservando las demás.
3. En el Navegador, clic derecho en **Asesores Expertos → Actualizar**.
   Adjunta una sola instancia del exportador al gráfico elegido para la cuenta.
4. Completa estos inputs o carga el `.set` privado generado:

| Input visible | Valor |
|---|---|
| URL del Proyecto Supabase | URL base de tu proyecto, sin `/functions/v1/…` |
| Credencial exclusiva del receptor | Valor `token` de `connection.json`, con prefijo `mt5_` |
| Nombre del Proyecto | Exactamente el `project_name` registrado, incluidos guiones y mayúsculas |
| Alias de Broker | Vacío: detección automática |
| Reactividad por evento | `true` |
| Intervalo de latido | `30` segundos |
| Exportar historial / tasas swap | `true` / `true` |
| Símbolos adicionales | Vacío, salvo necesidad propia |
| Cierre remoto | **`false`** |
| Respaldo local / panel | `true` / `true` |

5. Pulsa **OK**. Revisa HTTP 200 en el diario y `received_at` creciente en Supabase.
   Compilar no demuestra conexión; la recepción reciente sí la demuestra.

**Error que resolvimos:** `Seminario3` y `Seminario-3` son nombres distintos.
Con una clave válida, esa diferencia produjo HTTP 403 en snapshots e historial.
No hay que generar otra clave para corregir un input mal escrito.

## 5. Crear y conectar Telegram

1. Abre [BotFather oficial](https://t.me/BotFather), envía `/newbot`, elige un
   nombre visible y un usuario disponible terminado en `bot`.
2. Guarda el token en **el mismo proyecto Supabase → Edge Functions → Secrets**,
   con el nombre exacto **`TELEGRAM_BOT_TOKEN`**. Pulsa **Save** y comprueba la fila.
   `TLG_BOT_TOKEN` no es el nombre leído por este código.
3. El agente prepara el instalador privado:

```sh
# Autor: QRT Solutions. Desde la raíz; elegir un directorio nuevo.
uv run --locked python seminario_3/integraciones/telegram/preparar_instalacion.py \
  --bot-username TU_USUARIO_BOT \
  --output .local/telegram-setup/instalacion-1
```

4. El agente despliega temporalmente `mt5-telegram` con entrada `setup.ts` y el
   paquete indicado en la [guía de instalación](../integraciones/telegram/README.md).
   Luego ejecuta:

```sh
# Autor: QRT Solutions. Después del despliegue temporal, antes de su vencimiento.
uv run --locked python seminario_3/integraciones/telegram/configurar_webhook.py \
  --project-ref TU_PROJECT_REF \
  --installation .local/telegram-setup/instalacion-1
```

5. El instalador verifica el bot y configura el webhook —la dirección a la que
   Telegram entrega los mensajes— con `message` y `callback_query`.
   **Desplegar inmediatamente el paquete definitivo con `index.ts`**, retirando
   `setup.ts` y `setup.private.json`, también si falló la instalación temporal.
6. Abre el chat privado de tu bot y pulsa **Iniciar**. El agente obtiene el
   `account_id` de tu snapshot y genera la vinculación:

```sh
# Autor: QRT Solutions. Usar el identificador propio leído de la base.
uv run --locked python seminario_3/integraciones/telegram/crear_vinculo.py \
  --account-id TU_ACCOUNT_ID \
  --output .local/telegram-setup/vinculo-1
```

7. El agente ejecuta el `register.sql` generado y te entrega el código privado.
   Envía **`/vincular CODIGO_PRIVADO`** a tu bot; después, **`/pendientes`**.
   El código vence una hora después del registro y se usa una sola vez.

**Comprobación:** «Chat vinculado», `/pendientes` responde y solo el propietario
autorizado puede editar. `/start` abre la conversación; no autoriza la cuenta.
La creación del bot y el manejo de Secrets siguen las guías de
[Telegram](https://core.telegram.org/bots/features#botfather) y
[Supabase](https://supabase.com/docs/guides/functions/secrets).

## 6. Publicar el dashboard en Vercel

1. Autoriza expresamente la lectura pública de tu demo y sus motivos.
   El agente habilita **solo esa demo** en `mt5_dashboard_publication` mediante
   el [SQL de publicación](../aplicaciones/web/README.md). Los permisos de escritura
   siguen restringidos.
2. Obtén Project URL y la clave **publishable** de tu proyecto Supabase.
   Es la clave pensada para el navegador; no uses la clave administrativa.
   [Referencia oficial de claves](https://supabase.com/docs/guides/getting-started/api-keys).
3. Desde `seminario_3/aplicaciones/web`, prepara y verifica la aplicación:

```sh
# Autor: QRT Solutions. Configurar los valores propios antes del build.
npm ci
cp .env.example .env.local
# Editar .env.local con las dos variables de la tabla siguiente.
npm test
npm run build
```

| Variable | Valor propio |
|---|---|
| `PUBLIC_SUPABASE_URL` | `https://TU_PROJECT_REF.supabase.co` |
| `PUBLIC_SUPABASE_PUBLISHABLE_KEY` | Clave `sb_publishable_…` |

4. En Vercel crea o selecciona tu proyecto. Si importas un repositorio que ya
   contiene estos archivos, usa esta configuración:

| Ajuste | Valor |
|---|---|
| Root Directory | `seminario_3/aplicaciones/web` |
| Framework Preset | `Other` |
| Node.js | 22.x compatible, mínimo 22.19 para el recorrido documentado |
| Install Command | `npm ci` |
| Build Command | `npm run build` |
| Output Directory | `dist` |
| Variables de producción | Las dos de la tabla anterior |

5. Despliega y abre la **URL estable de producción**. Si no tienes integración
   Git, el agente puede desplegar la aplicación con las herramientas disponibles;
   editar un archivo local no actualiza por sí solo Vercel. Cambiar las variables
   de esta web requiere reconstruir/desplegar, porque se incorporan durante el build.

**Comprobación:** lectura pública de tu demo, datos recientes y columnas de
apertura/cierre. Detalle: [guía web](../aplicaciones/web/README.md) y
[configuración de builds de Vercel](https://vercel.com/docs/builds/configure-a-build).

## 7. Habilitar la edición web mediante Telegram

1. El agente registra la URL HTTPS de producción, **sin barra final**, y el usuario
   del bot, **sin `@`**, en `mt5_dashboard_web_config`.
2. Despliega `mt5-dashboard-editor` y comprueba que `mt5-telegram` incluya `/dashboard`.
3. En la web pulsa **Entrar con Telegram**. Envía **`/dashboard`** a tu bot privado.
4. Copia el código en la web y pulsa **Entrar**. Vence en cinco minutos y sirve una vez.
5. Abre una operación → **Editar motivo / Completar motivo → Guardar motivo**.
   Consulta **Historial** y termina con **Salir de edición**.

La sesión dura una hora; recargar la página la descarta. Los motivos son públicos,
pero editarlos exige autorización. Los comentarios originales del broker y los
datos financieros permanecen separados. Detalle: [editor web](../aplicaciones/web/EDICION.md).

## 8. Prueba final y funcionamiento cotidiano

| Tramo | Resultado que hay que observar |
|---|---|
| MT5 → Supabase | HTTP 200 y varias recepciones con `received_at` creciente |
| Supabase → Vercel | Datos propios en producción; **Actualizar** consulta inmediatamente |
| Telegram | Chat vinculado, consulta y motivo guardado en la operación correcta |
| Edición web | Código válido, cambio guardado, historial y salida de sesión |
| Protección | Cierre remoto `false`; acceso de escritura anónimo rechazado |

Para una demostración, basta usar una operación histórica existente. Si el
propietario decide operar en demo, el aviso de apertura/cierre permite **Responder**
con la razón; el agente no abre una operación para probar. Los deals históricos
no generan una tormenta de avisos: se consultan con `/pendientes`.

La web consulta el estado cada 30 segundos y el historial cada dos minutos.
Los cambios observados de SL/TP se agrupan por posición durante un minuto y su
aviso espera la finalización del grupo y una recepción posterior de telemetría.
El bot registra su explicación; no cambia los niveles en MT5. No se garantiza
entrega instantánea cuando fallan la red o MT5.

## Qué clave va en cada lugar

| Dato | Quién lo genera | Dónde se usa |
|---|---|---|
| Contraseña de base | Creación del proyecto Supabase | Administración de base; nunca en el EA |
| `mt5_…` | `crear_credencial.py` del repositorio | Input del EA; en Supabase se registra su hash |
| Token del bot | BotFather | Secret `TELEGRAM_BOT_TOKEN` en Supabase |
| `sb_publishable_…` | Supabase | Variables públicas del dashboard |
| Código `/vincular` | Generador del repositorio y registro de su hash | Autorizar el chat privado una vez |
| Código `/dashboard` | Bot para el propietario vinculado | Entrar al editor web temporalmente |

## Errores que conviene recordar

| Síntoma | Qué revisar primero |
|---|---|
| No compila | MetaEditor abierto y su MCP disponible; el MCP del terminal no compila |
| HTTP 401 | Credencial `mt5_` registrada, vigente y copiada completa |
| HTTP 403 en cuenta/historial | Login, broker, servidor y nombre exacto del proyecto |
| WebRequest 4014 | URL permitida y contexto de ejecución; no resolver habilitando DLL |
| Bot creado pero sin respuesta | Secret correcto, mismo proyecto, webhook y función definitiva |
| No aparecen botones de edición | Entrar con código `/dashboard`; lectura pública no da permiso de editar |
| Código vencido o página recargada | Pedir otro `/dashboard` y entrar de nuevo |
| Cambio guardado aún no visible | Pulsar **Actualizar**; revisar el proyecto y la publicación |
| Error de origen en editor | Usar el dominio de producción registrado; Preview es otro origen |

Guarda resultados sin secretos en una copia privada del
[registro de instalación](REGISTRO_INSTALACION.md). Consulta
[estado y límites](../ESTADO.md) antes de prometer capacidades y
[entrega](../ENTREGA.md) antes de compartir el repositorio.
