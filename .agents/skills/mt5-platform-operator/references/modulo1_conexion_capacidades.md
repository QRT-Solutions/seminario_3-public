# Módulo 1: Conexión y Descubrimiento de Capacidades

> **Autor Institucional:** QRT Solutions  
> **Ámbito:** Inicialización de sesión con el proveedor MCP, límites de permisos y sincronización temporal.

---

## 1. Fuente Documental y Descubrimiento de Esquemas

Las firmas y parámetros vigentes se obtienen del catálogo `tools/list` del proveedor
MCP descubierto en la sesión. Las tablas de esta skill proceden de esquemas
históricos del cliente de origen; no requieren su caché personal de Antigravity.

> [!NOTE]
> **Distinción Epistémica:** La presencia de un esquema `.json` en disco prueba que la interfaz de la herramienta está documentada y disponible para inspección estática; **NO** prueba que el servidor la ejecute con éxito en vivo ni que el terminal subyacente la soporte en una configuración concreta. La disponibilidad viva se valida mediante respuestas en tiempo de ejecución.

---

## 2. Inicialización de Sesión (`get_workspace_info`)

Para las herramientas que dependen del servidor MCP del terminal, la llamada `terminal:get_workspace_info` consulta el contexto del proveedor y puede exponer la topología de trabajo:

```jsonc
// Herramienta: terminal:get_workspace_info
// Argumentos: {}
```

### Campos de referencia, sujetos a la respuesta real:
Los nombres siguientes son ejemplos del adaptador documentado, no un esquema universal de salida. Si faltan, no inventarlos ni convertir su ausencia en valores por defecto.
* **`workspace`:** Rutas de trabajo (`mql5_folder`, `include_folder`, `common_folder`).
* **`permissions`:** 
  * `read_roots`: Conjunto de rutas autorizadas para lectura.
  * `write_roots`: Conjunto de rutas autorizadas para escritura.
  * *Límite de permisos:* Las rutas no incluidas en estas listas (por ejemplo, carpetas del sistema del terminal fuera de `read_roots`) resultarán en rechazo por la capa de permisos del MCP. Esto se descubre por instalación y no debe asumirse como regla universal de MT5.
* **`compiler`:** Presencia de compilador MQL5 (`compiler_mql5`), build reportado y arquitectura objetivo.
* **`capabilities`:** Indicadores booleanos de soporte (`can_compile_file`, `can_run_backtest`, `can_run_optimization`, etc.).

---

## 3. Sincronización Temporal (`get_time_information`)

MetaTrader 5 gestiona la hora local del terminal, la hora UTC y la hora del servidor de trading:

```jsonc
// Herramienta: terminal:get_time_information
// Argumentos: {}
```

* **Respuesta esperada:** Expone `utc_time`, `local_time`, `local_utc_offset_minutes` y `trade_server_last_known_time`.
* **Uso obligatorio:** Los filtros de búsqueda en diarios del tester (`datetime_from`, `datetime_to`) deben calcularse contra `local_time`, respetando el offset descubierto.
