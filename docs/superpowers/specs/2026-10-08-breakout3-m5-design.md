# Ruptura de tres velas M5 con salida a los diez minutos

Autoría: **QRT Solutions**. Fecha: 2026-10-08.

Strategy UUID: `STRAT-20261008-BREAKOUT3_LONG-M5-v1.0`.

Estado: variante B aprobada; diseño escrito para revisión antes de implementar.
Contrato: [StrategySpecification](2026-10-08-breakout3-m5-contract.json).

## Decisiones del usuario

La estrategia se aplica al símbolo del gráfico, utiliza M5, compra la ruptura
del máximo de las últimas tres velas cerradas y utiliza exactamente 0,10 lotes
por operación. El usuario seleccionó la variante B presentada con SL de
0,25x ATR D1 y TP de 0,50x ATR D1. La salida temporal ocurre a los 600 segundos
desde la ejecución, si ninguna de las barreras de precio ha cerrado antes.

No existe filtro de tendencia. Se permite una sola posición y una sola orden
pendiente de esta estrategia por símbolo. No se multiplica el volumen entre
señales ni se añaden posiciones mientras exista una compra abierta.

## Hipótesis y definición matemática

Las tres velas forman el techo de los últimos quince minutos. Comprar al
romperlo busca comprobar si el movimiento continúa durante los diez minutos
siguientes; esto es una hipótesis y no un rendimiento demostrado.

Al empezar una nueva vela M5:

- H3 = máximo de High[1], High[2] y High[3]. La vela en formación es High[0]
  y queda excluida del cálculo.
- A = ATR D1 de 14 períodos, leído del día cerrado anterior, shift 1.
- E = H3 ajustado hacia arriba al incremento mínimo de precio del símbolo.
- SL = E − 0,25 × A; TP = E + 0,50 × A.
- V = 0,10 lotes, sin redondearlo o sustituirlo por otro volumen.
- Fecha límite de posición = instante de ejecución real + 600 segundos.

El ATR funciona como una regla elástica: distancia = múltiplo × ATR diario.
Permite que las barreras se adapten al movimiento del activo. A se fija al
crear la orden y los niveles SL/TP permanecen fijos durante esa operación.
Los precios se ajustan al tick del símbolo, sin añadir un buffer de entrada.
Un salto del precio puede producir una ejecución distinta de E y alterar la
relación realizada entre beneficio y riesgo; no se promete una ejecución exacta.

## Preparación y actualización de la entrada

`IsNewBar()` controla únicamente el cálculo de señales y la preparación de
órdenes usando velas cerradas. La Buy Stop se ejecuta por el servidor cuando
Ask alcanza su nivel, incluso dentro de una vela. Esta ejecución intrabar es
la característica de la variante B seleccionada, no una señal con datos futuros.

1. Al inicializar, esperar al siguiente cambio de vela M5 para preparar una señal.
2. Si existe una posición propia, no crear ninguna entrada pendiente.
3. Sin posición, cancelar la orden pendiente propia anterior, verificar el
   resultado de la cancelación y actualizar el nivel con las tres velas cerradas.
4. Si la cancelación falla o la orden se ejecuta durante el intento, reconciliar
   las posiciones y órdenes antes de decidir; nunca crear una segunda pendiente.
5. Crear una única Buy Stop de 0,10 lotes cuando el símbolo admita ese volumen,
   las órdenes stop y las distancias requeridas por el bróker.
6. Si Ask ya alcanzó E o E no satisface la distancia mínima, omitir esa señal.
   No convertirla en una compra a mercado ni desplazar el nivel para perseguirla.
7. Tras una salida, esperar un nuevo cierre M5 posterior a la salida antes de
   preparar otra entrada. No reabrir inmediatamente en el mismo evento de cierre.

El volumen debe cumplir mínimo, máximo y paso de lotaje del instrumento.
Si 0,10 no es válido, se registra el motivo y no se opera. El uso en cualquier
activo significa reutilizar la misma lógica; depende de las condiciones del
instrumento, no implica que todos admitan 0,10 lotes.

La orden tendrá vencimiento en la próxima apertura M5 si el instrumento admite
vencimiento a un instante especificado. Cuando solo admita GTC, el EA cancelará
la pendiente al detectar la nueva vela y al retirarse del gráfico. Una pendiente
GTC puede permanecer en el servidor si el terminal se desconecta.

## Salida temporal y recuperación

La duración se mide desde el instante real de apertura, no desde la creación
de la orden o desde el inicio de la vela en que se ejecutó. Por ejemplo, una
compra ejecutada a las 10:02:15 debe intentar cerrarse desde las 10:12:15.
Contar dos cambios de vela M5 podría cerrarla antes de diez minutos y no cumple
esta regla.

El EA comprueba el vencimiento en cada tick y mediante un temporizador de un
segundo. Al cumplirse los 600 segundos, solicita el cierre de la posición propia
en la primera oportunidad de ejecución. Si el cierre es rechazado, registra
el código del servidor y vuelve a intentarlo mientras la posición continúe
abierta. El terminal debe estar funcionando y conectado; el tiempo de ejecución
depende de la disponibilidad de cotizaciones y del servidor.

Al reiniciar el EA, se recuperan los tickets propios y el instante de apertura
desde MT5. No se reinicia el plazo de diez minutos. Si ya venció, se solicita
el cierre antes de considerar nuevas entradas. Los SL/TP iniciales permanecen
en el servidor aunque el terminal esté apagado.

## Aislamiento y seguridad de ejecución

La implementación MQL5 utilizará `CTrade` y un Magic Number exclusivo, filtrando
por símbolo y Magic Number. En hedging, cerrará por ticket y gestionará únicamente
sus propias posiciones. En netting, no abrirá si existe una posición de otro
origen en ese símbolo, para evitar mezclarla con la estrategia. Tampoco abrirá
si detecta pendientes ajenas en ese símbolo en una cuenta netting.

El parámetro `InPenableTrading` tendrá valor predeterminado `false`. En Strategy
Tester la estrategia estará habilitada automáticamente. Preparar, copiar y
compilar el EA no equivale a autorizar que se adjunte a un gráfico con trading
habilitado ni a colocar órdenes en la cuenta conectada.

## Entregables y paridad

La siguiente fase producirá fuente MQL5, fuente Pine Script v6 y
`STRATEGY_FACTSHEET.md`, todos con autoría QRT Solutions. MQL5 será la referencia
para la ejecución de la salida a los 600 segundos.

En Pine, la preparación de órdenes se realizará con `barstate.isconfirmed` y
los datos diarios usarán `lookahead = barmerge.lookahead_off` con desplazamiento
del dato diario para excluir el día en formación. Las órdenes stop del emulador
pueden ejecutarse intrabar. En histórico M5, una salida evaluada solo al cierre
de vela puede demorarse hasta el siguiente cierre posterior al vencimiento:
no se declarará paridad temporal exacta sin evidencia intrabar que la demuestre.
La versión Pine identificará esta limitación en sus resultados.

El EA incorporará `OnTester()` y el selector de retorno porcentual acumulado,
Sharpe porcentual anualizado y profit factor porcentual. El criterio inicial
será la suma de los retornos del precio de las operaciones cerradas. Para el
Sharpe, los retornos se sumarán por fecha de cierre del servidor, incluyendo
con cero los días calendario sin cierres dentro del intervalo del test. Se
utilizará media diaria / desviación estándar muestral diaria × raíz de 365,
con tasa libre de riesgo igual a cero. Con menos de dos días o desviación
estándar igual a cero, el criterio devolverá cero y señalará muestra insuficiente.
Esta métrica describe la serie diaria de retornos del precio y no el rendimiento
del capital de la cuenta. No se confundirá el tiempo de permanencia con una
frecuencia constante de entradas. El profit factor porcentual será no definido
si no hay pérdidas; para `OnTester()` se devolverá cero y se registrará esa
condición, sin presentarlo como un ratio real igual a cero.

## Verificación prevista y criterio de aceptación

Se verificará que cambiar el símbolo no deje nombres de activos codificados;
que el máximo utilice exactamente shifts 1 a 3; que no se apilen órdenes;
que el lotaje sea 0,10 o la señal se rechace; y que SL/TP usen el ATR diario
cerrado. Se comprobarán entradas a mitad de vela, reinicio con posición abierta,
cancelación rechazada, falta de datos, gaps, volumen incompatible y aislamiento
de operaciones manuales.

La compilación nativa deberá terminar con cero errores y cero advertencias.
Las pruebas de ejecución temporal necesitan ticks, preferentemente reales.
No se elegirá un activo, un período o una optimización por supuesto: el
backtest requiere un mandato posterior con símbolos y fechas concretas.

El contrato v2 general del repositorio obliga a elegir filtros de régimen
que no forman parte de esta variante. Este contrato de diseño se mantiene
separado del registro de estrategias y declara su formato específico, para
no inventar un filtro ni alterar los contratos existentes. Su validación
inicial comprobará sintaxis JSON y coherencia de sus parámetros y reglas.

Referencias: [Guía canónica, Pilar 2](../../../MT5/docs_educativos/PILAR_2_HIPOTESIS_Y_LOGICA.md)
y [MetaQuotes, iHighest](https://www.mql5.com/en/docs/series/ihighest).
