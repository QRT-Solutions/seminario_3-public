# Receptor de telemetría: instalación y operación

Autoría: QRT Solutions. Fuente del EA: v3.40; evidencia histórica de compilación: v3.20.

## Diseño implementado

El EA envía JSON por HTTPS a `functions/v1/mt5-telemetry`. La Edge Function
comprueba una credencial de dispositivo y la identidad autorizada antes de escribir
las tres tablas. El EA no recibe permisos administrativos de Supabase ni puede
consultar tablas a través de este receptor.

La tabla adicional `mt5_ingest_credentials` guarda el SHA-256 de la credencial,
login, broker, servidor, identificador de cuenta, etiqueta de proyecto, vigencia y
estado de revocación. No almacena la credencial en texto claro. Las cuatro tablas
mantienen RLS y no conceden acceso a `anon` ni `authenticated`. Solo el componente
servidor puede consultar las autorizaciones y actualizar telemetría.

El poseedor de una credencial puede enviar datos para la identidad asignada;
esto no acredita criptográficamente que los datos provengan del broker. Debe
protegerse como una contraseña. No se admite otra cuenta con la misma credencial.

## 1. Preparar el proyecto propio

Completa [CONFIGURACION.md](CONFIGURACION.md), verifica proyecto y tablas, y revisa
el [SQL incremental](sql/receptor_telemetria.sql). Aplicarlo una sola vez como
migración remota `add_scoped_telemetry_receiver`. Si ya existe, comparar estructura
y permisos en lugar de repetirlo. La columna `received_at` se genera en el servidor
para distinguir hora declarada por el EA y hora de recepción.

Para migraciones en archivos CLI, crearlas con `supabase migration new`, como
indica la guía de configuración; los archivos de `sql/` son referencias sin versión.

La fuente actual v3.40 envía campos de comentarios. Antes de adjuntarla, aplicar
además `dashboard_publico.sql` y `bitacora_trades.sql` según el
[orden SQL](sql/README.md). Para el recorrido completo, preparar las diez referencias
y sus dependencias antes de activar la integración.

## 2. Desplegar la función

El código está en [index.ts](functions/mt5-telemetry/index.ts), con autenticación
y validación en [core.mjs](functions/mt5-telemetry/core.mjs), sin dependencias externas.

Antes de desplegar, ejecutar desde la raíz:

```sh
node --test seminario_3/supabase/functions/mt5-telemetry/core.test.mjs
```

El agente debe descubrir `deploy_edge_function` o la herramienta equivalente y
proporcionar:

| Campo | Valor |
|---|---|
| Proyecto | Referencia del proyecto del alumno, verificada antes de mutar |
| Nombre | `mt5-telemetry` |
| Entrada | `index.ts` |
| Archivos | `index.ts`, `core.mjs`, `notifications.mjs`, `deno.jsonc`, con sus contenidos completos |
| `verify_jwt` | `false`, porque el código valida una credencial propia en cada petición |

Desactivar la validación JWT **no** significa permitir peticiones anónimas: el
receptor exige `x-mt5-token`, calcula su hash y consulta una autorización activa y
no expirada antes de procesar datos. No desplegar una versión sin ese control.
Consultar la [autenticación de funciones](https://supabase.com/docs/guides/functions/auth)
y la [migración de claves](https://supabase.com/docs/guides/getting-started/migrating-to-new-api-keys).

La función obtiene el secreto administrativo exclusivamente del entorno de Supabase:
`SUPABASE_SECRET_KEYS.default`, o `SUPABASE_SERVICE_ROLE_KEY` como compatibilidad
con entornos anteriores. No hay que distribuir esos secretos al EA. Si faltan,
corregir la configuración del entorno; no incrustarlos en el código.
Para CLI se proporciona [config.example.toml](functions/mt5-telemetry/config.example.toml).
Consultar la ayuda vigente antes de ejecutar un comando de despliegue.

## 3. Emitir la credencial restringida

Leer login, broker y servidor mediante MCP nativo de MT5. Obtener el proyecto de
Supabase mediante su conector. No inventar valores ni reutilizar los del docente.
Mantener `InpBrokerAlias` vacío para que coincida el broker leído.

El script [crear_credencial.py](scripts/crear_credencial.py) genera una credencial
aleatoria de 256 bits con prefijo `mt5_`, vigencia de 90 días por defecto y archivos
locales con permisos restrictivos. No imprime el secreto ni registra nada remoto.
Ejemplo con **valores a sustituir**, no ejecutable tal cual:

```sh
python seminario_3/supabase/scripts/crear_credencial.py \
  --project-ref TU_PROJECT_REF \
  --login TU_LOGIN \
  --broker "TU_BROKER" \
  --server "TU_SERVIDOR" \
  --project-name "Seminario-3"
```

El destino predeterminado es `.local/supabase-setup/device/`. El script comprueba
que Git lo ignora y rechaza sobrescribir un directorio existente. Para una rotación,
utilizar un directorio nuevo con `--output`. En Windows, revisar también los permisos
NTFS del directorio: el modo POSIX no sustituye las ACL de Windows.

| Archivo local privado | Uso |
|---|---|
| `connection.json` | Credencial, identidad, URL y vencimiento; nunca publicar |
| `parameters.json` | Valores exactos de los inputs para el agente |
| `MT5_Telemetry_Supabase.set` | Cargar los inputs desde MT5 sin transcribir el secreto |
| `register.sql` | Registrar el hash y el alcance en el proyecto correcto |
| `revoke.sql` | Desactivar únicamente esa credencial |

Revisar el alcance de `register.sql` y ejecutarlo mediante `execute_sql` autorizado.
Es una operación de datos, no una migración de esquema. La credencial solo funciona
cuando ese registro existe. No imprimir ni enviar `connection.json` al conector.
El registro usa exclusivamente el hash, nunca el token en texto claro.

## 4. Compilar y configurar MT5

La fuente distribuible está en
[MT5_Telemetry_Exporter_Universal.mq5](../../MT5/MT5_Telemetry_Exporter_Universal.mq5).
Descubrir MetaEditor MCP, comprobar sus raíces permitidas, respaldar la versión
anterior y registrar hashes. En la demostración se compiló con el nombre
`MT5_Telemetry_Exporter_Supabase.ex5` para conservar el binario anterior.
Verificar errores, advertencias, existencia del binario y parámetros declarados.

La fuente actual no contiene funciones de trading, ni consulta comandos remotos.
`InpEnableKillSwitch` se conserva como parámetro de compatibilidad: debe ser
`false`; si se cambia a `true`, el EA rechaza su inicialización.

En MT5, **Herramientas → Opciones → Asesores Expertos → Permitir WebRequest para
las URL listadas**, añadir la URL HTTPS del proyecto propio y conservar las URL
existentes. Esto autoriza comunicación HTTP; no requiere activar trading ni DLL.
Si el MCP nativo no ofrece esa configuración, el alumno realiza ese paso en el panel.

Después, abrir Navegador (`Ctrl+N`), actualizar Asesores Expertos y cargar el EA
en el gráfico elegido. Cargar el `.set` desde Entradas, o usar los valores del
archivo privado `parameters.json`:

| Input | Valor |
|---|---|
| `InpSupabaseUrl` | `https://TU_PROJECT_REF.supabase.co`, sin `/functions/v1/...` |
| `InpSupabaseKey` | La credencial `mt5_...` generada, no una API key Supabase |
| `InpProjectName` | Exactamente el valor registrado al emitir la credencial |
| `InpBrokerAlias` | Vacío |
| `InpHeartbeatSeconds` | `30` |
| `InpEventDrivenSync`, `InpExportDeals`, `InpExportSwapRates` | `true` |
| `InpWatchSymbols` | Vacío inicialmente |
| `InpEnableKillSwitch` | `false` |
| `InpSaveLocalBackup`, `InpShowVisualPanel` | `true` |

El gráfico y las posiciones abiertas determinan los símbolos cuyo swap se exporta;
no se exporta automáticamente toda la Observación del Mercado. Adjuntar el EA
inicia la primera lectura y puede exportar histórico. Elegir una sola instancia
por cuenta evita trabajo y escrituras redundantes.

El agente puede usar `chart_add_expert` si está disponible y autorizado. Descubrir
su esquema y conservar los demás gráficos. Esta herramienta reemplaza el EA del
gráfico elegido. Sus inputs son una cadena estricta de pares separados por comas,
sin espacios: si un valor no se puede representar así, cargar el `.set` desde MT5
sin modificar la identidad para acomodarla al formato del conector.

## 5. Comprobar recepción real

1. Confirmar inputs efectivos del gráfico sin mostrar el token en la salida.
2. Buscar en el diario del EA `[TELEMETRY] ... HTTP 200` para cada recurso.
3. Ejecutar las [consultas de recepción y permisos](sql/verificar_receptor.sql)
   para consultar conteos y `max(received_at)` mediante Supabase.
4. Esperar otra lectura y comprobar que `received_at` avance sin duplicar la fila
   de la cuenta ni los mismos tickets. Conservar horas y resultados sanitizados.
5. Verificar rechazos HTTP `401` con credencial inválida y `403` con una identidad
   distinta. Esas pruebas no deben insertar filas.

Si la cuenta no tiene deals o posiciones, un conteo de cero puede ser correcto:
contrastarlo con MT5, sin crear operaciones para obtener datos de prueba.
El receptor limita cada petición a 512 KiB y 100 registros (un snapshot), y rechaza
campos desconocidos. Los tickets viajan como cadenas decimales para evitar pérdida
de precisión en JavaScript y se almacenan como números exactos en Postgres.

| Resultado | Interpretación |
|---|---|
| Error MT5 `4014` | Falta WebRequest permitido o ejecución en contexto no compatible; no hay evidencia de envío |
| HTTP `401` | Token inválido, desconocido, revocado o vencido |
| HTTP `403` | Cuenta, broker, servidor o etiqueta no coincide con la autorización |
| HTTP `400` | Formato, campos o recurso no admitido |
| HTTP `413` | Petición demasiado grande |
| HTTP `503` | Fallo temporal del servicio o configuración del servidor; revisar sin divulgar secretos |
| HTTP `200` y consulta con fila | Recepción comprobada; continuar verificando las siguientes lecturas |

El EA reintenta lotes históricos fallidos sin avanzar su cursor. No hay una cola
durable de todos los eventos: un evento de apertura fallido no tiene entrega
individual garantizada. El snapshot y el histórico permiten reconciliar parte de esa información.
v3.20 exportaba principalmente cierres; la fuente v3.40 incluye entradas y salidas,
pero un reenvío histórico no genera un aviso inmediato equivalente al evento. Este límite debe conservarse en la bitácora.

## 6. Revocar, rotar y recuperar

Ejecutar el `revoke.sql` privado en el proyecto correspondiente. La función consulta
el registro en cada solicitud: las siguientes peticiones serán rechazadas; una
petición ya autorizada y en curso podría finalizar. No hace falta redeploy para
revocar. Para rotar, emitir otro token, registrarlo, cargarlo en MT5, verificar
recepción y revocar el anterior. No usar la contraseña de la base como reemplazo.

Si la compilación o el despliegue falla, conservar fuente, logs sanitizados y
estado real. Retirar solo la instancia de prueba si es necesario; no reiniciar
MT5, restaurar credenciales antiguas ni activar cierre remoto como recuperación.

La hora de los deals sigue siendo la hora del broker etiquetada por la fuente
original; `received_at` sí es hora del servidor receptor. No usar aquella para
análisis intradiario UTC sin la normalización pendiente indicada en el
[contrato](CONTRATO_DATOS.md).

[Volver a Supabase](README.md).

## Receptor independiente de Telegram

`mt5-telegram` utiliza otra credencial y otra función, descritas en la
[guía Telegram](../integraciones/telegram/README.md). El token del bot no se coloca
en los inputs del EA. El bot escribe únicamente motivos humanos en la bitácora;
`mt5-telemetry` sigue recibiendo los datos originales. Ninguno incorpora órdenes
de compra, venta o cierre remoto.

Al activar las alertas, `mt5-telemetry` también utiliza el token del bot guardado en
Supabase para entregar avisos de apertura y cierre desde una cola durable. Esa tarea corre
en segundo plano y no cambia la credencial ni los inputs del EA. Aplicar antes el
SQL de alertas indicado en la guía Telegram; el receptor conserva la telemetría
aunque una notificación falle.

## Receptor de edición del dashboard

`mt5-dashboard-editor` es independiente del receptor de telemetría. Autentica
códigos de Telegram de un solo uso y sesiones de una hora. CORS admite únicamente
el origen configurado; cada operación privada requiere además una sesión válida
y un editor activo. No recibe órdenes de trading, credenciales del EA ni cambios
de precios o resultados. [Procedimiento completo](../aplicaciones/web/EDICION.md).
