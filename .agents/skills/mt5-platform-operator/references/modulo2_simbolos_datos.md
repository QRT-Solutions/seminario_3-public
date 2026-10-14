# Módulo 2: Símbolos, Especificaciones, Datos y Cobertura

> **Autor Institucional:** QRT Solutions  
> **Ámbito:** Consulta de especificaciones en Market Watch, verificación de datos OHLCV/ticks e inspección de cobertura.

---

## 1. Especificaciones de Símbolos (`get_marketwatch_symbols`)

### Firma Documentada:
```jsonc
// Herramienta: terminal:get_marketwatch_symbols
{
  "symbol": "TICKER_NAME",        // Filtro exacto opcional
  "include_hidden": true,          // Booleano opcional (false por defecto)
  "limit": 1000                    // Entero opcional
}
```

### Campos de referencia a comprobar en la respuesta:
El objeto retornado contiene las condiciones de negociación reportadas por la plataforma:
* `digits`, `point`, `contract_size`, `tick_value`, `tick_size`.
* `trade_mode`, `trade_mode_name` (descripción del modo de trading reportado por la plataforma).
* `trade_execution_mode`, `trade_calculation_mode`.
* `custom_symbol` (cadena que indica si el símbolo es personalizado).
* `update_time` (marca temporal de última actualización conocida).

> [!NOTE]
> No asumir códigos numéricos de `trade_mode` sin contrastar con el campo descriptivo `trade_mode_name` retornado en la respuesta viva.

---

## 2. Historial de Precios y Ticks

### 2.1. Consulta de Barras OHLCV (`get_chart_history`)
Firma estricta según esquema (`get_chart_history.json`):
```jsonc
// Herramienta: terminal:get_chart_history
{
  "symbol": "EURUSD",
  "period": "M15",
  "datetime_from": "2020-01-01T00:00:00Z",
  "datetime_to": "2020-01-10T00:00:00Z",
  "limit": 10000
}
```
* **Parámetros obligatorios:** `symbol`, `period`, `datetime_from`, `datetime_to`.
* **Períodos soportados:** `M1`, `M2`, `M3`, `M4`, `M5`, `M6`, `M10`, `M12`, `M15`, `M20`, `M30`, `H1`, `H2`, `H3`, `H4`, `H6`, `H8`, `H12`, `D1`, `W1`, `MN1`.

### 2.2. Consulta de Ticks (`get_chart_ticks_history`)
Firma estricta según esquema (`get_chart_ticks_history.json`):
```jsonc
// Herramienta: terminal:get_chart_ticks_history
{
  "symbol": "EURUSD",
  "datetime_from": "2020-01-01T00:00:00Z",
  "datetime_to": "2020-01-02T00:00:00Z",
  "limit": 50000
}
```
* **Parámetros obligatorios:** `symbol`, `datetime_from`, `datetime_to`.

### 2.3. Respuestas vacías y límites de consulta
En ciertas configuraciones o símbolos sin cotización activa de servidor comercial, la llamada a `get_chart_history` puede experimentar retardos de red o retornar un arreglo vacío (`history: []`), aun cuando existan datos en disco para el tester.
* **Directriz del Operador:** No asumir que un retorno vacío en `get_chart_history` implica ausencia de barras en el motor del tester; contrastar con las trazas de sincronización de datos emitidas en `get_tester_journal`.

---

## 3. Descubrimiento de Sesiones de Cotización

La consulta de ventanas de cotización horaria depende de las capacidades expuestas por la instalación:
* En este catálogo de herramientas MCP, **no se expone un endpoint para leer sesiones de cotización/trading**.
* Si una tarea solicita explícitamente conocer los horarios de sesión y ninguna herramienta del servidor MCP los provee, el operador debe declarar la capacidad como `unsupported` en la capa MCP actual, evitando inferir horarios sin respaldo documental o sin una herramienta dedicada.

---

## 4. Gestión de Market Watch y Fenómeno "Chart-Lock"

### 4.1. El Bloqueo por Gráfico Activo (Chart-Lock)
En la arquitectura interna de MetaTrader 5, el motor de cotizaciones vincula de forma estricta las ventanas de gráficos abiertas con la suscripción a datos en tiempo real de Market Watch.
* **Comportamiento Crítico:** Si un símbolo tiene una ventana de gráfico abierta (`.chr` visible en `list_open_charts`), la llamada a `terminal:remove_marketwatch_symbol` (homóloga a `SymbolSelect(symbol, false)` en MQL5) **es rechazada o ignorada silenciosamente por la plataforma**.
* **Protocolo Obligatorio de Purga:** Antes de expulsar cualquier símbolo de Market Watch, el operador debe:
  1. Invocar `terminal:list_open_charts`.
  2. Identificar si alguno de los símbolos a expulsar posee un `chart_id` activo.
  3. Cerrar formalmente dichas ventanas mediante `terminal:chart_close({"chart_id": "<ID_STRING>"})`.
  4. Ejecutar posteriormente `terminal:remove_marketwatch_symbol`.

### 4.2. Protocolo de Sincronización de Market Watch por Lote (Batch Sync)
Para configurar una canasta de instrumentos de prueba sin incurrir en estados intermedios ni latencia por llamadas individuales:
1. **Fase de Diagnóstico:** Obtener la lista actual de símbolos visibles (`terminal:get_marketwatch_symbols({"include_hidden": false})`).
2. **Fase de Desbloqueo y Purga:** Cerrar gráficos bloqueantes y expulsar los símbolos no pertenecientes a la canasta objetivo.
3. **Fase de Inclusión en Bloque:** Invocar `terminal:add_marketwatch_symbol({"symbol": "<SYM>", "show": true})` para cada activo de la canasta.
4. **Verificación de Cardinalidad Estricta:** Comprobar mediante `get_marketwatch_symbols(include_hidden=false)` que:
   * La longitud devuelta coincida exactamente con el tamaño de la canasta objetivo ($N$).
   * Ningún símbolo no autorizado permanezca visible.

### 4.3. Símbolos Personalizados (Custom Symbols) y Datos Inyectados
Para activos sintetizados o inyectados desde fuentes externas (ej. TradeStation, tick feeds):
* Los símbolos deben poseer la propiedad `custom_symbol: "yes"` en sus especificaciones.
* Deben estar explícitamente seleccionados en Market Watch (`selected: true`) para que el Strategy Tester pueda acceder a sus series temporales sintetizadas (M1, M5, M15, H1, D1) de forma desatendida.

### 4.4. Calibración de Sesiones RTH y Quality Gate de Calidad Histórica
La inyección de series intradiarias puras (ej. Regular Trading Hours, RTH) sobre símbolos con configuración de sesión por defecto 24/7 (00:00 a 24:00 los 7 días) provoca que el Strategy Tester penalice las horas nocturnas y fines de semana como datos ausentes, degradando la métrica oficial de calidad al ~57%.
* **Requisito Operativo:** Todo símbolo personalizado debe someterse al protocolo de calibración estricta de sesiones RTH y corrección de marca temporal documentado en detalle en el **[Módulo 9: Protocolo de Calidad Histórica](modulo9_protocolo_calidad_historica.md)**.
* **Compuerta de Calidad ($\ge 95\%$):** Ninguna optimización cuantitativa es válida si el Strategy Tester reporta una calidad inferior al 95%.

Los intervalos de historial son inclusivos en el inicio y exclusivos en el final según el esquema documentado. Dividir consultas extensas en ventanas acotadas, detectar truncamiento por limit, conservar zona horaria, y verificar orden/duplicados/cobertura sin reparar ni importar datos por iniciativa propia. Si ambas formas de target están presentes, deben coincidir; en caso contrario rechazar el contrato.


