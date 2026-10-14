# Guía completa del alumno — MT5, Supabase, Telegram y Vercel

Autoría: QRT Solutions. Actualizada: 8 de octubre de 2026.

Al terminar tendrás una bitácora conectada a **tu cuenta demo**: MT5 envía datos,
Supabase los guarda, Telegram solicita las razones y Vercel muestra el dashboard.
Podrás corregir los motivos desde Telegram o desde la web con acceso restringido.
Cada alumno usa su propia cuenta, proyecto y bot.

Esta guía coordina el recorrido completo. Las guías de cada componente contienen
los comandos y detalles; no es necesario reconstruir el proceso desde el chat del docente.

Si es tu primer contacto con el proyecto o prefieres explorar sin configurar cuentas aún, consulta **[Empieza aquí (Primer ejercicio sin credenciales)](EMPIEZA_AQUI.md)**.
Para una lectura más breve, usa el [resumen de configuración](RESUMEN_CONFIGURACION.md).
Para la clase, abre la [ayuda memoria de la presentación](../material/AYUDA_MEMORIA.md).

## 1. Entender qué vive en cada lugar

| Componente | Función | Dónde se ejecuta |
|---|---|---|
| Expert Advisor de telemetría | Lee la cuenta y envía estados y ejecuciones | Tu instalación de MT5, abierta y conectada |
| Supabase | Guarda datos, valida credenciales y procesa mensajes | Proyecto en la nube del alumno |
| Bot de Telegram | Solicita motivos y recibe tus respuestas | Telegram, conectado a una función de Supabase |
| Dashboard | Muestra datos y permite editar motivos al propietario | Vercel; los datos permanecen en Supabase |
| Agente y conectores MCP | Ayudan a instalar, compilar, desplegar y comprobar | Tu cliente Codex, Claude Code o Antigravity |

```text
MT5 → receptor mt5-telemetry → Supabase → consulta limitada → dashboard Vercel
                                  ↓                              ↓
                         aviso al bot Telegram          editor web autorizado
                                  ↓                              ↓
                         tu motivo de apertura/cierre → bitácora en Supabase
```

El bot no es una estrategia de trading. El exportador no abre ni cierra posiciones.
Los conectores administrativos del agente tampoco son las credenciales del EA.

## 2. Preparar el clon y el agente

Obtén la URL de distribución que entregue el docente y clona ese repositorio.
Abre su **carpeta raíz**, donde están `AGENTS.md`, `MT5/` y `seminario_3/`.
Si ya tienes un clon, el agente debe revisar qué existe antes de copiar archivos.
No necesitas el directorio privado del seminario 2 del docente.

| Requisito | Para qué se utiliza |
|---|---|
| Git, uv y Python 3.12 | Laboratorio, esquemas, generación de credenciales y documentación |
| Node.js 22.19+ compatible y npm | Pruebas de las funciones y construcción del dashboard |
| MT5 y MetaEditor con sus MCP nativos | Detectar cuenta, instalar y compilar el exportador |
| Cuenta Supabase y acceso al proyecto propio | Tablas y funciones de la nube |
| Telegram y bot propio | Bitácora y acceso de edición |
| Cuenta Vercel | Publicar la aplicación web |

Desde la raíz:

```sh
uv sync --locked
uv run --locked seminario doctor
uv run --locked seminario verify
uv run --locked python .agents/skills/mt5-platform-operator/tests/run_offline.py
```

Estas comprobaciones son locales. No prueban que MT5 ni las nubes estén conectados.
Para la instalación asistida, copia el [mensaje completo para tu agente](PROMPT_AGENTE.md).
El agente adapta la configuración a tu sistema y descubre las herramientas reales;
no se presupone que todos los clientes acepten los mismos archivos.

## 3. Conectar MT5 y MetaEditor

Sigue la [guía MT5](../integraciones/metatrader/README.md), incluida su sección de
configuración local. El servidor del terminal usa normalmente `22346` y el de
MetaEditor `22345`, ambos en `127.0.0.1`. Comprueba cada uno por separado.

El resultado de esta fase es una lectura verificada de login, broker y servidor,
más la disponibilidad del compilador. Guarda esos datos solo en tu registro local.
No cambies la cuenta para hacer coincidir un ejemplo ni actives trading como prueba.

La migración fue selectiva: se conserva la skill completa y cuatro referencias
MT5, además de las herramientas heredadas útiles. No hacen falta los 21 manuales
ni los bridges y servidores alternativos del repositorio privado anterior.

## 4. Crear Supabase e instalar el esquema

1. Sigue [CONFIGURACION.md](../supabase/CONFIGURACION.md): proyecto propio,
   organización correcta, URL y conexión del agente.
2. Guarda la contraseña de la base en tu gestor; no va en el EA ni en el chat.
3. Lee el [contrato de datos](../supabase/CONTRATO_DATOS.md).
4. Aplica el [orden canónico de SQL](../supabase/sql/README.md). En un proyecto
   nuevo se preparan las doce referencias en orden antes de activar la integración
   completa. En uno existente se comparan tablas e historial y se aplican diferencias.

Preparar la tabla de publicación no publica una cuenta: empieza sin una demo
habilitada. La autorización y activación de lectura pública se hacen más adelante.
Los archivos `verificar_*.sql` son comprobaciones; no son migraciones de instalación.

**Punto de control:** tablas y funciones esperadas, RLS habilitado, escrituras
públicas bloqueadas y proyecto destino confirmado.

## 5. Instalar el receptor y el exportador

Sigue [RECEPTOR.md](../supabase/RECEPTOR.md) en este orden:

1. Prueba y despliega `mt5-telemetry` con todos sus archivos.
2. Genera una credencial propia vinculada a la identidad leída de MT5. El script
   crea archivos privados bajo `.local/`; ejecuta únicamente su SQL de registro
   del hash en tu Supabase. No envíes el archivo que contiene el token al conector.
3. Compila la fuente del repositorio mediante MetaEditor MCP. La fuente actual
   es **v3.40**, compilada y con recepción verificada en el entorno docente. Debes
   repetir la comprobación de compilación y recepción en tu instalación.
4. Añade `https://TU_PROJECT_REF.supabase.co` a las URL permitidas para WebRequest.
5. En MT5: `Ctrl+N → Asesores Expertos → clic derecho → Actualizar`. Carga el EA
   en el gráfico elegido y sus inputs desde el `.set` privado generado.
6. Conserva `InpEnableKillSwitch=false`, `InpEventDrivenSync=true` y latido de
   30 segundos. Mantén una sola instancia de telemetría por cuenta.

La v3.40 envía entradas/salidas y comentarios nativos. Necesita la extensión SQL
`bitacora_trades.sql` **antes** de enviar esos campos. No basta con las tres tablas
iniciales. Activar el EA también puede enviar histórico.

**Punto de control:** HTTP 200 y `received_at` avanzando en Supabase. Un mensaje de
compilación correcta no demuestra envío. La ausencia de operaciones puede ser
válida; el agente no abre trades para obtener filas.

## 6. Publicar el dashboard

La aplicación vive en **Vercel**; no se aloja dentro de las tablas de Supabase.
Sigue la [guía web](../aplicaciones/web/README.md):

1. Decide expresamente si quieres publicar tu demo. Los visitantes verán cifras,
   operaciones y motivos. La cuenta real no es destino de esta publicación.
2. Habilita solo tu demo en `mt5_dashboard_publication`, siguiendo el SQL de la guía.
3. Configura las dos variables públicas de tu proyecto en `.env.local` y Vercel.
4. Ejecuta `npm ci`, `npm test` y `npm run build` dentro de
   `seminario_3/aplicaciones/web`.
5. Publica con esa carpeta como raíz y `dist` como salida. Verifica la URL estable
   de producción, que puede diferir del enlace protegido de un despliegue concreto.

**Punto de control:** datos reales y comentarios de apertura/cierre en columnas
separadas. Los filtros del historial no filtran la tabla de motivos. El dashboard
consulta el estado cada 30 segundos y el historial cada 2 minutos; no promete mostrar cada cambio instantáneamente.

## 7. Crear y vincular Telegram

La [guía Telegram](../integraciones/telegram/README.md) incluye el paso a paso:

1. BotFather oficial → `/newbot` → nombre → usuario disponible terminado en `bot`.
2. Guarda el token como **`TELEGRAM_BOT_TOKEN`** en **Secrets del mismo proyecto
   Supabase**. Pulsa Save; `TLG_BOT_TOKEN` no es el nombre que usa esta implementación.
3. El agente despliega el instalador temporal, comprueba el bot y registra el webhook.
   Después debe desplegar la versión definitiva, sin archivos de instalación privados.
4. Inicia el chat con el bot. El agente genera un código para tu cuenta y registra
   su hash; tú envías `/vincular CODIGO_PRIVADO` en ese chat.
5. Comprueba «Chat vinculado» y `/pendientes`. `/start` por sí solo no concede acceso.

**Punto de control:** solo tu chat privado vinculado puede consultar y completar
motivos. Una cuenta y un bot por proyecto en esta versión.

## 8. Completar razones y editar desde la web

Cuando el propietario abre o cierra una operación demo y llega el evento, el bot
solicita la razón. Usa **Responder** sobre ese aviso: así la respuesta queda ligada
a la operación y fase correctas. Un mensaje suelto no se asigna al último trade.
`/cierre` registra una explicación; no cierra posiciones.

Para editar en la web, completa [EDICION.md](../aplicaciones/web/EDICION.md):
configura origen HTTPS exacto y nombre del bot en `mt5_dashboard_web_config`,
despliega `mt5-dashboard-editor` y el bot actualizado. Después:

1. Pulsa **Entrar con Telegram** en el dashboard.
2. Envía `/dashboard` al bot y pega el código privado **en la web**, no en el chat del agente.
3. Pulsa **Editar motivo** o **Completar motivo** y guarda el texto.
4. Consulta el historial; al terminar pulsa **Salir de edición**.

El código dura cinco minutos y es de un solo uso; la sesión dura una hora y se
pierde al recargar la página. Si hay un cambio simultáneo, carga la versión actual,
compara y decide qué guardar. Tu borrador se conserva.

## 9. Saber qué texto significa cada cosa

| Texto | Origen y uso |
|---|---|
| Comentario de ejecución/orden | Literal recibido de MT5; puede contener una etiqueta del EA o del broker |
| `deal_reason` y `magic` | Metadatos técnicos; por sí solos no explican la intención humana |
| Motivo de apertura | Explicación escrita por el propietario en Telegram o en el dashboard |
| Motivo de cierre | Explicación de la salida o reducción de volumen ya recibida |

Los comentarios de un EA se conservan y muestran; no se traducen automáticamente
en una explicación inventada. Si el broker o EA dejó el comentario vacío, no se
reconstruye una razón. En operaciones discrecionales la completa el propietario.
Los cierres parciales de una posición comparten el mismo motivo de cierre.

## 10. Verificar y conservar tu instalación

Completa el [plan de pruebas](../pruebas/README.md) y los
[ejercicios guiados](../ejemplos/README.md). Registra resultados en una copia de la
[plantilla de instalación](REGISTRO_INSTALACION.md) dentro de `.local/`.
No publiques números de cuenta, tokens, códigos de vinculación, capturas de Secrets,
inputs privados, logs completos ni copias de la carpeta de datos de MT5.

| Incidencia | Primer paso |
|---|---|
| MetaEditor desconectado | Revisar su MCP; el terminal y el compilador son servicios distintos |
| MT5 error 4014 | Verificar WebRequest y contexto de ejecución, sin habilitar DLL |
| Receptor 401 / 403 | Revisar token vigente / identidad y nombre exacto del proyecto, incluidos guiones; no usar una clave administrativa |
| Comentarios nativos ausentes | Contrastar versión del EA, columnas SQL y datos recibidos; pueden ser vacíos |
| Telegram no responde | Confirmar bot, nombre del secreto, proyecto y webhook |
| No llega aviso de un deal antiguo | El histórico no dispara solicitudes nuevas; usar `/pendientes` |
| Edición web rechazada por origen | Usar el dominio de producción configurado, sin barra final |
| Código web vencido | Enviar `/dashboard` otra vez; el código previo deja de servir |
| Guardado en conflicto | Cargar versión actual y comparar con el borrador antes de guardar |

La bitácora no calcula MAE/MFE, riesgo inicial, Sharpe o equity histórica con datos
que no recibe. La hora de los deals todavía requiere normalización; no asumir UTC.
La entrega depende de MT5 y la red, y los reintentos del bot dependen de nuevas
recepciones de telemetría. Consulta los límites completos en cada guía.

[Estado y evidencias](../ESTADO.md) · [Índice del seminario](../README.md).

La ampliación vigente se explica en [Ajustes simples](AJUSTES_SIMPLES.md): SL/TP, Telegram, edición, móvil y paginación.
