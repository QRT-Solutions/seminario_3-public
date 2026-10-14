# Módulo 9: Protocolo de Calidad Histórica, Alineación Temporal y Operación Desatendida de Símbolos Personalizados

> **Autor Institucional:** QRT Solutions  
> **Ámbito:** Estándar técnico y matemático para remediación de datos históricos, alineación de marcas temporales, calibración de sesiones RTH y aprovisionamiento 100% desatendido de símbolos personalizados vía MCP en MetaTrader 5.

---

## 1. Diagnóstico Cuantitativo de Calidad Histórica en Strategy Tester

En MetaTrader 5, el Strategy Tester evalúa la cobertura y densidad de la serie temporal mediante el indicador escalar **Calidad de la historia analizada** (`quality of analyzed history is XX%`), registrado en el diario del tester (`get_tester_journal`).

### 1.1. Las Dos Causas Raíz de la Degradación al 57%

La auditoría forense formal realizada sobre el activo `QQQ` (In-Sample 2005–2021) demostró empíricamente que una lectura de 57% **no es un defecto de la fuente original de datos**, sino la superposición de dos errores de configuración e ingesta:

```
┌────────────────────────────────────────────────────────────────────────┐
│ ERROR 1: MISMATCH DE SESIONES 24/7 vs RTH                              │
│ • La serie inyectada sólo contiene horario regular (390 min/día).     │
│ • El símbolo se configuró forzando 00:00 a 24:00 los 7 días (24/7).   │
│ • MT5 penaliza los 1.050 min/día de noche y los fines de semana       │
│   como "datos ausentes", reduciendo la cobertura teórica al 27.1%.     │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ ERROR 2: INVERSIÓN DE MARCA TEMPORAL (BAR CLOSE vs BAR OPEN)           │
│ • TradeStation WebAPI v3 etiqueta las barras en BAR CLOSE.             │
│ • MetaTrader 5 exige marcas temporales en BAR OPEN.                    │
│ • Omitir la resta de 1 minuto desplaza la serie +1m hacia el futuro,  │
│   ingiere 4.264 barras de pre-market y descarta 4.251 de cierre.       │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ RESULTADO: DEGRADACIÓN HISTÓRICA AL 57% EN EL STRATEGY TESTER          │
└────────────────────────────────────────────────────────────────────────┘
```

### 1.2. El Salto Empírico Demostrado: De 57% a 99%
Al corregir ambas dimensiones de forma simultánea, el Strategy Tester de MT5 registró:
- `CUSTOM_QQQ_M1` (Línea base previa, 24/7, sin desfase -1m): **57% de calidad histórica**.
- `CUSTOM_QQQ_V2_M1` (Piloto reparado, RTH calibrado, con desfase -1m): **99% de calidad histórica**.

---

## 2. Estándar Matemático de Conversión y Sanitización

### 2.1. Fórmula de Mapeo Temporal
Para transformar datos intradiarios de proveedores que estampan al cierre de barra (*Bar Close*, ej. TradeStation) al estándar de inicio de barra (*Bar Open*) de MetaTrader 5 bajo el huso horario de broker Pepperstone (+7 horas constante respecto a New York):

$$T_{\text{MT5}} = (T_{\text{TS}} - 1\text{ minuto}) + 7\text{ horas}$$

* **Apertura de Mercado (09:30:00 ET):**
  - TradeStation emite la barra al cierre del primer minuto: `09:31:00 ET`.
  - Conversión: $(09:31:00 - 1\text{m}) + 7\text{h} = 09:30:00 + 7\text{h} = \mathbf{16:30:00}$ (Broker Time).
* **Cierre de Mercado (16:00:00 ET):**
  - TradeStation emite la barra al cierre del último minuto: `16:00:00 ET`.
  - Conversión: $(16:00:00 - 1\text{m}) + 7\text{h} = 15:59:00 + 7\text{h} = \mathbf{22:59:00}$ (Broker Time).

### 2.2. Ventana de Filtrado RTH
El filtro intradiario en hora local de New York debe configurarse estrictamente como:

$$571 \le \text{MinuteOfDay}_{\text{NY}} \le 960 \quad (09:31 \le T_{\text{local}} \le 16:00)$$

Esto garantiza:
1. **Erradicación del Pre-Market:** La barra `09:30 ET` (minuto 570, que cubre `09:29:00–09:29:59 ET`) queda excluida de la sesión regular.
2. **Inclusión del Cierre Oficial:** La barra `16:00 ET` (minuto 960, que cubre `15:59:00–15:59:59 ET`) queda preservada.
3. **Cardinalidad Estándar:** Exactamente 390 barras de 1 minuto por día bursátil completo.

### 2.3. Reglas de Sanitización Geométrica
Antes de la inyección, toda fila debe cumplir:
1. **Precios Estrictamente Positivos:** $Open > 0, High > 0, Low > 0, Close > 0$.
2. **Envolvente High/Low Coherente:** $High \ge \max(Open, Close)$ y $Low \le \min(Open, Close)$.
3. **Monotonicidad Estricta:** $\text{Epoch}_{i} > \text{Epoch}_{i-1}$ para descartar duplicados de red.
4. **Volúmenes Mínimos:** Si `TotalTicks` está ausente o es 0, forzar `tick_volume = 1` para satisfacer el requisito del Strategy Tester.

---

## 3. Calibración de Sesiones en MQL5 (`CustomSymbolSetSession*`)

Para erradicar la penalización por inactividad y eliminar el error `10018: Market closed`, las sesiones del símbolo personalizado deben coincidir con la presencia real de datos en el huso de broker:

### 3.1. Días de Negociación (Lunes a Viernes)
- Horario de Cotización y Trading: `16:30:00` a `23:00:00`.
- En segundos desde las 00:00:
  $$\text{from\_time} = 16 \times 3600 + 30 \times 60 = 59.400\,\text{s}$$
  $$\text{to\_time} = 23 \times 3600 = 82.800\,\text{s}$$

```mql5
for(int d = 1; d <= 5; d++) // Lunes (1) a Viernes (5)
{
   CustomSymbolSetSessionQuote(custom_name, (ENUM_DAY_OF_WEEK)d, 0, (datetime)59400, (datetime)82800);
   CustomSymbolSetSessionTrade(custom_name, (ENUM_DAY_OF_WEEK)d, 0, (datetime)59400, (datetime)82800);
}
```

### 3.2. Días Inhábiles (Sábado y Domingo)
Para declarar explícitamente el mercado cerrado y que el tester no espere cotizaciones:
```mql5
// Domingo (0) y Sábado (6): Sesiones limpias (from = 0, to = 0)
CustomSymbolSetSessionQuote(custom_name, (ENUM_DAY_OF_WEEK)0, 0, (datetime)0, (datetime)0);
CustomSymbolSetSessionTrade(custom_name, (ENUM_DAY_OF_WEEK)0, 0, (datetime)0, (datetime)0);
CustomSymbolSetSessionQuote(custom_name, (ENUM_DAY_OF_WEEK)6, 0, (datetime)0, (datetime)0);
CustomSymbolSetSessionTrade(custom_name, (ENUM_DAY_OF_WEEK)6, 0, (datetime)0, (datetime)0);
```

---

## 4. Patrón de Aprovisionamiento e Inyección 100% Desatendida vía MCP

En entornos de ejecución autónoma (sin operador humano que arrastre scripts en la interfaz gráfica de MT5), los Asesores Expertos (EAs) y plantillas `.tpl` pueden quedar inactivos si la opción *"Permitir trading algorítmico"* está desactivada en la terminal.

### 4.1. El Canal de Indicadores MCP (Bypass Seguro y Confiable)
A diferencia de los EAs, **los Indicadores Técnicos de MT5 siempre se ejecutan inmediatamente al adjuntarse a un gráfico**, ya que no poseen permisos de trading directo sobre el mercado. Sin embargo, dentro de su función `OnInit()`, un indicador en un gráfico vivo tiene acceso completo a la API de símbolos personalizados:
- `CustomSymbolCreate`
- `CustomSymbolSetInteger`, `CustomSymbolSetDouble`, `CustomSymbolSetString`
- `CustomSymbolSetSessionQuote`, `CustomSymbolSetSessionTrade`
- `CustomRatesReplace` / `CustomRatesUpdate`

### 4.2. Algoritmo de Ejecución Autónomo en 5 Pasos
```
┌────────────────────────────────────────────────────────────────────────┐
│ PASO 1: chart_open                                                     │
│ • Abre un gráfico temporal de anclaje (ej. GOOGL.US en M1).            │
│ • Retorna el chart_id numérico unívoco.                                │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ PASO 2: chart_add_indicator                                            │
│ • Inyecta el indicador compilado (.ex5) en el chart_id.                │
│ • MT5 invoca de inmediato OnInit() en el hilo de la ventana.           │
│ • OnInit() crea el símbolo, fija sesiones e inyecta las barras.        │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ PASO 3: Telemetría y Validación                                        │
│ • Consultar get_expert_journal para verificar el reporte de OnInit().  │
│ • Invocar add_marketwatch_symbol para visibilidad en Market Watch.     │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ PASO 4: chart_close                                                    │
│ • Cierra ordenadamente el gráfico temporal liberando memoria y sockets. │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ PASO 5: Quality Gate en Strategy Tester                                │
│ • Disparar backtest formal de control vía tester_run_backtest.         │
│ • Validar quality of analyzed history >= 95% en get_tester_journal.   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Quality Gate Institucional de Datos

> [!IMPORTANT]
> **Compuerta de Calidad Mandatoria ($\ge 95\%$):**
> Queda terminantemente prohibido certificar estrategias, calibrar stops o realizar optimizaciones paramétricas sobre cualquier activo cuya calidad histórica en el Strategy Tester sea inferior al **95%**.
> Si un activo presenta $<95\%$, el operador debe someterlo obligatoriamente a este protocolo de calibración de sesiones RTH y alineación temporal antes de proseguir con tareas cuantitativas.
