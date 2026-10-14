# Laboratorio local de diez KPI

Autoría: QRT Solutions.

Versión preparada para el seminario: cálculos desarrollados, datos simulados y
vista local. **No está integrada con Supabase, Telegram, MT5 ni Vercel.** No usar
estos resultados como estadísticas de la demo publicada.

El [motor independiente](engine.mjs) puede importarse desde cualquier aplicación
JavaScript. La [vista React](DashboardContent.jsx) y su [estilo](dashboard.css)
reproducen la composición de tarjetas del dashboard, con logo Pepperstone. La
vista compilada se prepara localmente; las fórmulas no dependen del motor visual.

## Ver la muestra

Desde la raíz del repositorio, ejecutar:

```bash
python3 -m http.server 4188 --bind 127.0.0.1 --directory seminario_3/aplicaciones/kpi-laboratorio
```

Abrir `http://127.0.0.1:4188/preview.html`. La vista es autónoma y no necesita
claves, API, conexión con la plataforma ni instalación de paquetes. Incluye
fuentes y fórmulas inspeccionables. El selector de periodo afecta a los diez KPI;
símbolo y dirección afectan a los siete KPI por operación. Los tres KPI de cuenta
permanecen sobre la cuenta completa del periodo elegido.

Para regenerar los datos y verificar el motor (Node.js 22 o compatible):

```bash
node seminario_3/aplicaciones/kpi-laboratorio/generate-fixture.mjs
node --test seminario_3/aplicaciones/kpi-laboratorio/tests/*.test.mjs
```

La generación de fixtures no reconstruye el HTML automáticamente. Para reconstruir
la vista, seguir [BUILD.md](BUILD.md). Conservar la vista compilada si el agente
no dispone del runtime visual correspondiente.

## Definiciones cerradas para la presentación

Los retornos se almacenan como fracciones: `0.01` representa `1%`. La UI multiplica
por 100 solo al mostrar porcentajes. Los cocientes se muestran como ratios.

| KPI | Base | Definición |
|---|---|---|
| Tasa de acierto | Operación | Ganadores / todas las operaciones analizables; incluye neutros |
| Profit Factor % | Operación | Suma de retornos positivos / valor absoluto de retornos negativos |
| Payoff Ratio % | Operación | Media positiva / valor absoluto de media negativa |
| Expectativa por trade | Operación | Media aritmética de los retornos, incluidos neutros |
| Mediana del retorno | Operación | Valor central; promedio de los dos centrales si n es par |
| Desviación estándar | Operación | Desviación muestral, divisor n − 1 |
| Drawdown máximo | Cuenta | Mayor caída desde un máximo del índice ajustado, incluida la base inicial |
| Sharpe | Cuenta diaria | √252 × media del exceso diario / desviación muestral del exceso |
| Sortino | Cuenta diaria | √252 × media respecto al objetivo / raíz de la media de desviaciones negativas al cuadrado |
| Máxima racha de pérdidas | Operación | Secuencia negativa observada más larga ordenada por cierre UTC e ID; neutros e incompletas interrumpen el conteo |

Sharpe utiliza tasa libre de riesgo cero y Sortino objetivo cero en esta muestra.
Una tasa anual distinta se convierte a diaria como `(1 + tasa_anual)^(1/252) − 1`.
La tasa anual y el calendario deben elegirse explícitamente para producción: 252
no corresponde a una serie de cripto de 365 días. No mezclar resultados por trade
con resultados diarios de cuenta dentro del mismo ratio.

Profit Factor sin pérdidas y Sortino sin observaciones bajo el objetivo muestran
**No disponible**, con la causa; no se convierten en cero ni en un número enorme.
Una operación aislada no permite estimar desviación muestral ni Sharpe. Ningún
indicador se colorea como una recomendación de inversión ni usa umbrales inventados.

Con exclusiones, la racha describe únicamente la secuencia observada: no certifica
la máxima racha de todas las operaciones de la cuenta. Un resultado desconocido
interrumpe el conteo, evitando unir pérdidas separadas por una operación incompleta.

## Contrato de entrada del motor

Cada operación normalizada tiene un ID único por episodio, símbolo, dirección de
la posición original, precios medios ponderados de entrada/salida, volúmenes de
apertura/cierre, `is_closed`, `coverage_complete` y fechas UTC. Solo se calcula si
está completamente cerrada, sus datos son válidos y los volúmenes coinciden.

Un SELL que cierra una compra no cambia la dirección original a SELL. Un INOUT
debe separarse en cierre del episodio anterior y apertura del nuevo. En netting,
una reducción seguida de otra entrada requiere definir el episodio y reconstruir
sus volúmenes; el esquema actual por posición no resuelve por sí solo todos los
ciclos de reversión. Operaciones próximas en el tiempo no se fusionan por compartir
comentario. Los filtros usan fecha de cierre: aperturas previas al periodo siguen
siendo necesarias para calcular los cierres del periodo.

El motor recibe la serie diaria **ya ajustada por flujos externos**. El adaptador
debe validar calendario, zona horaria, días faltantes, hora de corte, duplicados y
cobertura antes de marcar `coverage_complete=true`. Esta marca no puede inventarse
para rellenar días sin datos. Ante depósitos/retiros intradía, calcular retornos
por subperiodos en torno al flujo (TWR) y encadenarlos; no restar arbitrariamente
todo el flujo del cierre diario. El prototipo no contiene ese adaptador aún.

## Activación durante el seminario

1. Mostrar la muestra y explicar operación completa frente a ejecución.
2. Inspeccionar las tablas reales y la cobertura de aperturas, cierres, costes y
   reversiones. Normalizar correctamente la hora del broker a UTC. Excluir y contar
   episodios incompletos; comprobar ejemplos BUY, SELL, parcial e INOUT.
3. Construir el adaptador de operaciones completas usando este contrato. Mantener
   costes monetarios separados del retorno del precio. Agregar sobre **todo el
   filtro**, antes de paginar; conservar las tablas privadas y la proyección pública.
4. Empezar a guardar equity histórica. Definir corte y calendario, capturar flujos,
   construir retornos diarios ajustados y declarar el inicio de la cobertura.
   El estado actual sobrescrito no permite recuperar equity intradía pasada.
5. Conectar las siete métricas por operación. Las tres de cuenta seguirán como
   no disponibles hasta que exista su serie válida, sin usar fixtures como fallback.
6. Adaptar las tarjetas a la aplicación publicada existente. Reutilizar filtros,
   paginación y edición de motivos; mantener consulta del estado cada 30 segundos
   y actualizar estadísticas con el historial, sin descargar todos los trades al móvil.
7. Comparar resultados con cálculos manuales y probar filtros, muestra vacía,
   denominadores cero, parciales, datos incompletos y móvil. Desplegar únicamente
   después de aprobar el resultado concreto. Mantener cierre remoto desactivado.

No hay migraciones aplicadas, nuevas funciones remotas, credenciales ni imports
desde `aplicaciones/web/` hacia este laboratorio. **La integración con datos reales
se realiza durante el seminario**; la demostración local y sus cálculos están listos.

[Volver al dashboard actual](../web/README.md).

[Resultados de verificación local](VERIFICACION.md).
