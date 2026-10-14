# Módulo 5: Reportes, Diarios, Run ID y Huellas

> **Autor Institucional:** QRT Solutions  
> **Ámbito:** Extracción de reportes cuantitativos, detección de formatos, contraste de configuración y telemetría de diarios.

---

## 1. Extracción de Reportes (`tester_get_report`)

*Esquema Documentado:* `tester_get_report.json`
```jsonc
// Herramienta: terminal:tester_get_report
{
  "run_id": "RUN_ID_PLACEHOLDER",
  "file_format": "xml",
  "path": "<MQL5_FOLDER_ABSOLUTE>\\Files\\report_TASK_ID.xml"
}
```
* **`run_id` (string, obligatorio).**
* **`file_format` (string, opcional):** `"json"` o `"xml"`. Por defecto `"json"`.
* **`path` (string):** Obligatorio cuando `file_format` es `"xml"`; opcional cuando es `"json"`. Debe ser ruta absoluta bajo `write_roots`.

### 1.1. Estructura del Reporte en Optimización Multi-Activo (`Optimization=3`)
Al solicitar el reporte de una corrida de optimización multi-símbolo en formato `"json"`, MT5 retorna un payload estructurado por pasadas:
```jsonc
{
  "run_id": "<RUN_ID_STRING>",
  "records_count": 20,
  "records": [
    {
      "optimization_pass": 0,
      "profit": 1.74,
      "gross_profit": 7.56,
      "gross_loss": 5.82,
      "trades": 7,
      "profit_trades": 4,
      "loss_trades": 3,
      "profit_factor": 1.2990,
      "expected_payoff": 0.25,
      "max_drawdown_equity": 9.27,
      "drawdown_percent_equity": 0.01,
      "sharpe_ratio": 0.2916,
      "custom_fitness": 0.3035
    }
  ]
}
```
* **Mapeo de Símbolos:** Cada pasada ($Pass_i$, campo `optimization_pass`) corresponde a la posición del símbolo en la ventana Market Watch en el momento del lanzamiento.
* **Correlación con Diarios:** Para verificar el mapeo unívoco símbolo-pasada sin ambigüedad, el operador consulta `get_tester_journal` filtrando por el inicio de simulación, donde el motor lista formalmente:
  `Tester: <SIMBOLO>: history data begins from <FECHA_INICIO>` en el orden exacto de asignación de pasadas.

---

## 2. Detección de Formato y Validación de Contenido

> [!CAUTION]
> **No asumir estructura a ciegas:** El operador no debe garantizar de antemano que un archivo exportado como `.xml` contenga una versión específica de SpreadsheetML ni que incluya la totalidad de los parámetros de entrada.  
> **Procedimiento de Validación:**
> 1. Inspeccionar la cabecera o firma del archivo generado en disco.
> 2. Si el XML omite los parámetros de entrada, el operador debe contrastar la configuración efectiva invocando `terminal:tester_get_configuration(run_id)` o consultando el bloque de inicialización en `get_tester_journal`.

---

## 3. Extracción de Diarios (`get_tester_journal`)

*Esquema Documentado:* `get_tester_journal.json`
```jsonc
// Herramienta: terminal:get_tester_journal
{
  "datetime_from": "2026-01-01T10:00:00",
  "datetime_to": "2026-01-01T10:05:00",
  "filter": "quality",
  "limit": 50
}
```
* **Parámetros obligatorios:** `datetime_from`, `datetime_to` (en hora local del terminal).
* **Parámetros opcionales:** `filter` (búsqueda de subcadena sensible a mayúsculas en origen y mensaje), `limit`.
* **Limitación:** Los diarios están indexados por tiempo y no garantizan contener explícitamente el `run_id`.

---

## 4. Auditoría de Trazabilidad e Integridad

Para cada ejecución, el operador emite un paquete de evidencia que vincula:
1. **`run_id`:** Identificador retornado por MT5.
2. **Huella de Configuración Efectiva:** SHA-256 canónico de los parámetros reales leídos de `tester_get_configuration` y el archivo `.ini`.
3. **Métricas Crudas:** Lectura directa sin redondeos ni inferencias subjetivas.
