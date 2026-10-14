# Módulo 6: Fallos, Recuperación e Idempotencia

> **Autor Institucional:** QRT Solutions  
> **Ámbito:** Checkpoint atómico externo, recuperación entre sesiones, deduplicación por huella canónica y prevención de colisiones.

---

## 1. Checkpoint Externo Atómico Obligatorio

Para garantizar la recuperación desatendida ante caídas de red, reinicios de sesión del agente o interrupciones del entorno, el operador mantiene un **archivo de checkpoint externo atómico en disco** (`checkpoint_<task_id>.json`):

```
[CONTRATO VALIDADO]
        │
        ▼
[1. PERSISTIR INTENCIÓN] ──> Escribe checkpoint_<TASK_ID>.json (Status: "pending_launch", timestamp_utc)
        │
        ▼
[2. DISPARAR RUNNER] ────> Invocación de terminal:tester_run_*
        │
        ▼
[3. CAPTURAR RUN_ID] ────> Actualización atómica en disco: status: "running", run_id: "<RUN_ID>", timestamp_utc
        │
        ▼
[4. FINALIZACIÓN]    ────> Actualización atómica: status: "completed", artifacts, report_path
```

### Protocolo de Recuperación en Sesión Nueva:
Al iniciar una sesión o tras una interrupción:
1. El operador escanea el directorio de checkpoints persistidos en disco.
2. Si detecta un checkpoint con estado `pending_launch` o `running`:
   * **No asume terminación ni dispara una nueva corrida en el tester.**
   * Si el `run_id` ya fue capturado en el checkpoint, invoca `terminal:tester_get_status(run_id)`.
   * Si el `run_id` no llegó a persistirse (la interrupción ocurrió durante la llamada a `tester_run_*`):
     - El operador consulta `terminal:get_tester_journal` en la ventana temporal local del terminal calculada desde `timestamp_utc`.
     - **Limitación Mandatoria:** Los diarios del tester están indexados en **hora local del terminal** y **NO garantizan registrar explícitamente el `run_id`**.
     - Si la inspección de diarios no permite identificar de forma unívoca e indubitable la corrida, el operador emite evidencia con `status: "uncertain"`, `blocking_reason: "unreconciled_pending_checkpoint_without_run_id"` y suspende cualquier mutación adicional.

---

## 2. Prevención de Conflictos de Identidad de Tarea

> [!CAUTION]
> **Conflicto Mandatorio por Reutilización de `task_id` con Payload Distinto:**  
> Si se recibe una tarea cuyo `task_id` ya existe en el registro histórico de checkpoints pero su configuración, target o parámetros difieren del registro previo:  
> El operador **ABORTA INMEDIATAMENTE** la ejecución devolviendo:  
> `status: "blocked"`  
> `blocking_reason: "task_id_conflict_different_payload"`  
> Se exige al rol emisor proporcionar un `task_id` único y no reutilizar identificadores para especificaciones divergentes.

---

## 3. Deduplicación por Huella Canónica Completa

Para autorizar la reutilización de un resultado previo (`status: "reused"`, `reused_cached_result: true`), la huella se calcula como el hash SHA-256 de un JSON canónico (con claves ordenadas lexicográficamente) que integra:

1. **Configuración Efectiva Completa:** Símbolo, período, fechas extremas, modelo de tick, depósito, divisa, apalancamiento, delay y criterios/rangos de optimización.
2. **Integridad de Artefactos de Código:** Hash SHA-256 del ejecutable `.ex5` y hash SHA-256 del archivo `.set` de parámetros.
3. **Identidad y Revisión de Datos Históricos:** Identificador de revisión o hash del historial/ticks utilizados.  
   > [!IMPORTANT]
   > **Condición de Datos:** Si la identidad o revisión de los datos históricos **no es verificable**, el operador **NO certifica la reutilización** bajo ninguna circunstancia. En tal caso, rechaza el cacheo y reporta la limitación técnica.
4. **Propiedades Relevantes de Plataforma:** Build del terminal y proveedor MCP descubierto.  
   > [!WARNING]
   > Queda **estrictamente prohibido** incluir rutas personales del sistema de archivos, nombres de usuario de host o credenciales dentro de la huella canónica, garantizando portabilidad y privacidad.

---

## 4. Cancelación Controlada de Corridas (`tester_stop`)

Cuando se recibe una instrucción formal de cancelación (`operation: "cancel_run"`):
1. Verificar que el contrato cuenta con autorización explícita de mutación: `gates.mutation_approval = true`.
2. Validar que se suministra el `run_id` correspondiente a la tarea activa.
3. Invocar `terminal:tester_stop(run_id)`.
4. Actualizar atómicamente el checkpoint en disco a `status: "canceled_by_user"`.
5. Emitir evidencia de cierre con `status: "blocked"` y `blocking_reason: "canceled_by_authorized_instruction"`.
