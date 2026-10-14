# Configuración de Supabase con tu agente

Autoría: QRT Solutions. Revisión: 8 de octubre de 2026, America/Santiago.

## 1. Revisar el entorno

Abre la raíz del repositorio y usa el mensaje del [README](README.md). El agente
debe revisar archivos, cambios locales, instrucciones y herramientas disponibles.
Necesitas acceso a Supabase y permiso para crear un proyecto en tu organización.
MT5 solo será necesario para el envío; consulta su
[guía de conexión](../integraciones/metatrader/README.md) por separado.

La fuente [MT5_Telemetry_Exporter_Universal.mq5](../../MT5/MT5_Telemetry_Exporter_Universal.mq5)
se distribuye en el clon, versión 3.40. Leerla antes de compilar y seguir
[RECEPTOR.md](RECEPTOR.md) para emitir la credencial y configurar el envío. No
sustituirla por otro EA del catálogo ni asumir rutas del equipo docente.

## 2. Conectar el agente

Consulta la [guía oficial del MCP de Supabase](https://supabase.com/docs/guides/ai-tools/mcp)
y selecciona el cliente instalado. La configuración puede cambiar entre versiones.

| Cliente | Procedimiento |
|---|---|
| Codex | Usar el conector/plugin Supabase existente o la configuración MCP vigente de su cliente |
| Claude Code | Incorporar el servidor HTTP en su configuración MCP, conservando los demás servidores |
| Antigravity | Revisar su configuración MCP y soporte de autenticación; no asumir que lee archivos de otro cliente |
| Cliente sin herramientas conectadas | Preparar y revisar SQL con el agente; ejecutar en el panel y aportar resultados sanitizados |

Endpoint del servicio alojado:

```text
https://mcp.supabase.com/mcp
```

Completa OAuth en el navegador y selecciona tu organización. El flujo habitual
no requiere pegar contraseñas de base ni tokens personales en el chat. Si el
cliente necesita otra configuración, consultar su documentación actual.

Verifica la conexión con una consulta de solo lectura. Descubrir el catálogo y
los esquemas antes de invocar herramientas: sus nombres pueden llevar prefijos
distintos. Capacidades útiles: `list_projects`, `get_project`, `list_tables` y
`search_docs`. Que una herramienta esté documentada no demuestra que el conector
actual la ofrezca.

Cuando exista el proyecto, limitar el conector a su referencia si el cliente lo
permite:

```text
https://mcp.supabase.com/mcp?project_ref=TU_PROJECT_REF
```

Para inspección se puede añadir `&read_only=true`; ese modo impide crear tablas.
Un conector limitado a un proyecto puede omitir herramientas de organización y
creación de proyectos. Estas opciones se describen en la guía oficial anterior.

## 3. Crear o seleccionar el proyecto

Comprobar primero si ya existe el proyecto que el alumno quiere utilizar.
Resolver cualquier ambigüedad de organización o destino antes de modificarlo.

| Dato | Elección para el ejercicio | Motivo |
|---|---|---|
| Organización | La del alumno | Separar entornos |
| Nombre | Por ejemplo, `seminario-3-alumno` | Reconocer el laboratorio |
| Región | Cercana al alumno; São Paulo en la demostración | Reducir recorrido de red |
| Plan | Revisar precio, cupo y condiciones actuales | No asumir creación gratuita |
| Contraseña de base | Introducir en el formulario y guardar en un gestor | Credencial administrativa; no va en el EA |
| Data API | Habilitada para esta arquitectura | Acceso del componente que escribirá datos |
| Exponer tablas nuevas automáticamente | Desactivado, si aparece la opción | Conceder permisos expresamente |
| Activar RLS automáticamente | Activado, si aparece la opción | Protección al crear tablas |

Si las herramientas de creación y costes existen y la acción está autorizada,
el agente puede usarlas. En caso contrario, usar el panel. En la demostración
faltó `get_cost`: se creó desde el panel y se verificó después con el conector.
No repetir una herramienta ausente ni inventar una confirmación de coste.

Después, comprobar nombre, referencia, organización, región y estado saludable.
Obtener la URL mediante herramienta o panel, sin deducirla del nombre. Guardar
estos detalles en el registro local del alumno.

## 4. Crear el esquema

Leer el [contrato de datos](CONTRATO_DATOS.md) y el
[SQL de referencia](sql/esquema_telemetria.sql), aplicado en la demostración al
EA v3.10. No contiene credenciales ni datos del docente.

Listar tablas y migraciones del destino antes de ejecutar:

- Si las tablas no existen, aplicar el SQL como migración remota mediante
  `apply_migration` o el mecanismo equivalente documentado del cliente.
- Si existen, comparar columnas, tipos, claves y permisos; preparar solo las
  diferencias necesarias. El SQL no está diseñado para ejecutarse repetidamente.
- No usar borrados, reinicios o `CREATE TABLE IF NOT EXISTS` para ocultar
  incompatibilidades o evitar la revisión del esquema existente.

Si se van a conservar migraciones mediante Supabase CLI, comprobar versión y ayuda
con `supabase --help` y `supabase migration new --help`. Inicializar el directorio
según la ayuda vigente solo si no está inicializado. Crear el archivo mediante
`supabase migration new create_mt5_telemetry_storage` y copiar allí el SQL revisado.
No inventar marcas de tiempo ni aplicar dos veces una migración que el conector
ya ejecutó: conciliar antes los historiales local y remoto. Esta carpeta contiene
referencias SQL, no una orden para ejecutar `db push` a ciegas.

Las tablas activan RLS y revocan permisos a `anon` y `authenticated`. Los permisos
determinan si se puede acceder a una tabla; RLS filtra después sus filas. En esta
etapa no existen políticas de acceso de clientes y el envío directo del EA aún
no debe funcionar. Consulta [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security)
y [protección de la API](https://supabase.com/docs/guides/api/securing-your-api).

## 5. Verificar y documentar

Ejecutar las [consultas de verificación](sql/verificar_telemetria.sql) por separado
si el cliente solo muestra el resultado de la última sentencia.

| Comprobación | Resultado inicial esperado |
|---|---|
| Tablas | Tres, con columnas y claves del contrato |
| RLS | Activado en las tres |
| Roles `anon` y `authenticated` | Sin permisos sobre esas tablas |
| Filas | Cero en un proyecto nuevo; no vaciar uno reutilizado |
| Asesores de seguridad | Sin advertencias sin resolver; explicar avisos informativos |

En la demostración apareció una advertencia sobre `public.rls_auto_enable()`,
creada por la opción de RLS automático del panel. Solo si existe y se verifica
que es esa función administrativa, revisar el
[SQL de corrección de permisos](sql/restringir_rls_automatico.sql). No crear esa
función solo para aplicar la corrección. Volver a ejecutar los asesores.

El aviso [RLS sin políticas](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy)
es informativo y esperado en esta etapa. No silenciarlo con una política que
permita todo. Guardar evidencia privada en `.local/supabase-setup/`, excluido de
Git. Publicar fecha, acción, comprobación y limitaciones sin datos personales.

## 6. Instalar el receptor y conectar el EA

Continúa con [RECEPTOR.md](RECEPTOR.md): contiene el SQL incremental, despliegue,
generación local de credenciales, registro del hash, compilación del EA, inputs,
WebRequest y verificación. La fuente v3.40 ya tiene compilación y recepción
verificadas en el entorno docente; repetir ambas comprobaciones en cada instalación.
Instalar primero las columnas de comentarios siguiendo el [orden SQL](sql/README.md).

Cada credencial queda vinculada a login, broker, servidor y etiqueta de proyecto.
No colocar contraseñas de base ni claves administrativas de Supabase en el EA.
La conexión OAuth del agente es independiente de la credencial de telemetría.

La instalación requiere añadir el dominio propio a WebRequest en MT5. En la
prueba docente, el error `4014` desapareció cuando el usuario añadió ese dominio;
el EA reintentó y se comprobaron registros sin abrir operaciones ni activar DLL.

## Problemas frecuentes

| Síntoma | Siguiente comprobación |
|---|---|
| Agente sin acceso a Supabase | Conector, OAuth, organización y catálogo real |
| No puede crear proyectos | Alcance `project_ref`, permisos y capacidades; panel como alternativa |
| HTTP 401 o token inválido | Mecanismo y cabeceras de autenticación; no intercambiar contraseña, API key y JWT |
| HTTP 403 | Permisos y receptor; es esperado durante la etapa de tablas cerradas |
| Conflicto al enviar | Comparar `on_conflict` con las claves instaladas |
| Compila pero no llegan filas | Receptor, parámetros, WebRequest, HTTP y lectura en base; no activar trading como solución |

[Volver a Supabase](README.md).

## Continuar con Telegram

La [guía de Telegram](../integraciones/telegram/README.md) explica desde BotFather
hasta la vinculación y prueba de un motivo. Guardar `TELEGRAM_BOT_TOKEN` en Secrets
del mismo proyecto que recibe MT5. Verificar nombre y referencia de proyecto y
el nombre exacto del secreto antes de pulsar Save. El bot necesita un receptor
desplegado y webhook; `/start` no autoriza a consultar la cuenta.

## Origen del editor web

Después de configurar el bot y publicar Vercel, aplica la migración incremental
[dashboard_editor.sql](sql/dashboard_editor.sql). Registra en
`mt5_dashboard_web_config` el origen HTTPS exacto de tu dashboard y el nombre de
tu bot, sin `@`. No son secretos; los códigos y sesiones sí lo son. El receptor
`mt5-dashboard-editor` mantiene el acceso restringido mediante autenticación propia.
Sigue la [guía de edición](../aplicaciones/web/EDICION.md) para despliegue y pruebas.
