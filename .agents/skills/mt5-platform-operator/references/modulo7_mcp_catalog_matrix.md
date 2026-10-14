# Módulo 7: Matriz de Catálogo MCP (Documentado vs Disponible vs Unsupported)

> **Autor Institucional:** QRT Solutions  
> **Ámbito:** Selección documental del ecosistema de herramientas de MetaTrader 5 por proveedor, disponibilidad real y estado de verificación.

---

## 1. Criterios de Clasificación y Fuente Documental

Las tablas siguientes conservan firmas documentadas en el cliente de origen.
Obtener las firmas vigentes mediante `tools/list` del proveedor MCP descubierto
en la sesión; no se necesita la caché personal del cliente de origen.

> [!NOTE]
> **Condición de Verificación:** La presencia de archivos en la caché local de esquemas demuestra que la firma está documentada para inspección estática. La disponibilidad viva en una sesión activa del terminal depende del catálogo MCP vivo, de la respuesta del proveedor y de sus permisos. La existencia de un archivo local **nunca certifica por sí sola la ejecución viva**.

* **`Documentado en caché de esquemas local`:** Herramienta con esquema `.json` existente en disco, con parámetros conocidos e inspeccionados.
* **`Documentado en MQL5 (No expuesto en MCP)`:** Función de la API de MetaQuotes/MQL5 que no cuenta con herramienta homóloga en el servidor MCP.
* **`Unsupported`:** Funcionalidad expresamente no soportada o fuera de permisos descubiertos.

---

## 2. Selección de herramientas documentadas

### 2.1. Gestión de Workspace y Sistema
| Herramienta / Función | Proveedor | Firma de Esquema Verificada | Estado Documental |
| :--- | :--- | :--- | :---: |
| `get_workspace_info` | Terminal MCP | `{}` | Documentado en caché de esquemas local |
| `get_time_information` | Terminal MCP | `{}` | Documentado en caché de esquemas local |
| `find_files_by_glob` | Terminal MCP | `path, pattern, max_results?, show_hidden?` | Documentado en caché de esquemas local |
| `read_file` | Terminal MCP | `path` | Documentado en caché de esquemas local |
| `read_binary_file` | Terminal MCP | `path, offset?, length?` | Documentado en caché de esquemas local |
| `write_file` | Terminal MCP | `path, content` | Documentado en caché de esquemas local |
| Acceso a `bases/` | Sistema MT5 | N/A | **`Unsupported`** (si está fuera de `read_roots`) |

### 2.2. Símbolos, Precios y Ticks
| Herramienta / Función | Proveedor | Firma de Esquema Verificada | Estado Documental |
| :--- | :--- | :--- | :---: |
| `get_marketwatch_symbols` | Terminal MCP | `symbol?, include_hidden?, limit?` | Documentado en caché de esquemas local |
| `add_marketwatch_symbol` | Terminal MCP | `symbol` | Documentado en caché de esquemas local |
| `remove_marketwatch_symbol` | Terminal MCP | `symbol` | Documentado en caché de esquemas local |
| `get_chart_history` | Terminal MCP | `symbol, period, datetime_from, datetime_to, limit?` | Documentado en caché de esquemas local |
| `get_chart_ticks_history` | Terminal MCP | `symbol, datetime_from, datetime_to, limit?` | Documentado en caché de esquemas local |
| `SymbolInfoSessionQuote` | MQL5 Nativo | `symbol, day, session, from, to` | Documentado en MQL5 (No expuesto en MCP) |
| `CustomSymbolCreate` | MQL5 Nativo | `symbol, group, origin` | Documentado en MQL5 (No expuesto en MCP) |

### 2.3. Gráficos e Indicadores
| Herramienta / Función | Proveedor | Firma de Esquema Verificada | Estado Documental |
| :--- | :--- | :--- | :---: |
| `chart_open` | Terminal MCP | `symbol, period` | Documentado en caché de esquemas local |
| `chart_close` | Terminal MCP | `chart_id (string)` | Documentado en caché de esquemas local |
| `chart_apply_template` | Terminal MCP | `chart_id (string), template_filename` | Documentado en caché de esquemas local |
| `chart_add_indicator` | Terminal MCP | `chart_id (string), indicator_name, custom_indicator_path?, indicator_parameters? (string)` | Documentado en caché de esquemas local |
| `list_open_charts` | Terminal MCP | `{}` | Documentado en caché de esquemas local |
| `list_available_indicators` | Terminal MCP | `{}` | Documentado en caché de esquemas local |
| `list_available_expert_advisors` | Terminal MCP | `{}` | Documentado en caché de esquemas local |

### 2.4. Strategy Tester
| Herramienta / Función | Proveedor | Firma de Esquema Verificada | Estado Documental |
| :--- | :--- | :--- | :---: |
| `tester_get_configuration` | Terminal MCP | `run_id (string)` | Documentado en caché de esquemas local |
| `tester_get_status` | Terminal MCP | `run_id (string)` *(obligatorio)* | Documentado en caché de esquemas local |
| `tester_prepare_config` | Terminal MCP | `expert_path, output_path, model? (string), optimization_criterion? (string)...` | Documentado en caché de esquemas local |
| `tester_run_backtest` | Terminal MCP | `config_path, inputs_path?, wait?, timeout_sec?` | Documentado en caché de esquemas local |
| `tester_run_optimization` | Terminal MCP | `config_path, inputs_path?, wait?, timeout_sec?` | Documentado en caché de esquemas local |
| `tester_wait` | Terminal MCP | `run_id (string), timeout_sec (integer)` | Documentado en caché de esquemas local |
| `tester_stop` | Terminal MCP | `run_id (string)` | Documentado en caché de esquemas local |
| `tester_get_report` | Terminal MCP | `run_id (string), file_format?, path?` | Documentado en caché de esquemas local |
| `get_tester_journal` | Terminal MCP | `datetime_from, datetime_to, filter?, limit?` | Documentado en caché de esquemas local |
| Calidad histórica por intervalo | Proveedor por descubrir | No asumir nombre de herramienta | Unsupported si el catálogo vivo no la ofrece |

---

## 3. Principio de Contención Operativa

> [!CAUTION]
> Lo que no esté expuesto en el catálogo del MCP descubierto se clasifica como `unsupported`. Queda estrictamente prohibido recurrir a emulación de clics por ratón (*Computer Use* no autorizado) o scripts arbitrarios sin validación previa.
