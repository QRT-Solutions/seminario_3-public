# Módulo 4: Strategy Tester y Ejecución de Contratos

> **Autor Institucional:** QRT Solutions  
> **Ámbito:** Preparación técnica de configuraciones, modelos de simulación, ejecución del tester y control de ciclo de vida por `run_id`.

---

## 1. Puertas de Autorización Externa (Gates Obligatorios)

Antes de invocar cualquier herramienta que consuma ciclos de CPU en el Strategy Tester:
1. **`study_approval: true` Obligatorio:** El contrato de tarea debe incluir `gates.study_approval = true`. **Sin aprobación explícita del estudio, el operador NO inicia el lanzamiento.**
2. **`quality_gate` Explícito:** Debe contener `min_quality_pct` y la política ante calidades no interpretables (`reject_uninterpretable`).
3. **`allow_oos` Controlado:** Si el rango temporal incluye períodos reservados como Out-of-Sample, la tarea debe contener autorización explícita; de lo contrario, se suspende.
4. **Cancelación Autorizada (`tester_stop`):** Si se requiere cancelar una simulación activa previamente identificada, el contrato debe contar con `gates.mutation_approval = true` y suministrar el `run_id`.

---

## 2. Preparación de Configuración (`tester_prepare_config`)

*Esquema Documentado:* `tester_prepare_config.json`
```jsonc
// Herramienta: terminal:tester_prepare_config
{
  "expert_path": "Experts\\ExpertPlaceholder.ex5",
  "output_path": "<MQL5_FOLDER_ABSOLUTE>\\Profiles\\Tester\\config_generated.ini",
  "symbol": "SYMBOL_PLACEHOLDER",
  "timeframe": "M15",
  "model": "m1 ohlc",
  "from_date": "2020-01-01T00:00:00Z",
  "to_date": "2020-12-31T23:59:59Z",
  "deposit": 10000.0,
  "leverage": 20,
  "optimization": false,
  "optimization_criterion": "sharpe_ratio_max"
}
```

> [!CAUTION]
> **Parámetros no aceptados por `tester_prepare_config`:**  
> El esquema de `tester_prepare_config` **NO acepta** los parámetros `currency` ni `execution_delay`.  
> *Regla Mandatoria:*  
> 1. Jamás pasarlos a `tester_prepare_config` (provocaría error de validación de esquema en la llamada MCP).  
> 2. Jamás ignorarlos silenciosamente.  
> 3. *Mapeo Técnico:* Estos parámetros pertenecen a la directiva del archivo `.ini` (sección `[Tester]`, campos `Currency=<DIVISA>` y `ExecutionMode=<DELAY_MS>`). Si el contrato los exige, el operador debe mapearlos directamente en el archivo `.ini` generado bajo las raíces de escritura descubiertas (`write_roots`), o mediante un mecanismo verificado vía MCP.  
> 4. Si el entorno no permite este mapeo verificado de forma segura, el operador debe devolver de inmediato `status: "unsupported"` con `blocking_reason: "unsupported_currency_or_delay_injection"`.

---

## 3. Lanzamiento de Backtest (`tester_run_backtest`)

*Esquema Documentado:* `tester_run_backtest.json`

> [!IMPORTANT]
> **Resolución Obligatoria de Rutas Absolutas:**  
> `tester_run_backtest` exige que `config_path` e `inputs_path` sean **rutas absolutas** bajo la subcarpeta `\MQL5\Profiles\Tester`.  
> El operador resuelve estas rutas absolutas concatenando la raíz `mql5_folder` descubierta dinámicamente mediante `get_workspace_info` con la subcarpeta del perfil:  
> `config_path = mql5_folder + "\\Profiles\\Tester\\config_generated.ini"`  
> `inputs_path = mql5_folder + "\\Profiles\\Tester\\inputs.set"`  
> Queda terminantemente prohibido suministrar rutas relativas ambiguas a `tester_run_backtest`.

```jsonc
// Herramienta: terminal:tester_run_backtest
{
  "config_path": "<MQL5_FOLDER_ABSOLUTE>\\Profiles\\Tester\\config_generated.ini",
  "inputs_path": "<MQL5_FOLDER_ABSOLUTE>\\Profiles\\Tester\\inputs.set",
  "wait": false,
  "timeout_sec": 300
}
```
*Retorno de la llamada:*
```json
{
  "run_id": "<RUN_ID_PLACEHOLDER>",
  "tester_status": "started"
}
```

---

## 4. Lanzamiento de Optimización (`tester_run_optimization`)

*Esquema Documentado:* `tester_run_optimization.json`
```jsonc
// Herramienta: terminal:tester_run_optimization
{
  "config_path": "<MQL5_FOLDER_ABSOLUTE>\\Profiles\\Tester\\opt_generated.ini",
  "inputs_path": "<MQL5_FOLDER_ABSOLUTE>\\Profiles\\Tester\\opt_inputs.set",
  "wait": false,
  "timeout_sec": 1800
}
```
* **Rutas Absolutas:** Al igual que en el backtest, `config_path` e `inputs_path` deben ser rutas absolutas resueltas a partir de `mql5_folder`.
* **Rangos de Optimización Cuantitativos:** El contrato puede recibir rangos fijados por el rol Quant (`optimization_ranges` con `start`, `step`, `stop` por parámetro) para inyectarlos en el archivo de parámetros `.set`. El operador no modifica ni elige estos rangos.
* **Retorno:** Objeto con `run_id` (string) que identifica la tarea de optimización.

---

## 5. Control de Ciclo de Vida: Estado, Espera y Parada

### 5.1. Consulta de Estado (`tester_get_status`)
*Esquema Documentado:* `tester_get_status.json`
```jsonc
// Herramienta: terminal:tester_get_status
{
  "run_id": "<RUN_ID_PLACEHOLDER>"
}
```
> [!IMPORTANT]
> `tester_get_status` **requiere obligatoriamente `run_id` no vacío**. No se permite su invocación sin identificador.

### 5.2. Espera Controlada (`tester_wait`)
*Esquema Documentado:* `tester_wait.json`
```jsonc
// Herramienta: terminal:tester_wait
{
  "run_id": "<RUN_ID_PLACEHOLDER>",
  "timeout_sec": 60
}
```

### 5.3. Detención Forzada (`tester_stop`)
*Esquema Documentado:* `tester_stop.json`
```jsonc
// Herramienta: terminal:tester_stop
{
  "run_id": "<RUN_ID_PLACEHOLDER>"
}
```
*Detiene inmediatamente la corrida identificada bajo autorización expresa (`gates.mutation_approval = true`).*

---

## 6. Backtesting Multi-Activo Nativo vía Market Watch (`Optimization=3`)

### 6.1. La Directiva Nativa `Optimization=3`
En MetaTrader 5, el Strategy Tester provee una modalidad nativa para ejecutar simulaciones multi-activo en una sola corrida unificada:
* **Directiva en archivo `.ini`:** Bajo la sección `[Tester]`, el parámetro `Optimization=3` corresponde a la opción *"Todos los símbolos seleccionados en Observación del Mercado"* (*All symbols selected in Market Watch*).
* **Mecánica Interna:** 
  1. El terminal lee la lista de símbolos activos y visibles en la ventana Market Watch.
  2. Mantiene fijos e idénticos todos los parámetros de entrada del Asesor Experto.
  3. Ejecuta una pasada independiente por cada símbolo ($Pass_0, Pass_1, \dots, Pass_{N-1}$).
  4. Distribuye concurrentemente las pasadas entre los agentes locales (`Core 01`, `Core 02`, etc.), reduciendo drásticamente el tiempo de ejecución frente a loops externos serializados.
  5. Consolida la totalidad de las métricas en la pestaña nativa **"Resultados de optimización"** (*Optimization Results*) del terminal.

### 6.2. Generación del Perfil Técnico
Dado que `tester_prepare_config` opera con un booleano para `optimization` (que fija 0 o 1), el operador plasma la directiva `Optimization=3` directamente en el archivo `.ini` bajo las raíces de escritura permitidas:
```ini
[Tester]
Expert=Experts\MiEstrategia.ex5
Optimization=3
Model=1
OptimizationCriterion=6
Period=M15
FromDate=2020.01.01
ToDate=2024.12.31
Deposit=100000.00
Currency=USD
Leverage=20
ProfitInPips=0
ExecutionMode=0
Visual=0
ForwardMode=0
```

### 6.3. Manejo de Inicios Históricos Dispares y Pasadas Omitidas
* Si la ventana de prueba (`FromDate` a `ToDate`) abarca períodos donde ciertos activos de Market Watch no cotizaban (ej. activos recientes o IPOs), el Strategy Tester simula cada símbolo desde su primera barra válida.
* Si un símbolo debutó después de la fecha `ToDate`, MT5 **omite ese activo de forma segura** y reporta en el diario (`Tester: testing on Market Watch symbols finished, total passes M`), donde $M \le N$. El operador no debe declarar fallo si $M < N$ siempre que las pasadas emitidas correspondan estrictamente a los activos con datos en el intervalo.

### 6.4. Protocolo de Partición Temporal (In-Sample vs Out-of-Sample)
Para salvaguardar la pureza estadística del estudio:
* El operador ejecuta la corrida `Optimization=3` fijando como `ToDate` el límite superior del período de entrenamiento **In-Sample (IS)** (ej. `2015.01.01` a `2022.12.31`).
* El segmento más reciente (ej. `2023.01.01` a `2024.12.31`) permanece **estrictamente ciego y reservado como Out-of-Sample (OOS)**, impidiendo filtraciones de datos hacia la fase de entrenamiento.

---

## Fuente de configuración y verificación

Las directivas `Currency` y `ExecutionMode` están documentadas por [MetaQuotes, Platform Start](https://www.metatrader5.com/en/terminal/help/start_advanced/start). ExecutionMode admite 0, -1 (aleatorio) y retardos positivos hasta 600000 ms. Esta fuente documenta el formato, no autoriza una vía CLI.

Toda escritura de perfiles se hace por MCP, en archivos nuevos de la tarea, con lectura de verificación antes del lanzamiento. Si el proveedor no permite preparar y verificar todos los valores solicitados, devolver `unsupported`; no ignorarlos ni usar los del terminal. Los ejemplos son plantillas: resolver raíces, nombres y fechas con el contrato. No sobrescribir presets existentes. Fijar también los inputs por defecto del EA si no se suministra .set; no depender de la última sesión del tester. Contrastar configuración efectiva por run_id después de lanzar.

