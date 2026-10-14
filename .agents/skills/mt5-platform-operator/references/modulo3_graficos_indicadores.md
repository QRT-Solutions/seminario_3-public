# Módulo 3: Gráficos, Indicadores y Plantillas

> **Autor Institucional:** QRT Solutions  
> **Ámbito:** Apertura, control e inspección de gráficos e indicadores condicionados al catálogo real descubierto.

---

## 1. Gestión de Gráficos (Firmas de Esquema Verificadas)

### 1.1. Abrir Gráfico (`chart_open`)
*Esquema:* `chart_open.json`
```jsonc
// Herramienta: terminal:chart_open
{
  "symbol": "SYMBOL_PLACEHOLDER",
  "period": "M15"
}
```
* **Parámetros obligatorios:** `symbol` (string), `period` (string: M1..MN1).
* **Retorno:** Objeto con el identificador del gráfico como cadena (`chart_id: "CHART_ID_PLACEHOLDER"`).

### 1.2. Listar Gráficos Abiertos (`list_open_charts`)
*Esquema:* `list_open_charts.json`
```jsonc
// Herramienta: terminal:list_open_charts
{}
```
* **Retorno:** Lista de gráficos con metadatos de ventana, símbolos y temporalidades activas.

### 1.3. Cerrar Gráfico (`chart_close`)
*Esquema:* `chart_close.json`
```jsonc
// Herramienta: terminal:chart_close
{
  "chart_id": "CHART_ID_PLACEHOLDER"
}
```
* **Parámetro obligatorio:** `chart_id` (**tipo string**, no entero).

---

## 2. Aplicación de Plantillas (`chart_apply_template`)

*Esquema:* `chart_apply_template.json`
```jsonc
// Herramienta: terminal:chart_apply_template
{
  "chart_id": "CHART_ID_PLACEHOLDER",
  "template_filename": "clean_view.tpl"
}
```
* **Parámetros obligatorios:** 
  * `chart_id` (string).
  * `template_filename` (string): Debe existir en la subcarpeta `\MQL5\Profiles\Templates`.
* **Regla de Seguridad de Plantillas:** Las plantillas aplicadas deben ser estrictamente de visualización gráfica (colores, velas, rejillas) y **NO deben contener Asesores Expertos vinculados ni scripts con directivas de trading**.

---

## 3. Adición de Indicadores Técnicos (`chart_add_indicator`)

*Esquema:* `chart_add_indicator.json`
```jsonc
// Herramienta: terminal:chart_add_indicator
{
  "chart_id": "CHART_ID_PLACEHOLDER",
  "indicator_name": "INDICATOR_NAME_PLACEHOLDER",
  "indicator_parameters": "Param1=Value1,Param2=Value2"
}
```
* **Parámetros:**
  * `chart_id` (string, obligatorio).
  * `indicator_name` (string, obligatorio): Nombre del indicador verificado.  
    > [!WARNING]
    > **No Asumir Indicadores por Defecto:** Queda terminantemente prohibido asumir que indicadores de demostración como `"Examples\\ATR"` o `"ATR Examples"` existen en el terminal. El operador debe validar previamente su disponibilidad mediante `list_available_indicators`.
  * `custom_indicator_path` (string, opcional): Ruta absoluta al `.ex5` compilado, requerido para indicadores en carpetas personalizadas bajo `MQL5`.
  * `indicator_parameters` (string, opcional): Cadena estricta separada por comas en formato `Name=Value`, **sin espacios** (ej. `"InpPeriod=14,InpMethod=0"`).

---

## 4. Frontera de Propiedad, Restauración y Seguridad Operativa

> [!CAUTION]
> **1. Propiedad Estricta de Objetos y Ventanas:**  
> El operador sólo debe modificar, interactuar o cerrar gráficos u objetos que hayan sido creados específicamente para la tarea técnica en curso (`task_id`). Queda prohibido cerrar gráficos de supervisión existentes del usuario o de otras tareas concurrentes.
> 
> **2. Restauración al Estado Inicial:**  
> Al finalizar una tarea técnica que haya requerido abrir ventanas de gráficos temporales para inspección, el operador debe proceder a su cierre ordenado (`chart_close`) para no saturar los recursos gráficos del terminal.
> 
> **3. Prohibición de Trading en Gráficos:**  
> Las ventanas de gráficos manipuladas por el operador no deben contener EAs activos ni auto-trading habilitado.

---

## 5. Patrón de Aprovisionamiento Headless Desatendido vía Indicador

En terminales desatendidos donde no hay operador manual para interactuar con cuadros de diálogo ni arrastrar scripts, la invocación de Asesores Expertos (EAs) vía plantillas `.tpl` puede ser bloqueada si el botón de *Trading Algorítmico* está deshabilitado en la barra de herramientas del terminal.

### El Canal de Indicadores Personalizados:
Los indicadores técnicos (`chart_add_indicator`) constituyen el canal de ejecución MQL5 más seguro y confiable en entornos desatendidos:
1. **Ejecución Incondicional:** El motor de MT5 ejecuta siempre la función `OnInit()` del indicador en el hilo del gráfico sin solicitar confirmaciones de trading.
2. **Acceso Completo a la API de Símbolos:** Dentro de `OnInit()`, un indicador en un gráfico vivo puede crear símbolos (`CustomSymbolCreate`), configurar propiedades financieras, calibrar sesiones RTH (`CustomSymbolSetSession*`) y reemplazar series temporales masivas (`CustomRatesReplace`).
3. **Flujo de Ejecución Atómica:**
   - Abrir gráfico de anclaje temporal: `chart_open(anchor_symbol, "M1")`.
   - Inyectar indicador: `chart_add_indicator(chart_id, indicator_name, custom_indicator_path)`.
   - Esperar ejecución y validar telemetría en `get_expert_journal`.
   - Seleccionar en Market Watch: `add_marketwatch_symbol(custom_symbol)`.
   - Cerrar gráfico de anclaje: `chart_close(chart_id)`.
   - Restaurar el slot si se utilizó un indicador preexistente.
   - Detalle completo del protocolo en **[Módulo 9: Protocolo de Calidad Histórica](modulo9_protocolo_calidad_historica.md)**.

