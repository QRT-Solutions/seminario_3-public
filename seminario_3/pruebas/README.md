# Plan de pruebas del seminario 3

Autoría: QRT Solutions. Ejecutar desde la raíz del clon salvo donde se indique.

## Pruebas locales sin cuentas ni credenciales

Con Python 3.12, uv y Node.js 22.19+ compatible:

```sh
uv sync --locked
uv run --locked seminario verify
uv run --locked python .agents/skills/mt5-platform-operator/tests/run_offline.py
uv run --locked python seminario_3/pruebas/test_credencial.py
node --test seminario_3/supabase/functions/mt5-telemetry/core.test.mjs seminario_3/supabase/functions/mt5-telemetry/notifications.test.mjs seminario_3/supabase/functions/mt5-telegram/core.test.mjs seminario_3/supabase/functions/mt5-dashboard-editor/core.test.mjs
npm --prefix seminario_3/aplicaciones/web ci
npm --prefix seminario_3/aplicaciones/web test
uv run --locked python tools/check_links.py
uv run --locked mkdocs build --strict
```

La instalación de dependencias puede necesitar red; las pruebas no llaman a MT5,
no envían mensajes a Telegram ni escriben en Supabase. No hacen trading.
La suite de integraciones es explícita: `seminario verify` no la ejecuta por sí sola.

| Grupo | Qué comprueba | Resultado local de esta consolidación |
|---|---|---|
| Catálogo heredado | Esquemas, IDs, rutas y copias de estrategias | 17 estrategias, sin errores |
| Skill MT5 | Contratos y evidencia, casos válidos e inválidos | 63 comprobaciones aprobadas |
| Generador de credenciales | Archivos privados, hash, destino ignorado y no sobrescritura | 3 pruebas aprobadas |
| Funciones y avisos | Autenticación, alcance, límites, deduplicación, fases, códigos web y errores | 37 pruebas aprobadas |
| Dashboard | Métricas, filtros, nulos, comentarios y fases | 7 pruebas aprobadas |
| Documentación | Enlaces internos y construcción MkDocs | Sin fallos en la preparación final |

No interpretar los recuentos como certificación de MT5 conectado ni de todos los
sistemas operativos. Los datos controlados de tests no se publican como operaciones reales.

## Construcción web

Primero configura `.env.local` con **solo los dos valores públicos de tu proyecto**,
como explica la [guía web](../aplicaciones/web/README.md). Luego:

```sh
npm --prefix seminario_3/aplicaciones/web run build
```

El build falla sin configuración válida; esa protección es intencional.
Para comprobar solo la construcción sin proyecto propio puede usarse, en una copia
local de `.env.example`, una URL de ejemplo y clave con formato de ejemplo. Eso no
valida conectividad y no debe desplegarse como aplicación conectada.

## Comprobaciones en el proyecto del alumno

Sigue el [mapa de verificaciones SQL](../supabase/sql/README.md). Las consultas de
estructura y conteos son de lectura; la prueba del editor utiliza `ROLLBACK` y
requiere editor activo y una apertura existente. Ejecútala completa, nunca separando
las escrituras de su rollback. No uses datos de otro alumno.

| Tramo | Evidencia necesaria |
|---|---|
| Compilación del EA actual | Fuente/hash, versión, errores y advertencias, binario generado |
| MT5 → receptor | HTTP 200, identidad correcta y más de una recepción con hora creciente |
| Permisos | Credencial inválida rechazada; tablas/RPC privadas sin permisos cliente |
| Supabase → Vercel | Datos reales de la demo autorizada en la URL de producción |
| Telegram | Webhook definitivo, chat autorizado, aviso y motivo verdadero guardado |
| Editor web | Código real, edición autorizada, historial, lectura pública y cierre de sesión |
| Concurrencia | Un cambio previo impide sobrescritura silenciosa y conserva borrador |

Estas comprobaciones requieren autorización de la instalación y acciones del
propietario. El agente no abre/cierra operaciones para completar una lista.
La primera edición real del propietario seguía sin confirmación al consolidar
esta documentación; las pruebas SQL y de interfaz local sí se registraron.

## Antes de distribuir

```sh
uv run --locked python -m seminario_lab.publication
```

El escáner revisa archivos candidatos e historia Git y muestra rutas/reglas, no
el contenido que coincida. Es un control heurístico; no reemplaza revisión humana
ni un escáner general. Consulta [ENTREGA.md](../ENTREGA.md) para excluir configuración
local, revisar artefactos y preparar la publicación del repositorio correcto.

[Resultados de esta entrega](VERIFICACION.md) · [Estado y límites](../ESTADO.md) · [Bitácora](../supabase/BITACORA.md).

## Extensión de ajustes simples

Ejecutar [verificar_protecciones.sql](../supabase/sql/verificar_protecciones.sql)
completo: prueba identidad, agrupación, ausencia de duplicados, revisiones, acceso
ajeno, conflicto de versión y páginas con 30 ejecuciones sintéticas. Termina con
`ROLLBACK`; no envía mensajes ni coloca operaciones. Comprobar por separado un
cambio real hecho por el propietario cuando el nuevo exportador esté instalado.
