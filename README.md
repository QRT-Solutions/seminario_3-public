# Seminario 3 — Laboratorio cuantitativo e integraciones

> **Autoría institucional:** QRT Solutions  
> **Ámbito:** Continuación y ampliación del Seminario 2. Infraestructura de telemetría MT5, base de datos analítica en la nube, bot de bitácora en Telegram, dashboard en Vercel y laboratorio cuantitativo de estrategias.

> [!IMPORTANT]
> **Aviso de Alcance Prioritario (Preparación Pública):**  
> Por directiva del propietario, **Seminario 2 se conserva como la BASE integral de este repositorio** (presentación masterclass, catálogo de 17 estrategias y bibliografía se conservan, sujetos a saneamiento futuro de narrativas y revisión independiente de derechos). La entrega pública final mantiene la prohibición estricta de incluir **datos de transacciones** (reales, sintéticas o simuladas) y resultados de cuentas, quedando los fixtures transaccionales del laboratorio KPI (`fixture.json` y el bundle de datos de `preview.html`) fuera de la entrega distribuible. Consulta la matriz de saneamiento y el alcance en [seminario_3/ALCANCE_SIN_DATOS.md](seminario_3/ALCANCE_SIN_DATOS.md). Los textos y guías previas se preservan en este espacio como referencia histórica y técnica en desarrollo.

---

## 1. Propósito y elección de ruta de aprendizaje

Este proyecto continúa el Seminario 2 y amplía el laboratorio algorítmico institucional. Permite transformar operaciones de trading en una **bitácora cuantitativa conectada**: tu terminal de MetaTrader 5 transmite telemetría hacia Supabase, un bot de Telegram solicita las razones de cada apertura o cierre, y un panel web en Vercel calcula tus indicadores de rendimiento (KPIs) y distribuciones estadísticas en tiempo real.

Para comenzar, elige la ruta que mejor se adapte a tu nivel y objetivo:

```text
┌─────────────────────────────────────────────────────────────────────────────────┐
│ RUTA 1: INTRODUCTORIA (SIN CREDENCIALES)                                        │
│ • Para alumnos que se inician o desean explorar inmediatamente la interfaz.     │
│ • Abre directamente preview.html en tu navegador. Cero claves ni configuración. │
│ • Explora los 10 KPIs y curvas de retorno sobre una muestra simulada.           │
│ 👉 Guía: seminario_3/guias/EMPIEZA_AQUI.md                                      │
└────────────────────────────────────────┬────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│ RUTA 2: TÉCNICA COMPLETA (MT5 + SUPABASE + TELEGRAM + VERCEL)                   │
│ • Para conectar tu propia cuenta demo de MT5 y desplegar la nube personal.      │
│ • Esquema SQL, Edge Functions, webhook de Telegram y dashboard de producción.   │
│ 👉 Guía: seminario_3/guias/README.md · Prompt: seminario_3/guias/PROMPT_AGENTE.md│
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Requisitos por ruta

| Componente / Herramienta | Ruta Introductoria | Ruta Técnica Completa |
|---|:---:|:---:|
| **Navegador web moderno** (Chrome, Safari, Firefox, Edge) | **Obligatorio** | **Obligatorio** |
| **Python** (servidor local opcional) | Opcional (3.12+) | CPython 3.12 exacto |
| **Gestor uv y Git** | No requerido | **Obligatorio** (`uv sync --locked`) |
| **Node.js (22.19+) y npm** | No requerido | **Obligatorio** (pruebas y build web) |
| **MetaTrader 5 y MetaEditor** | No requerido | **Obligatorio** (cuenta demo + compilador) |
| **Cuentas en la nube** (Supabase, Telegram, Vercel) | **Ninguna** | **Propias del alumno** (revisar planes y condiciones vigentes) |

---

## 3. Primer ejercicio inmediato (Ruta Introductoria)

No necesitas instalar dependencias pesadas ni registrar servicios para tu primera práctica:

1. **Abre el archivo:** Navega en tu explorador de archivos a [`seminario_3/aplicaciones/kpi-laboratorio/preview.html`](seminario_3/aplicaciones/kpi-laboratorio/preview.html) y haz doble clic sobre él.
2. **Alternativa con servidor local (si tu navegador restringe archivos locales):**
   ```bash
   python3 -m http.server 4188 --bind 127.0.0.1 --directory seminario_3/aplicaciones/kpi-laboratorio
   ```
   Y abre en tu navegador: `http://127.0.0.1:4188/preview.html`.
3. **Explora:** Filtra por periodos (*40 sesiones, 20 sesiones, 5 sesiones, sin datos*), símbolos y dirección (*Compras, Ventas*). Observa el cálculo dinámico de la tasa de acierto, Profit Factor %, Payoff Ratio %, Sharpe, Sortino, Drawdown y racha máxima de pérdidas.

> [!IMPORTANT]
> **Distinción entre muestra simulada y datos reales:**  
> El laboratorio `preview.html` es un prototipo local independiente (React) que contiene **48 operaciones analizables, una incompleta excluida y 40 retornos diarios ficticios** de prueba educativa. No representa el saldo ni las órdenes de tu cuenta de trading. La aplicación web final de producción (`seminario_3/aplicaciones/web/`) es una implementación independiente en **Vanilla HTML/CSS/JavaScript + Chart.js** conectada a funciones RPC en Supabase con lectura pública optativa y edición restringida de motivos.

---

## 4. Mapa del repositorio

```text
seminario_3-public/
├── seminario_3/                      # Módulo principal del Seminario 3
│   ├── guias/                        # Documentación paso a paso para alumnos
│   │   ├── EMPIEZA_AQUI.md           # Primer ejercicio guiado (sin credenciales)
│   │   ├── README.md                 # Guía técnica completa de instalación
│   │   ├── RESUMEN_CONFIGURACION.md  # Resumen rápido de parámetros
│   │   └── PROMPT_AGENTE.md          # Instrucciones para tu asistente de IA
│   ├── aplicaciones/
│   │   ├── kpi-laboratorio/          # preview.html, motor de 10 KPIs y fixtures (React)
│   │   └── web/                      # Dashboard web en Vanilla HTML/CSS/JS + Chart.js y editor
│   ├── supabase/                     # 12 referencias SQL, 3 Edge Functions y receptor
│   ├── integraciones/                # Guías técnicas para MetaTrader 5 y Telegram
│   ├── ESTADO.md                     # Evidencias observadas y límites funcionales
│   └── ENTREGA.md                    # Checklist de publicación y propiedad intelectual
├── MT5/                              # Exportador EA v3.40, scripts M1 y formación
│   ├── MT5_Telemetry_Exporter_Universal.mq5 # Código fuente del exportador institucional
│   └── GUIA_100_PREGUNTAS_TRADING_CUANTITATIVO.md # 100 preguntas científicas (4 pilares)
├── quant_agentic_swarm/strategies/   # Catálogo canónico de 17 estrategias institucionales
├── masterclass/                      # Presentación interactiva y guion del Seminario 2
├── docs/                             # Arquitectura, metodología, validación y glosario
└── tools/                            # Scripts de verificación de enlaces y publicación
```

---

## 5. Estado honesto de la versión y evidencias

El repositorio separa con rigor lo que está disponible en el código, lo probado en el entorno docente histórico y lo que cada alumno debe verificar en su propia máquina:

- **Exportador EA v3.40:** El código fuente oficial en [`MT5/MT5_Telemetry_Exporter_Universal.mq5`](MT5/MT5_Telemetry_Exporter_Universal.mq5) corresponde a la **versión 3.40**. En el entorno docente se verificó compilación nativa limpia (0 errores, 0 advertencias) y recepción de snapshots e historial en Supabase. No obstante, **estas evidencias son históricas**: cada alumno debe compilar el EA y comprobar la recepción HTTP 200 en su propia instalación.
- **Edición web y bot de Telegram:** El código de las tres Edge Functions (`mt5-telemetry`, `mt5-telegram`, `mt5-dashboard-editor`) y las suites de pruebas unitarias asociadas cuentan con validación local (Node.js) y pruebas SQL con `ROLLBACK`. El primer inicio de sesión real en producción del alumno debe confirmarse al desplegar su proyecto.
- **Estado de distribución Git:** Esta copia de trabajo contiene todo el material preparado localmente. El remoto Git configurado continúa apuntando a la base del Seminario 2; **el destino remoto definitivo para el Seminario 3 está pendiente de confirmación por el propietario** (no se han inventado URLs remotas ni ejecutado `git push`). Consulta [seminario_3/ENTREGA.md](seminario_3/ENTREGA.md).

---

## 6. Base heredada del Seminario 2 — Diseño y validación de estrategias

El Seminario 3 conserva íntegramente todo el material metodológico y técnico del Seminario 2:

* [English overview](README.en.md) · [Ruta docente](docs/start.md) · [Catálogo de 17 estrategias](docs/strategies.md) · [Arquitectura](docs/architecture.md) · [Contribuir](CONTRIBUTING.md).

> 🚀 **Actualización Institucional v2.0 (Pepperstone Latam & QRT Solutions):**  
> Incorporamos el **Agente Educador Cuantitativo (`QuantEducatorAgent`)**, la [**Guía Canónica de 100 Preguntas Científicas**](MT5/GUIA_100_PREGUNTAS_TRADING_CUANTITATIVO.md) en 4 pilares, herramientas para [**Inyección de 20+ Años M1 y Desbloqueo 24/7**](MT5/DATA_INJECTION_GUIDE.md) (solución a error 10018), y el manual de [**Auditoría de Backtesting en 3 Módulos**](MT5/BACKTEST_AUDIT_MANUAL.md).  
> 👉 Alumnos con ChatGPT/Claude Web o IDEs: consulta las [**Instrucciones del Sistema de IA**](INSTRUCCIONES_SISTEMA_CREADOR_BOTS_IA.md).

### Verificación local del catálogo

Desde la raíz del repositorio, utilizando Git, [uv](https://docs.astral.sh/uv/getting-started/installation/) y CPython 3.12:

```sh
uv run --locked --no-dev seminario doctor
uv run --locked --no-dev seminario verify
uv run --locked --no-dev seminario quickstart
```

La verificación de esquemas e integridad del catálogo no requiere datos de mercado ni credenciales. Abre [`masterclass/index.html`](masterclass/index.html) para ver la presentación interactiva del Seminario 2 sin necesidad de servidores externos.

---

## 7. Licencia, avisos y base de conocimientos

- **Autoría:** **QRT Solutions**. Material original bajo licencia [MIT](LICENSE).
- **Avisos legales y de terceros:** Consulta [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md), [SECURITY.md](SECURITY.md) y [CHANGELOG.md](CHANGELOG.md).
- **Base de conocimientos para agentes:** Ubicada en [base_de_conocimientos](https://github.com/QRT-Solutions/seminario_2-public/tree/main/base_de_conocimientos) con índice semántico en [LLM_INDEX.md](https://github.com/QRT-Solutions/seminario_2-public/tree/main/base_de_conocimientos/LLM_INDEX.md). Consulta las directivas de propiedad intelectual en [seminario_3/ENTREGA.md](seminario_3/ENTREGA.md).
