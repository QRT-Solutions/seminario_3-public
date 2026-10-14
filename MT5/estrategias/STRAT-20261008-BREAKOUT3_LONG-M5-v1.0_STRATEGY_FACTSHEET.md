# STRAT-20261008-BREAKOUT3_LONG-M5-v1.0

Autoría: **QRT Solutions**. Fecha: 2026-10-08.

## Reglas de la versión

| Parámetro | Regla |
|---|---|
| Instrumento | Símbolo del gráfico; requiere M5 |
| Dirección | Solo compras |
| Nivel | Mayor máximo de las tres velas M5 cerradas |
| Orden | Una Buy Stop; actualizar cada nueva vela M5 |
| Volumen | Exactamente 0,10 lotes; rechazar instrumentos incompatibles |
| Filtro de tendencia | Ninguno |
| SL | Entrada solicitada − 0,25x ATR D1(14) cerrado |
| TP | Entrada solicitada + 0,50x ATR D1(14) cerrado |
| Salida temporal | Desde los 600 segundos después de la ejecución |
| Reentrada | Esperar un nuevo cierre M5 posterior a la salida |
| Identificación | Símbolo + Magic Number; una instancia por combinación |

La hipótesis es que romper el techo de los últimos quince minutos puede
preceder un movimiento alcista durante los siguientes diez. Su utilidad
estadística todavía no se ha probado.

El reloj se inicia con la ejecución real. Una entrada a las 10:02:15 intenta
cerrarse desde las 10:12:15, independientemente de las aperturas M5. El EA
comprueba el plazo en cada tick y mediante temporizador de un segundo. Las
barreras de precio pueden cerrar antes. Una desconexión, el cierre del mercado
o el rechazo del servidor pueden demorar la salida temporal.

El volumen fijo no iguala el riesgo monetario entre activos. El bot valida
mínimo, máximo y paso de volumen, sin sustituir 0,10 por otro tamaño. Los
precios se redondean al tick; las distancias mínimas inválidas hacen omitir la
señal. No se cambia la Buy Stop por una entrada a mercado cuando el nivel ya
fue alcanzado.

## Fuentes y contrato

- [Fuente MQL5](STRAT-20261008-BREAKOUT3_LONG-M5-v1.0.mq5).
- [Fuente Pine v6](STRAT-20261008-BREAKOUT3_LONG-M5-v1.0.pine).
- [Diseño](../../docs/superpowers/specs/2026-10-08-breakout3-m5-design.md).
- [StrategySpecification](../../docs/superpowers/specs/2026-10-08-breakout3-m5-contract.json).
- [Contrato final de compilación](../evidencia/STRAT-20261008-BREAKOUT3_LONG-M5-v1.0/compile-task-final.json).
- [Evidencia de compilación](../evidencia/STRAT-20261008-BREAKOUT3_LONG-M5-v1.0/compile-evidence.json).
- Diagnósticos nativos: registro técnico local (`compile.log`, preservado como evidencia privada; resultados certificados en [compile-evidence.json](../evidencia/STRAT-20261008-BREAKOUT3_LONG-M5-v1.0/compile-evidence.json)).

| Evidencia del 2026-10-08 | Resultado |
|---|---|
| Compilador nativo MetaEditor | Build 6230, x64 |
| Diagnósticos | 0 errores; 0 advertencias |
| Binario generado | EX5 de 41.596 bytes |
| Fuente instalada | Idéntica al archivo local; SHA-256 en la evidencia |
| Catálogo del terminal | EA detectado bajo Experts |
| Parámetro de seguridad del binario | InPenableTrading=false |
| Ejecución o backtest | No realizados |
| Compilación Pine | No verificada |

## Instalación y uso

La fuente MQL5 se copia mediante MCP a la carpeta MQL5\Experts y se compila con
MetaEditor. El EA dispone de **InPenableTrading=false** por defecto; fuera del
tester no prepara, cancela ni cierra operaciones con ese parámetro desactivado.
En Strategy Tester se habilita automáticamente, sin cambiarlo.

Para verlo sin reiniciar MT5: **Ctrl + N → clic derecho en Asesores Expertos →
Actualizar**. Su uso requiere un gráfico M5. El EA gestiona exclusivamente
posiciones y órdenes propias; en netting omite nuevas entradas si encuentra
exposición o pendientes ajenas en el símbolo.

La orden pendiente vence en la próxima apertura M5 cuando el bróker admite
ese vencimiento. Si solo admite GTC, el EA la cancela al detectar la nueva vela
y al retirarse. Con el terminal desconectado una GTC puede seguir activa.
Retirar el EA no liquida automáticamente una posición abierta.

## Criterios de Strategy Tester

Seleccionar **Custom max / Criterio personalizado máximo** para que la columna
Resultado muestre la métrica elegida en **InTesterCriterion**.

| Valor | Métrica |
|---|---|
| 0, predeterminado | Suma de retornos del precio: 100 × (salida − entrada) / entrada |
| 1 | Sharpe de retornos diarios del precio; días calendario con ceros; raíz de 365 |
| 2 | Profit factor de retornos del precio |

Las métricas porcentuales no son rentabilidad del capital. El diario también
registra beneficio monetario neto incluyendo comisiones, swaps y tasas. Los
criterios no definidos por falta de dispersión, días o pérdidas devuelven cero
con una explicación en el diario, sin presentar ese cero como una estimación
válida del ratio.

## Paridad y límites de verificación

MQL5 es la referencia del temporizador. En Pine histórico M5, la salida se
evalúa al cierre posterior al vencimiento y no garantiza exactamente 600
segundos. Sus cotizaciones, sesiones, spread, especificación de contratos y
modelo de ejecución también pueden diferir de MT5.

Pine requiere introducir las unidades/contratos correspondientes a un lote
del instrumento del bróker: qty = 0,10 × unidades por lote. No se interpreta
qty=0,10 como un lote universal. El valor inicial cero exige configurar esta
equivalencia antes de simular. El ATR diario se fija al cambiar de sesión con
el valor confirmado de la sesión precedente, usando lookahead_off.

La versión Pine no se ha compilado en TradingView. La compilación MQL5 no
demuestra rendimiento ni verifica por sí sola ejecución en un backtest.
La evidencia nativa de la compilación se conserva por separado.

## Siguiente etapa de integración

La incorporación formal de BREAKOUT3 al catálogo de estrategias de `seminario_lab` y la extensión de cobertura en el pipeline de CI forman parte de una segunda etapa técnica independiente, no contemplada en este encargo documental editorial.

