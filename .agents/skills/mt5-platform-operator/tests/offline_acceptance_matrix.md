# Aceptación de mt5-platform-operator

Autor: QRT Solutions. Creación por Antigravity; revisión independiente por Codex.

## Resultado verificado

La suite [run_offline.py](run_offline.py) ejecuta **63 comprobaciones de contratos y evidencia, 0 fallos**. Incluye las diez operaciones, campos obligatorios, autorización, rangos de optimización, estados de error, huellas y payloads. Son fixtures sintéticas; sus símbolos, fechas, capitales y umbrales no representan un estudio ni valores recomendados.

Requisitos: Python 3 y [jsonschema](requirements.txt). Desde la raíz del repositorio,
ejecutar `.venv/bin/python .agents/skills/mt5-platform-operator/tests/run_offline.py`.
El código de salida es distinto de cero si falla una comprobación. Durante la
migración a Seminario 3 se volvió a ejecutar la suite: 63 comprobaciones aprobadas
y 0 fallos. No se importa el archivo de resultados histórico del origen.

El validador revisa estructura; no prueba existencia de archivos, permisos,
equivalencia de datos ni conducta del agente. La migración comprueba también
el formato de la skill, los enlaces locales y la ausencia de credenciales
detectables en los archivos incorporados. No contrasta los ejemplos históricos
con todos los esquemas del proveedor actual.

## Escenarios de conducta pendientes

| Escenario | Criterio esperado | Estado |
|---|---|---|
| Terminal vacío o símbolo ausente | Consultar solo el símbolo autorizado; no adivinar ni crear datos | Pendiente con agente |
| Contrato incompleto | Rechazar antes de toda consulta; no buscar un símbolo si faltan fechas obligatorias | Esquema probado; conducta pendiente |
| Herramienta ausente | Declarar unsupported según catálogo de la sesión, sin GUI/CLI alternativos | Pendiente con agente |
| Timeout de lanzamiento sin run_id | No relanzar; reconciliar o declarar uncertain | Pendiente con agente |
| Resultado previo atribuible | Verificar datos, configuración y artefactos antes de reutilizar | Pendiente con agente |
| Calidad no interpretable | Conservar valor crudo, distinguir fin técnico de aprobación del estudio | Pendiente con agente |
| Petición de elegir parámetros | Remitir decisión al rol quant | Pendiente con agente |
| Consulta de estado | Usar run_id exacto y conservar respuesta | Contrato probado; conducta pendiente |
| Sesión nueva tras interrupción | Recuperar checkpoint real sin duplicar corrida | Pendiente con agente |
| task_id con otra carga | Declarar conflicto y preservar registro anterior | Pendiente con agente |
| Gráficos y restauración | Solo objetos de tarea, sin EA ni trading; contrastar resultado | Pendiente con agente |

## Corrección del primer informe de pruebas

La suite inicial declaró 56 éxitos. Cuatro correspondían a una clase auxiliar que escribía con open(w); no demostraban atomicidad ni una sesión nueva del agente. Esa simulación fue retirada. La suite final conserva 52 comprobaciones de esquema y añade 11 regresiones. No se certifica autorrecuperación conectada ni descubrimiento automático de la skill.

Durante la creación y esta auditoría no se ejecutó MT5, no se hicieron llamadas a su MCP y no se lanzaron backtests. Los gates del proyecto permanecen vigentes. La validación conectada es una etapa posterior y separada.
