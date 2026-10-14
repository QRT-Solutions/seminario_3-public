---
name: mt5-platform-operator
description: Se activa cuando se requiere operar técnicamente la plataforma MetaTrader 5 de forma desatendida y reproducible EXCLUSIVAMENTE mediante sus servidores MCP nativos (verificación de capacidades descubiertas, preparación de perfiles de prueba, lanzamiento de backtests y optimizaciones bajo contrato, monitoreo de estado por run_id, extracción de reportes y telemetría de diarios). No formula hipótesis ni elige parámetros óptimos.
metadata:
  author: "QRT Solutions"
  version: "1.0.0"
  compatibility: "Cliente con un proveedor MCP nativo de MetaTrader 5 descubierto en la sesión; comprobar disponibilidad en cada cliente."
  role: "Technical Platform Operator"
  execution_boundary: "MCP Only"
  trading_permission: "false"
---

# MT5 Platform Operator (MCP Native)

> **Autor Institucional:** QRT Solutions  
> **Ámbito:** Operador técnico agnóstico y desatendido de MetaTrader 5 mediante MCP.  
> **Principio Rector:** El operador ejecuta la mecánica de plataforma bajo un contrato formal y devuelve evidencia cruda verificable; **NUNCA** formula hipótesis, no selecciona parámetros óptimos ni inventa desgloses de métricas.

## Integración local en Seminario 3

La documentación seleccionada está en [MT5/knowledge/INDEX.md](../../../MT5/knowledge/INDEX.md).
La [guía de conexión del proyecto](../../../seminario_3/integraciones/metatrader/README.md)
describe los conectores nativos y los límites de esta migración. La configuración
con credenciales es local y no se distribuye con la skill. Descubrir herramientas
en la sesión actual antes de operar; las tablas heredadas son referencias históricas.
Instalar esta skill no autoriza estudios, trading ni mutaciones de la plataforma.

---

## 1. Separación Estricta de Roles

```
┌────────────────────────────────────────────────────────────────────────┐
│                   ROL QUANT (SUPERVISOR / EXTERNO)                     │
│ • Formula la hipótesis causal y el modelo matemático.                  │
│ • Define el espacio de búsqueda paramétrico y filtros de régimen.     │
│ • Evalúa la robustez estadística y emite el veredicto del estudio.    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Contrato de Tarea (JSON Estricto)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│               ROL OPERADOR DE PLATAFORMA (ESTA SKILL)                  │
│ • Inicializa sesión con el proveedor MCP (`get_workspace_info`).       │
│ • Valida pre-condiciones de la tarea según la operación solicitada.    │
│ • Resuelve rutas absolutas en `\MQL5\Profiles\Tester`.                 │
│ • Prepara perfil técnico (`.ini`) y dispara la corrida en el tester.   │
│ • Monitorea por `run_id` y extrae telemetría (JSON/XML, diarios).      │
│ • Gestiona gráficos limitándose a ventanas de tarea sin trading.       │
│ • Entrega evidencia cruda; no interpreta ni opina sobre causalidad.    │
└────────────────────────────────────────────────────────────────────────┘
```

> [!IMPORTANT]
> **Herramienta disponible no implica autorizada:** La presencia de herramientas de trading (`trade_send_market_order`, etc.) en el catálogo MCP no concede autorización para operar en cuentas vivas. Toda mutación fuera del Strategy Tester o en gráficos requiere autorización explícita (`gates.mutation_approval: true`), sin abrir trading en vivo.

---

## 2. Contrato de Ejecución por Tarea (Discriminado por Operación)

El operador valida toda tarea contra el esquema formal [`assets/task_execution_contract.schema.json`](assets/task_execution_contract.schema.json). Las 10 operaciones del contrato (disponibilidad sujeta al catálogo vivo) cuentan con requisitos estrictos:

1. **`capabilities`**: Consulta de herramientas disponibles y rutas del workspace.
2. **`query_status`**: Exige `run_id` no vacío.
3. **`inspect_symbol`**: Exige `symbol` no vacío.
4. **`history`**: Exige símbolo, período e intervalo temporal (`target` o campos directos).
5. **`chart`**: Exige `chart_action`. Si involucra mutación (`open`, `close`, `apply_template`, `add_indicator`), exige autorización expresa (`gates.mutation_approval: true`).
6. **`compile`**: Exige `source_path`, `output_path` y `gates.mutation_approval: true`.  
   *(Descubrir un proveedor MCP con compilación y su esquema. Si no existe, responder `unsupported`. Si existe, leer fuente, fijar hash y destino nuevo, compilar sin editar lógica, verificar errores/advertencias y binario; no desplegar a gráficos ni reiniciar el terminal.)*
7. **`backtest`**: Exige configuración completa, `gates.study_approval = true` y `gates.quality_gate` explícito.
8. **`optimization`**: Exige configuración completa, `gates.study_approval = true`, `gates.quality_gate` explícito y soporta rangos fijados por el rol Quant (`optimization_ranges`).
9. **`cancel_run`**: Exige `run_id` no vacío y `gates.mutation_approval: true`.
10. **`extract_report`**: Exige `run_id` no vacío y `expected_output`.

### Ejemplo mínimo: consulta de capacidades
```json
{"task_id":"TASK-CAPABILITIES-EXAMPLE","operation":"capabilities"}
```
Los contratos de tester se construyen con las decisiones explícitas del estudio. Los valores en las fixtures de tests son sintéticos, nunca recomendaciones ni valores predeterminados.

* Si una solicitud pide "elegir el mejor stop loss" o "proponer una hipótesis", el operador **RECHAZA** la tarea por violación de límites y delega al Rol Quant.

---

## 3. Protocolo de Operación en 5 Fases

```
[FASE 0: DESCUBRIMIENTO] ──> [FASE 1: CONTRATO] ──> [FASE 2: LANZAMIENTO] ──> [FASE 3: RECUPERACIÓN] ──> [FASE 4: EVIDENCIA]
  get_workspace_info          Validación Schema       tester_prepare_config    Rastreo por run_id       tester_get_report
  get_time_information        Deduplicación Hash      tester_run_*             Suspensión de mutación   Validación de firma XML
```

### Fase 0: Descubrimiento de Capacidades y Entorno
1. Descubrir primero el catálogo vivo; validar el esquema y consultar el entorno mediante `terminal:get_workspace_info`.
2. Registrar los `read_roots` y `write_roots` permitidos dinámicamente.
3. Consultar `terminal:get_time_information` para registrar la hora local del terminal y el offset UTC aplicable a los filtros del diario.
4. Normalizar `knowledge_root` verificando la presencia física de `INDEX.md`.

### Fase 1: Validación y Deduplicación Exhaustiva
Antes de mutar, aplicar [preflight semántico](references/preflight_semantico.md). El esquema valida estructura, no demuestra permisos, existencia de archivos ni validez de un estudio.
1. Validar el contrato contra su esquema JSON según la operación.
2. Comprobar si `task_id` ya existe en disco con payload diferente; si ocurre, **abortar por conflicto**.
3. Calcular la huella digital canónica completa de la tarea (claves ordenadas, hashes de binarios y parámetros, revisión de datos verificable, sin rutas personales).
4. Si existe un resultado previo indexado con la misma huella y `force_reexecution` es falso, emitir evidencia con `status: "reused"` y `reused_cached_result: true`.

### Fase 2: Configuración y Lanzamiento
1. Si la operación es `backtest` u `optimization`:
   * Persistir intención en checkpoint atómico en disco (`checkpoint_<task_id>.json` con `status: "pending_launch"`).
   * Resolver rutas absolutas obligatorias bajo `\MQL5\Profiles\Tester` concatenando `mql5_folder`.
   * Preparar la configuración mediante `terminal:tester_prepare_config` y plasmar directivas no soportadas (`currency`, `execution_delay`) en el `.ini`.
   * Invocar `terminal:tester_run_backtest` o `terminal:tester_run_optimization`.
   * Capturar inmediatamente el `run_id` y actualizar el checkpoint a `status: "running"`.
2. **Mandato de Backtesting Conjunto Multi-Activo (`Optimization=3`):**  
   Cuando la tarea cuantitativa requiera evaluar una misma estrategia sobre múltiples instrumentos, el operador **NUNCA** ejecutará bucles secuenciales lentos símbolo por símbolo. Debe poblar la Observación del Mercado (*Market Watch*), generar el perfil con `Optimization=3` (*"Todos los símbolos seleccionados en Observación del Mercado"*) y lanzar la corrida conjunta mediante `tester_run_optimization`, aprovechando la concurrencia nativa multi-núcleo de MT5.

### Fase 3: Manejo de Estado Incierto y Recuperación
* Si ocurre un timeout o error de transporte tras disparar el test:
  1. **NO reintentar a ciegas** para evitar saturar agentes de cómputo.
  2. El comando `terminal:tester_get_status` **requiere `run_id`**, por lo que no puede usarse si no se recibió el identificador.
  3. Consultar `terminal:get_tester_journal` en la ventana temporal reciente (en hora local del terminal) para verificar si el terminal registró el inicio de la prueba.
  4. Si no puede identificarse la corrida de forma unívoca, **suspender únicamente esa mutación** emitiendo `status: "uncertain"` y solicitar verificación de estado al supervisor.

### Fase 4: Extracción de Telemetría y Cierre
Estas fases de lanzamiento y reporte solo aplican al tester; las consultas retornan su payload y las otras operaciones su evidencia específica.

1. Extraer el reporte mediante `terminal:tester_get_report`.
2. **Validación de formato:** Detectar el contenido y firma real del archivo generado; no asumir ciegamente que el reporte XML incluye inputs o es SpreadsheetML estándar sin contrastar la configuración efectiva con el diario o `tester_get_configuration`.
3. Emitir el paquete estructurado según [`assets/execution_evidence.schema.json`](assets/execution_evidence.schema.json).
4. Actualizar el checkpoint atómico a `status: "completed"`.

---

## 4. Revelación Progresiva (Progressive Disclosure)

Para especificaciones detalladas de herramientas y firmas verificadas, consulta los módulos en `references/`:

* **[Módulo 1: Conexión y Descubrimiento de Capacidades](references/modulo1_conexion_capacidades.md)**: Inicialización, permisos dinámicos y sincronización temporal.
* **[Módulo 2: Símbolos, Especificaciones y Cobertura](references/modulo2_simbolos_datos.md)**: Sincronización por lote de Market Watch, desbloqueo por Chart-Lock, símbolos personalizados, firmas exactas de barras/ticks y descubrimiento de sesiones.
* **[Módulo 3: Gráficos, Indicadores y Plantillas](references/modulo3_graficos_indicadores.md)**: Manejo seguro de gráficos de tarea, templates sin trading y no asunción de indicadores por defecto.
* **[Módulo 4: Strategy Tester y Ejecución de Contratos](references/modulo4_tester_contrato_ejecucion.md)**: Backtesting multi-activo nativo (`Optimization=3`), rutas absolutas, parámetros verificados de `tester_prepare_config`, mapeo de currency/delay y `tester_stop`.
* **[Módulo 5: Reportes, Diarios y Huellas](references/modulo5_reportes_telemetria_id.md)**: Estructura de pasadas de optimización, formatos JSON/XML, detección de firmas, contrastes independientes y telemetría de agentes sin datos hardcodeados.
* **[Módulo 6: Fallos, Recuperación e Idempotencia](references/modulo6_fallos_recuperacion_idempotencia.md)**: Checkpoint atómico externo, recuperación entre sesiones, conflicto de payload y deduplicación por huella canónica.
* **[Módulo 7: Matriz de Catálogo MCP](references/modulo7_mcp_catalog_matrix.md)**: Clasificación de herramientas en Documentado en caché de esquemas vs Disponible por sesión viva vs Unsupported.
* **[Módulo 8: Adaptador e Índice de Conocimiento Local](references/modulo8_knowledge_adapter.md)**: Normalización estricta por `INDEX.md`, mapeo temático canónico y frontera MCP sin fallbacks CLI/Python.
* **[Módulo 9: Protocolo de Calidad Histórica y Símbolos Personalizados](references/modulo9_protocolo_calidad_historica.md)**: Estándar matemático de desfase Bar Close/Bar Open (-1m), calibración de sesiones RTH, canal desatendido de indicadores e inyección masiva con calidad del 99%.

## Validación de esta versión

Skill creada y auditada offline. Ver [matriz de aceptación](tests/offline_acceptance_matrix.md). Ni la recuperación del agente ni su ejecución conectada están certificadas por estos tests.
