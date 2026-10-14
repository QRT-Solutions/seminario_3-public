# Conexión con MetaTrader 5

Autoría: QRT Solutions.

La integración utiliza los servidores HTTP nativos de MetaTrader 5. La migración
selectiva incorpora instrucciones y referencias técnicas; no instala otro servidor
ni reemplaza el contenido MT5 ya incluido en el repositorio.

## Componentes disponibles

| Componente | Ubicación y propósito |
|---|---|
| Skill de operación | [mt5-platform-operator](../../../.agents/skills/mt5-platform-operator/SKILL.md): contratos, esquemas, nueve módulos, preflight semántico y pruebas offline. |
| Conocimiento técnico | [Índice MT5](../../../MT5/knowledge/INDEX.md): cuatro manuales sobre arquitectura, tester, gráficos y datos. |
| Terminal MCP | `http://127.0.0.1:22346/mcp`: herramientas y permisos sujetos al catálogo descubierto en cada sesión. |
| MetaEditor MCP | `http://127.0.0.1:22345/mcp`: conexión independiente, requiere su servicio en ejecución. |

Las configuraciones `.codex/config.toml` y `.mcp.json` son archivos locales,
excluidos de Git. No se copian desde el repositorio anterior ni se distribuyen
credenciales. Un clon nuevo requiere configurar los conectores y autenticar cada
servidor con sus propias credenciales. `127.0.0.1` identifica el equipo del cliente;
estos archivos no instalan MT5, Wine ni MetaEditor en otro equipo.

Codex puede descubrir la skill en `.agents/skills/`; la disponibilidad en una
sesión nueva y en otros clientes debe comprobarse. No se presupone que Cursor,
Claude Code y Antigravity compartan rutas o formatos de configuración.

## Verificación

Desde la raíz del repositorio, el entorno Python 3.12 existente incluye
`jsonschema`, requerido por las pruebas de contratos:

```sh
uv sync --locked
uv run --locked python .agents/skills/mt5-platform-operator/tests/run_offline.py
```

Estas pruebas validan esquemas y ejemplos sintéticos; no llaman a MT5, no lanzan
backtests y no certifican recuperación del agente ni ejecución conectada.
El resultado histórico `offline_results.txt` del origen no se importa.

Para verificar una conexión, iniciar el protocolo MCP, consultar `tools/list`
y revisar el esquema antes de llamar a `get_workspace_info`. Es una consulta de
metadatos; la disponibilidad del compilador declarada por el servidor no equivale
a una compilación probada. No usar trading, tester ni despliegue como smoke test.

## Selección de la migración

Se omiten el servidor stdio y los bridges antiguos: duplican el acceso nativo,
contienen problemas de arranque, credenciales incrustadas o herramientas de
terminación de procesos que no son necesarias para esta integración.
Tampoco se importan perfiles de estudios, binarios, históricos, el manual de
conexión antiguo con secretos ni otro `MT5/AGENTS.md` con instrucciones ajenas
al alcance actual. Se conservan el inyector y el manual de auditoría existentes.

La instalación de la skill no concede permiso para iniciar estudios, cambiar
cuentas, activar AutoTrading, operar, desplegar EAs ni descargar históricos.
Las autorizaciones de cada tarea siguen siendo necesarias.

Las estrategias y scripts existentes permanecen en `MT5/` y en el
[catálogo canónico](../../../docs/strategies.md). No se copian aquí.
Solo se distribuyen instrucciones y referencias sin credenciales personales.

## Telemetría hacia Supabase

La [guía Supabase](../../supabase/README.md) documenta la creación del proyecto,
tablas, permisos y parámetros del exportador. La fuente actual v3.40 está en
[MT5_Telemetry_Exporter_Universal.mq5](../../../MT5/MT5_Telemetry_Exporter_Universal.mq5).
La versión v3.40 se compiló por MCP nativo con 0 errores y 0 advertencias y
binario verificado. La versión v3.40 está activa en el entorno docente, con
snapshot reciente recibido e historial HTTP 200. La prueba de un cambio real
de SL/TP y su motivo por Telegram sigue pendiente.
Consulta [instalación y pruebas del receptor](../../supabase/RECEPTOR.md) para
repetirlo en otro equipo. El EA no contiene funciones de trading ni cierre remoto.

[Volver al seminario 3](../../README.md).

## Ejemplos de configuración local, sin credenciales del docente

Autoría de los ejemplos: QRT Solutions. Sustituye `<TOKEN_LOCAL>` por la credencial
que entregue tu instalación, únicamente en el archivo local ignorado por Git.
Conserva los demás conectores. Estos ejemplos describen el formato usado en este
recorrido; el agente debe verificar el soporte de su versión y cliente.

Para un cliente que acepte `.mcp.json` con servidores HTTP:

```json
{
  "mcpServers": {
    "metaeditor": {
      "type": "http",
      "url": "http://127.0.0.1:22345/mcp",
      "headers": {"Authorization": "Bearer <TOKEN_LOCAL>"}
    },
    "terminal": {
      "type": "http",
      "url": "http://127.0.0.1:22346/mcp",
      "headers": {"Authorization": "Bearer <TOKEN_LOCAL>"}
    }
  }
}
```

Para la configuración de proyecto Codex `.codex/config.toml` utilizada en este recorrido:

```toml
# Author: QRT Solutions. Local configuration, never commit populated credentials.
[mcp_servers.metaeditor]
url = "http://127.0.0.1:22345/mcp"
enabled = true
http_headers = { "Authorization" = "Bearer <TOKEN_LOCAL>" }

[mcp_servers.terminal]
url = "http://127.0.0.1:22346/mcp"
enabled = true
http_headers = { "Authorization" = "Bearer <TOKEN_LOCAL>" }
```

Antigravity u otro IDE puede utilizar otro archivo o mecanismo. No copiar estos
bloques a una ruta no verificada ni asumir que las cabeceras son compartidas entre
ambos servicios. La autenticación Supabase y el token del bot Telegram son credenciales
distintas. No usar ninguno de ellos como token del MCP local.
