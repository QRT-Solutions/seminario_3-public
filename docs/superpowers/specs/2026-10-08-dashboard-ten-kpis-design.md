# Diez KPI en el dashboard del seminario

Autoría: QRT Solutions.

El usuario aprobó la selección de diez indicadores y su implementación en la
aplicación existente: equity, neto cerrado, retorno puro acumulado, drawdown,
Profit Factor, acierto, payoff, esperanza, riesgo hasta SL y nivel de margen.

Se conserva la aplicación JavaScript y la paginación existente. Una RPC adicional
agrega operaciones completas en Supabase; el navegador recibe solo resultados y
conteos. Frente a descargar todos los deals, esto mantiene el coste de red acotado
y evita calcular sobre una página. El laboratorio simulado permanece separado.

Los filtros de símbolo, dirección original y fecha de cierre afectan al rendimiento.
Las aperturas anteriores al período se incluyen al reconstruir precios y costes.
El filtro de ejecución sigue afectando solo a los deals. Cuenta y motivos conservan
su alcance. No se infiere una estrategia a partir de comentarios o magic numbers.

La reconstrucción exige volumen positivo y balanceado, un símbolo, entradas de una
misma dirección y salidas opuestas, todas las entradas antes de las salidas y un solo
retorno a volumen cero. Los parciales usan precios ponderados por volumen. INOUT,
reaperturas intercaladas y cierres sin apertura se excluyen y se cuentan. Esto prueba
consistencia del historial observado, no integridad de datos que nunca se recibieron.

Los retornos porcentuales describen precio antes de costes, no capital. Acierto usa
esa misma base e incluye neutros. Neto y PF monetario usan costes recibidos de toda
la operación, excluyen flujos y advierten de cargos separados no enviados.

Sin muestra o denominador válido se muestra «Sin datos». Sin margen se informa
«Sin margen utilizado». Riesgo es cero solo con snapshot completo, equity positiva
y ninguna posición; si falta SL se informa riesgo no acotado. Con posiciones y SL
no se inventa valoración monetaria. Drawdown queda sin datos porque falta la serie
histórica de equity ajustada por flujos.

La RPC limita la lectura a la demo ya publicada, no devuelve identificadores y no
cambia tablas, RLS, publicación ni trading. Se prueban cálculos SQL con fixtures y
ROLLBACK local, estados del presentador y uso real en navegador a cuatro anchos.
El despliegue usa únicamente el build público del proyecto existente de Vercel.

## Ampliación solicitada: distribuciones y curvas

Cuatro gráficos en el dashboard existente: histograma de retornos del precio,
histograma de neto monetario, retorno puro acumulado con contribuciones de compras
y ventas, y neto acumulado. Se reutiliza Chart.js ya incluido y la RPC de KPI;
no se cambia el framework ni se descarga otra copia del historial.

Los histogramas usan doce intervalos iguales del mínimo al máximo, o uno si la
muestra es constante. Las curvas parten de cero, ordenan cierres por fecha e ID
interno y muestran como máximo 400 puntos mediante bloques consecutivos. El
extremo de cada bloque conserva el acumulado exacto; la interfaz declara cuándo
se agrupa y muestra los rangos de cierres y fechas en tablas accesibles.
No se presenta el neto acumulado como equity ni se calcula drawdown desde él.

Filtros y totales coinciden con los KPI. Se prueban histograma vacío/constante,
extremos de intervalo, contribuciones long/short, conciliación del último punto,
805 cierres, paginación, error HTTP y recuperación, móvil y escritorio. Se corrige
el listener de Actualizar para no enviar el objeto de evento como `p_history`.
