# Módulo 8: Adaptador e Índice de Conocimiento Local

> **Autor Institucional:** QRT Solutions  
> **Ámbito:** Normalización estricta de la base de conocimiento local, mapeo documental verificado y fronteras de ejecución exclusiva por MCP.

---

## 1. Normalización Estricta de la Raíz de Conocimiento (`knowledge_root`)

Para desacoplar el operador de rutas absolutas personales o estructuras arbitrarias, la raíz de conocimiento se normaliza obligatoriamente a una **carpeta que contenga el archivo canónico `INDEX.md`**:

### Procedimiento de Resolución:
1. **Entrada explícita del contrato:** Si el contrato suministra `knowledge_root`:
   * Si `<knowledge_root>/INDEX.md` existe en disco: se adopta dicha carpeta.
   * Si `<knowledge_root>/knowledge/INDEX.md` existe en disco: se normaliza a esa subcarpeta `knowledge/`.
2. **Variable de entorno host:** `$MT5_KNOWLEDGE_ROOT` evaluada bajo el mismo criterio de existencia de `INDEX.md`.
3. **Detección automática en Workspace:** Inspección de `$WORKSPACE/MT5/knowledge` o `$WORKSPACE/knowledge` verificando la presencia física de `INDEX.md`.
4. **Política ante Ausencia (Sin Fallbacks Ambiguos):**  
   Si ningún directorio contiene `INDEX.md`, **NO se aplica ningún fallback heurístico ni adivinación**. El operador declara `knowledge_root = null` y registra en las limitaciones de la tarea que la documentación local no está disponible.

---

## 2. Mapeo Canónico de Documentos Técnicos Locales

Cuando `knowledge_root` está normalizado y validado, el operador consulta por tema los siguientes documentos si están presentes; otros nombres se resuelven desde INDEX.md para contraste de especificaciones técnicas:

| Documento Canónico | Propósito Técnico Específico |
| :--- | :--- |
| **`INDEX.md`** | Índice maestro de tags temáticos, arquitectura de módulos y referencias cruzadas. |
| **`Strategy Tester MT5_ Guía Exhaustiva.md`** | Parámetros formales de perfiles `.ini`, directivas de simulación, modelos de ticks y criterios de optimización. |
| **`Informe Técnico_ Indicadores y Gráficos MT5.md`** | Especificaciones de gráficos, parámetros de indicadores técnicos, manejo de ventanas y plantillas `.tpl`. |
| **`Informe Técnico Arquitectura MetaTrader 5.md`** | Arquitectura de procesos del terminal, modelo de memoria, aislamiento de agentes del tester y sincronización de red. |
| **`Data Engineering para Trading Algorítmico MT5.md`** | Estructuras de almacenamiento `.hcc`, formatos de barras sujetos a versión, barras M1 e inyección de datos históricos. |

---

## 3. Fronteras de Seguridad y Exclusión Operativa

> [!CAUTION]
> **1. Prohibición de Importación de Credenciales:**  
> Queda terminantemente prohibido extraer, parsear, importar o versionar contraseñas, cuentas, claves API o tokens procedentes de `AGENT_CONNECTION_GUIDE.md` o cualquier otro manual.
> 
> **2. Prohibición de Fallback a CLI o Scripts Python:**  
> La documentación de arquitectura puede describir compilación por MetaEditor CLI o scripts de conexión Python. Dichas menciones son meramente descriptivas: **el operador opera EXCLUSIVAMENTE a través de las herramientas del servidor MCP del terminal**. Jamás se sustituye una herramienta MCP faltante con invocaciones a procesos externos no autorizados.
> 
> **3. Regla ante Documentación Faltante:**  
> Si una operación requiere validación documental pero el archivo o especificación necesaria no se encuentra disponible, el operador **LIMITA LA OPERACIÓN** (emitiendo `status: "blocked"` o `"unsupported"` con `blocking_reason: "missing_required_technical_documentation"`). Queda estrictamente prohibido adivinar comportamientos, inventar estructuras de archivos o asumir formatos no verificados.
