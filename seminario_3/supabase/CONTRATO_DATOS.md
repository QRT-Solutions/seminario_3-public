# Contrato de telemetría y parámetros del EA

Autoría: QRT Solutions.

La fuente distribuida es **v3.40**, que conserva los inputs de v3.20 y añade
comentarios nativos e historial de entradas/salidas. v3.40 está compilada por MCP
nativo, con 0 errores y 0 advertencias y binario verificado. Su activación,
recepción reciente de snapshots y envío del historial con HTTP 200 están
verificados; falta probar un cambio real de SL/TP con su motivo por Telegram. Contrastar siempre inputs y JSON con la fuente compilada. El receptor añade `received_at`
con su hora UTC al guardar cada registro.

| Tabla | Registro | Clave de actualización |
|---|---|---|
| `mt5_accounts_snapshot` | Último estado de una cuenta | `account_id` |
| `mt5_deals` | Ejecución o movimiento reportado por MT5 | `deal_ticket` |
| `mt5_swap_rates` | Últimas tasas por broker y símbolo | `broker,symbol` |

Actualizar por clave evita duplicar una fila al reenviarla. La tabla de estado
sobrescribe la lectura anterior: **no conserva una curva histórica de equity**.
Una operación puede tener varios deals; contarlos no equivale necesariamente a
contar operaciones completas.

El [esquema SQL](sql/esquema_telemetria.sql) enumera todas las columnas. Importes
en `numeric`, tickets en `numeric(20,0)` y posiciones en una matriz `jsonb`
preservan los números recibidos y evitan tratar las posiciones como texto.

| Grupo | Campos principales |
|---|---|
| Identidad | `account_id`, `login`, `broker`, `server`, `currency`, `project_name` |
| Estado | Balance, equity, márgenes, beneficio flotante y posiciones abiertas |
| Acumulados | Beneficios cerrados y del día; contadores de deals y posiciones |
| Deals | Tickets, símbolo, dirección, entrada/salida, volumen, precio, beneficio, comisión, swap y hora |
| Swaps | Tasas long/short, modo de cálculo, día de multiplicación y actualización |

`approval_status` es un dato original del EA: `PENDING` en el evento inmediato y
`APPROVED` al exportar histórico. No demuestra aprobación humana ni autoriza
operar; el reenvío histórico puede sobrescribirlo.

## Parámetros compartidos por v3.20 y v3.40

Obtener los valores propios mediante el procedimiento de [RECEPTOR.md](RECEPTOR.md).
La misma guía describe el registro del hash y el archivo local de inputs.

| Parámetro | Valor o acción | Propósito |
|---|---|---|
| `InpSupabaseUrl` | URL raíz del proyecto propio, sin ruta de función | Destino |
| `InpSupabaseKey` | Credencial exclusiva `mt5_...` registrada | Autorización |
| `InpProjectName` | Etiqueta propia, como `seminario-3-alumno` | Identificar; no crea proyectos ni concede permisos |
| `InpBrokerAlias` | Vacío inicialmente | Identificación automática |
| `InpHeartbeatSeconds` | `30` | Intervalo nominal |
| `InpEventDrivenSync` | `true` | Envíos adicionales por evento |
| `InpExportDeals` | `true`, tras autorizar exportación de histórico | Enviar deals |
| `InpExportSwapRates` | `true` | Enviar tasas de símbolos observados |
| `InpWatchSymbols` | Vacío inicialmente | No añadir símbolos extra |
| `InpEnableKillSwitch` | `false` | Cierre remoto desactivado |
| `InpSaveLocalBackup` | `true` | Respaldo local, con posibles datos privados |
| `InpShowVisualPanel` | `true` | Mostrar estado en el gráfico |

El exportador envía la credencial exclusivamente en `x-mt5-token` al receptor. No utiliza
una API key de Supabase en el EA. El JSON incluye `resource`, `account` (login,
broker y servidor) y `records`. Tickets y login viajan como cadenas decimales;
Postgres almacena los identificadores como números exactos. El receptor acepta
solo campos del contrato y agrega su propia hora de recepción.

La tabla administrativa `mt5_ingest_credentials` conserva únicamente el hash y
el alcance de cada credencial. No es una cuarta clase de telemetría ni se expone
al EA. Las tablas de datos siguen sin acceso directo de clientes.

## Límites conocidos

- Una cuenta por ahora. `deal_ticket` puede colisionar entre brokers o servidores;
  revisar claves y `on_conflict` antes de ampliar a varias cuentas.
- `account_id` combina login y broker, sin servidor. El receptor debe validar
  la cuenta autorizada, sin confiar solo en el texto enviado o `InpProjectName`.
- El EA añade `Z` a la hora del broker sin convertirla a UTC. `timestamptz` no
  corrige ese error de origen. Normalizar antes de analizar horas, considerando
  también cambios históricos de horario.
- La fuente v3.40 formatea precios y volumen con ocho decimales; las fuentes previas podían transmitir menos precisión; la base no
  recupera precisión descartada antes del envío.
- Se verificaron reenvíos de snapshots sin duplicados. En la fuente actual, los lotes históricos
  fallidos no avanzan el cursor y se reintentan; no existe una cola durable que
  garantice todos los eventos individuales de apertura durante una desconexión.
- Activar el exportador puede transmitir operaciones anteriores. No describirlo
  como envío exclusivo de eventos futuros.

No existe tabla de comandos remotos y la fuente actual no contiene funciones de compra,
venta ni cierre. Si `InpEnableKillSwitch=true`, se rechaza la inicialización.

[Volver a Supabase](README.md).

## Agregados públicos de los diez KPI

`mt5_public_dashboard_kpis(p_symbol, p_direction, p_from, p_to)` devuelve solo
agregados de la demo ya habilitada: `version=1`, `generated_at`, `time_basis=broker`,
`count`, `excluded`, `unlinked_deals`, `net`, `cumulative_return_pct`,
`win_rate_pct`, `profit_factor_pct`, `profit_factor_money`, `payoff_pct` y
`expectancy_pct`. No devuelve identidad ni tickets. No modifica la publicación.

Los campos con sufijo `_pct` de retorno/acierto/esperanza se expresan en puntos
porcentuales (1 representa 1%). `profit_factor_pct` y `payoff_pct` son cocientes,
no porcentajes; el sufijo identifica su base de cálculo. Los filtros usan fecha
de cierre y dirección original. Se reconstruye cada posición antes de filtrar;
las aperturas anteriores al período cuentan. `unlinked_deals` corresponde a todo
el histórico recibido de la cuenta y no al filtro seleccionado.

Solo se incluyen secuencias observadas de apertura y cierre completo, con volumen
balanceado, precios válidos y sin INOUT ni aumentos tras una reducción. Los
parciales se ponderan por volumen. `excluded` cuenta candidatos con cierres en el
filtro que no cumplen esos requisitos. Una muestra vacía y ratios sin denominador
devuelven `null`. El neto contempla costes recibidos, sin inventar cargos no
exportados. Equity histórica y valoración monetaria hasta SL siguen fuera del
contrato de telemetría actual. Ver [guía web](../aplicaciones/web/README.md).

La extensión `dashboard_distribuciones.sql` añade `charts` sin cambiar los campos
anteriores ni la versión de la RPC. `charts.version=1` y `curve_limit=400` describen
el formato gráfico. `histogram_return` y `histogram_net` contienen `lower`, `upper`
y `count` para hasta doce intervalos iguales de la muestra completa; una muestra
constante contiene un único intervalo. Una muestra vacía devuelve matrices vacías.

`curve` contiene `trade_from`, `trade_to`, `closed_from`, `closed_to`,
`cumulative_return_pct`, `cumulative_long_pct`, `cumulative_short_pct` y
`cumulative_net`. Los números de trade son ordinales dentro del filtro, no tickets.
Las fechas son cadenas de hora broker sin sufijo UTC. Para más de 400 cierres se
agrupan bloques de tamaño `ceil(n/400)`, preservando acumulados finales y rangos.
No se exportan identificadores de cuenta/posición ni se guarda equity histórica.

## Extensión de bitácora y Telegram (8 de octubre de 2026)

El receptor admite `deal_comment`, `order_comment`, `deal_reason` y `magic` como
grupo opcional completo; los payloads antiguos siguen siendo válidos. Los textos
nativos se conservan literalmente y no se interpretan como motivos humanos.
La fuente v3.40 está preparada para exportarlos; su instalación y recepción deben
comprobarse independientemente del despliegue del bot.

`mt5_trade_journal` guarda un motivo de apertura y otro de cierre por posición.
`mt5_trade_reason_audit` conserva los mensajes procesados, actor y fase; los reintentos
del mismo `update_id` no repiten la escritura. `mt5_telegram_editors` vincula un usuario
y chat privado a la cuenta; `mt5_telegram_pairing` conserva hashes de códigos de
un solo uso y vencimiento. Ninguna de esas tablas se expone directamente al público.

La [guía Telegram](../integraciones/telegram/README.md) define comandos, vinculación,
revocación y límites: un bot por proyecto, una cuenta por chat, texto de 1 a 1000
caracteres y validación de que la fase del trade exista en Supabase. Los motivos
pueden publicarse mediante la consulta limitada de la demo si está habilitada.
Las notas de una posición con cierres parciales se comparten entre esos cierres.

La extensión [telegram_alertas_cierre.sql](sql/telegram_alertas_cierre.sql) amplía
la cola a las fases `opening` y `closing`. El mensaje original conserva la fase;
la respuesta del usuario se registra en el motivo correspondiente. Los cierres
`OUT`/`OUT_BY` y las reversiones `INOUT` se distinguen de las nuevas entradas.
La unicidad por posición, usuario y fase evita duplicar solicitudes al reenviar datos.

## Editor de motivos desde Vercel

La migración `dashboard_reason_editor` añade `mt5_dashboard_web_config`,
`mt5_dashboard_login_codes`, `mt5_dashboard_sessions` y `mt5_web_reason_audit`.
RLS está habilitado y los clientes públicos no tienen privilegios directos.
`mt5_issue_dashboard_code` y `mt5_dashboard_editor` solo permiten ejecución a
`service_role`, usado internamente por las funciones Edge.

Los códigos se vinculan a cuenta, usuario y chat; vencen en cinco minutos y se
consumen atómicamente. Las sesiones duran una hora, guardan solo el hash y vuelven
a comprobar `mt5_telegram_editors.active` en cada petición. `save` acepta únicamente
`journal_id`, `phase`, `reason`, `expected_updated_at` y `request_id`; la cuenta y el
actor se derivan de la sesión. Conserva el valor anterior y registra el nuevo en
una misma transacción. Los comentarios nativos y los datos de ejecución no cambian.

La consulta privada del editor combina las últimas 50 entradas de auditoría web y
solicitudes históricas de Telegram sin revelar identificadores de usuario al
navegador. La consulta pública existente muestra los motivos vigentes. Véase la
[guía de implementación](../aplicaciones/web/EDICION.md).

## Cambios observados de protección (v3.40)

El snapshot admite `position_id` como cadena decimal exacta en cada posición,
además del ticket. Es opcional para compatibilidad; sin él no se generan eventos
SL/TP. El EA emite snapshot al recibir `TRADE_TRANSACTION_POSITION` y usa reloj
UTC para el latido, incluso cuando no hay nuevos ticks. No añade inputs.

La base compara snapshots con hora creciente. La primera observación establece
la referencia; no genera un cambio ni solicita una explicación. Un reenvío igual
o anterior no sustituye esa referencia. La resolución temporal es de un segundo:
ajustes intermedios más rápidos o durante una desconexión pueden no observarse.
El nivel final se compara en la siguiente recepción válida.

- `mt5_protection_events`: anterior/nuevo SL/TP y hora observada de cada diferencia.
- `mt5_protection_groups`: un grupo por posición y minuto de recepción, primer y
  último nivel, cantidad de cambios y motivo humano.
- `mt5_protection_audit`: revisiones web/Telegram, actor, anterior y nuevo motivo.

Los avisos quedan disponibles al terminar ese minuto; se entregan en una recepción
posterior de telemetría. Un grupo ya completado no genera un aviso pendiente.
No se detecta si un cambio lo causó un trailing, un EA o una persona: la agrupación
se aplica a todos, sin inventar autoría. Las razones se publican junto a la demo
si su propietario habilitó el dashboard; la auditoría y actores siguen privados.
