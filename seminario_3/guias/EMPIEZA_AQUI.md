# Empieza aquí — Tu primer ejercicio en el Seminario 3

> **Autoría institucional:** QRT Solutions  
> **Ámbito:** Guía de inicio rápido para alumnos del Seminario 3 (sin conocimientos previos de programación).  
> **Requisitos para este ejercicio:** Un navegador web moderno (Chrome, Safari, Firefox o Edge). **Cero claves, sin MetaTrader 5 y sin servicios en la nube.**

> [!IMPORTANT]
> **Aviso de Alcance Prioritario (Preparación Pública):**  
> Por directiva del propietario, **Seminario 2 se conserva como la BASE integral de este repositorio**. La entrega pública final prohíbe estrictamente la distribución de **datos de transacciones** (reales, sintéticas o simuladas) y resultados de cuentas, por lo que los fixtures transaccionales del laboratorio local (`fixture.json` y el bundle de datos embebidos de `preview.html`) quedan fuera de la entrega distribuible. Esta guía y los archivos del laboratorio se conservan en el entorno de desarrollo como referencia conceptual e histórica mientras se sanea el contenido. Consulta la matriz de saneamiento y el alcance en [ALCANCE_SIN_DATOS.md](../ALCANCE_SIN_DATOS.md).

---

## 1. Bienvenido al Seminario 3

Si acabas de descargar o clonar este repositorio y no tienes experiencia previa programando, **estás en el lugar correcto**.

El objetivo de este proyecto es enseñarte a construir una **bitácora cuantitativa institucional**: una arquitectura donde tu terminal de MetaTrader 5 envía telemetría de operaciones a una base de datos analítica (Supabase), un bot de Telegram te consulta las razones de cada decisión de trading, y una aplicación web (desplegada opcionalmente en Vercel) ofrece **lectura pública optativa** y **edición restringida de motivos** para el propietario.

Para que puedas experimentar inmediatamente la visualización y análisis de métricas antes de configurar servicios en la nube o tocar código, hemos preparado un **laboratorio visual de diez KPIs (Indicadores Clave de Rendimiento)** listo para usar.

---

## 2. Tu primer ejercicio: El Laboratorio de diez KPIs simulado

Este ejercicio te permite explorar la interfaz estadística local que sirve de referencia conceptual. Funciona de manera 100% autónoma en tu computadora local sin conexión a Internet ni bases de datos.

### Opción A: Apertura directa en tu navegador (Recomendada para empezar)

1. Abre el explorador de archivos de tu sistema operativo:
   * **En macOS (Finder):** Navega hasta la carpeta del proyecto y entra a:
     `seminario_3` → `aplicaciones` → `kpi-laboratorio`.
   * **En Windows (Explorador de archivos):** Navega hasta:
     `seminario_3\aplicaciones\kpi-laboratorio`.
2. Localiza el archivo llamado **`preview.html`**.
3. Haz **doble clic** sobre `preview.html` (o clic derecho → *Abrir con* → tu navegador preferido: Google Chrome, Safari, Firefox o Microsoft Edge).
4. El laboratorio interactivo se abrirá en tu navegador.

---

### Opción B: Servidor local ligero con dirección de enlace explícita

Algunos navegadores con directivas de seguridad locales restringen la carga de recursos empaquetados al abrir archivos directamente desde disco (`file://`). Si tu navegador muestra una página en blanco o prefieres un servidor local estándar:

1. Abre tu terminal de línea de comandos:
   * **macOS:** Abre la aplicación **Terminal** (`Cmd + Espacio`, escribe `Terminal` y presiona Enter).
   * **Windows:** Abre **PowerShell** o **Terminal de Windows** (`Tecla Windows`, escribe `PowerShell` y presiona Enter).
2. Posiciónate en la carpeta raíz del repositorio:
   ```bash
   # En macOS / Linux:
   cd /ruta/hacia/seminario_3-public

   # En Windows:
   cd C:\ruta\hacia\seminario_3-public
   ```
3. Ejecuta el servidor HTTP incorporado en Python enlazando expresamente a la interfaz local `127.0.0.1`:
   * **En macOS / Linux:**
     ```bash
     python3 -m http.server 4188 --bind 127.0.0.1 --directory seminario_3/aplicaciones/kpi-laboratorio
     ```
   * **En Windows:**
     ```powershell
     python -m http.server 4188 --bind 127.0.0.1 --directory seminario_3/aplicaciones/kpi-laboratorio
     ```
4. Abre tu navegador web y escribe la siguiente dirección:
   ```text
   http://127.0.0.1:4188/preview.html
   ```
5. Para detener el servidor cuando termines, regresa a tu terminal y presiona `Ctrl + C`.

---

## 3. Qué estás viendo y cómo interactuar con el laboratorio

El archivo `preview.html` es un prototipo interactivo desarrollado en React para demostración educativa. Al abrirlo observarás:

### A. Barra de controles y filtros
* **Periodo:** Selector con opciones para `40 sesiones` (muestra completa), `Últimas 20 sesiones`, `Últimas 5 sesiones` y `Periodo sin datos` (para observar cómo reacciona el sistema ante periodos vacíos).
* **Símbolo · operaciones:** Filtra operaciones por pares individuales (ej. `EURUSD`, `GBPUSD`...) o `Todos`.
* **Dirección · operaciones:** Filtra por `Todas`, `Compras` (BUY) o `Ventas` (SELL).
* **Botón Restablecer:** Devuelve todos los selectores a sus valores iniciales.

### B. Estadísticas por operación (7 KPIs)
Calculadas sobre el retorno del precio, sin apalancamiento ni costes:
1. **Tasa de acierto (Win Rate):** Porcentaje de operaciones ganadoras sobre el total de operaciones analizables (incluye neutras).
2. **Profit Factor %:** Cociente entre la suma de retornos positivos y el valor absoluto de retornos negativos.
3. **Payoff Ratio %:** Relación entre el retorno medio positivo y el valor absoluto del retorno medio negativo.
4. **Expectativa por trade:** Media aritmética observada de los retornos de esta muestra simulada (describe el promedio histórico de la muestra, sin constituir promesa ni proyección de retornos futuros).
5. **Mediana del retorno:** Retorno de la operación central que separa la mitad superior e inferior.
6. **Desviación estándar:** Medida de dispersión muestral de los retornos respecto a la media.
7. **Máxima racha de pérdidas:** Secuencia más larga observada de operaciones consecutivas con retorno negativo.

### C. Estadísticas de la cuenta (3 KPIs)
Calculadas sobre una serie diaria simulada de 40 sesiones independiente de las operaciones individuales:
8. **Drawdown máximo:** Mayor caída porcentual acumulada desde un máximo previo en la serie diaria ajustada.
9. **Sharpe anualizado:** Relación entre el exceso de retorno diario y su desviación típica, anualizado a 252 sesiones con tasa libre de riesgo de 0%.
10. **Sortino anualizado:** Rendimiento ajustado únicamente por las desviaciones a la baja respecto a un objetivo del 0%.

### D. Gráficos y tablas de evidencia
* **Gráfico de Retorno acumulado:** Curva porcentual de la cuenta simulada a lo largo de las sesiones.
* **Gráfico de Drawdown (%):** Curva de caídas porcentuales desde máximos previos.
* **Tabla Compras frente a ventas:** Desglose comparativo de acierto, retorno medio y factor entre posiciones largas y cortas.
* **Tabla de Operaciones simuladas analizadas:** Registro detallado de cada operación con su ID, fecha de cierre UTC, símbolo, dirección y retorno del precio.

---

## 4. Distinción crucial: Muestra simulada vs Producción en la nube

> [!IMPORTANT]
> **Datos simulados e independencia de implementaciones:**
> 
> 1. **Composición de la muestra:** El laboratorio `preview.html` contiene exactamente **48 operaciones analizables, una incompleta excluida y 40 retornos diarios ficticios**. No corresponde a la base de 108 operaciones que se utilizó en la demostración real del docente ni representa el saldo de tu cuenta.
> 2. **Motores independientes:** Este laboratorio es un **prototipo educativo local** implementado en React para ejercitar conceptos estadísticos. La aplicación web final de producción (`seminario_3/aplicaciones/web/`) es una implementación independiente en **Vanilla HTML/CSS/JavaScript y Chart.js** que consume funciones RPC de Supabase (`mt5_public_dashboard_kpis` y `mt5_public_dashboard_page`).

---

## 5. Tabla de requisitos por nivel de aprendizaje

Avanza paso a paso según lo que quieras realizar:

| Nivel de aprendizaje | Herramientas necesarias | Para qué se utiliza | ¿Requiere claves o cuentas? |
|---|---|---|:---:|
| **Nivel 1: Visual / Conceptual (Hoy)** | Navegador web moderno (Chrome, Safari, Firefox, Edge) | Ver e interactuar con el laboratorio de 10 KPIs (`preview.html`) y leer la documentación | **No** |
| **Nivel 2: Servidor local básico** | Python 3.12+ compatible en tu sistema operativo | Servir páginas web locales mediante `http.server --bind 127.0.0.1` | **No** |
| **Nivel 3: Laboratorio cuantitativo** | CPython 3.12 exacto y gestor de paquetes `uv` | Ejecutar verificaciones automáticas del catálogo de estrategias (`seminario verify`) | **No** |
| **Nivel 4: Ruta técnica completa** | Node.js 22.19+, MetaTrader 5 y cuentas propias en la nube | Conectar tu terminal MT5, capturar eventos, recibir alertas en Telegram y publicar tu dashboard en Vercel | **Sí** (cuentas propias del alumno; revisar planes y condiciones de cada proveedor) |

---

## 6. Siguientes pasos: Hacia la conexión real de tu cuenta

Ahora que conoces la interfaz y comprendes las métricas estadísticas del sistema, elige tu siguiente paso:

* Para explorar el diseño, contratos y código de las 17 estrategias cuantitativas heredadas del Seminario 2, consulta el [README principal](../../README.md).
* Para desplegar la infraestructura completa conectando tu propia cuenta demo de MetaTrader 5 a Supabase, Telegram y Vercel, continúa con la:
  👉 **[Guía completa del alumno](README.md)**.
* Si prefieres que un Asistente de IA (Codex, Claude Code o Google Antigravity) te guíe paso a paso en la terminal, utiliza el:
  👉 **[Mensaje preparado para tu agente (Prompt)](PROMPT_AGENTE.md)**.
