# Seminar 3 — Quantitative laboratory and integrations

Author: QRT Solutions.

> [!IMPORTANT]
> **Priority Scope Notice (Public Release Preparation):**  
> Per owner directive, **Seminar 2 is preserved as the foundation of this repository** (interactive masterclass, 17-strategy catalog, and knowledge base are retained, subject to future narrative sanitization and independent copyright review). The public release strictly prohibits including **transaction data** (real, synthetic, or simulated) and measured account results, with KPI lab fixtures (`fixture.json` and embedded data in `preview.html`) excluded from the distributed package. See the full scope matrix in [seminario_3/ALCANCE_SIN_DATOS.md](seminario_3/ALCANCE_SIN_DATOS.md). Previous guides and materials are preserved in this workspace as development and historical reference.

This repository builds on Seminar 2. Choose your learning path:

1. **Introductory Path (No credentials required):** Explore the local simulated 10-KPI laboratory ([`seminario_3/aplicaciones/kpi-laboratorio/preview.html`](seminario_3/aplicaciones/kpi-laboratorio/preview.html)) directly in your browser. See [Empieza aquí (Start here)](seminario_3/guias/EMPIEZA_AQUI.md).
2. **Full Technical Path:** Connect MT5 telemetry to Supabase, Telegram bot prompts for trade reasoning, and an optional public reading dashboard with restricted web editing. See the [complete student guide](seminario_3/guias/README.md) and [agent handoff prompt](seminario_3/guias/PROMPT_AGENTE.md) (in Spanish).

Each student uses their own demo account, projects and bot (checking current provider terms and plans). See the [version and evidence register](seminario_3/ESTADO.md): current source EA in [`MT5/MT5_Telemetry_Exporter_Universal.mq5`](MT5/MT5_Telemetry_Exporter_Universal.mq5) is **v3.40**. Recorded compiler diagnostics (0 errors, 0 warnings) and telemetry reception belong to historical teacher tests; students must compile and verify in their own setup. Web editing and Telegram functions have local Node.js and SQL test validation. These additions are staged locally; the remote Git destination is pending review by the repository owner (no remote URL has been invented; see [handoff](seminario_3/ENTREGA.md)).

Turn a market idea into an explicit hypothesis, a reviewable contract and source
code that others can inspect. [Español](README.md) · [Start here](docs/quickstart.en.md) · [Catalog](docs/strategies.md) · [Contribute](CONTRIBUTING.md)

> 🚀 **Institutional Update v2.0 (Pepperstone Latam & QRT Solutions):**  
> Introducing the **Quantitative Educator Agent (`QuantEducatorAgent`)**, the [**Canonical Guide of 100 Scientific Questions**](MT5/GUIA_100_PREGUNTAS_TRADING_CUANTITATIVO.md) across 4 pillars, [**20+ Year M1 Data Injection & 24/7 Session Unlock**](MT5/DATA_INJECTION_GUIDE.md) tools (resolving error 10018), and the [**3-Module Backtest Audit Manual**](MT5/BACKTEST_AUDIT_MANUAL.md).  
> 👉 Web chat & IDE students: see the [**AI System Instructions**](INSTRUCCIONES_SISTEMA_CREADOR_BOTS_IA.md).

The Spanish presentation explains hypotheses, entries, exits, sizing and evaluation.
The **17-strategy Pine/MQL5 catalog remains complete**, with canonical sources,
specifications, factsheets and checked deployment copies. Historical datasets and
the six research notebooks are deferred to a future seminar and are not distributed
in this edition.

Requirements: Git, [uv](https://docs.astral.sh/uv/getting-started/installation/) and
CPython 3.12, which uv can install.

```sh
# Run from the seminario_3-public repository root.
uv run --locked --no-dev seminario doctor
uv run --locked --no-dev seminario quickstart
```

No market data, credentials or accounts are required for installation and catalog
verification. Open `masterclass/index.html` to view the offline
presentation. `seminario verify` checks schemas, IDs, paths, artifacts and copies.
Use `seminario --project "PROJECT PATH" verify` outside the project tree.

Optional native compilation and Strategy Tester execution require explicit isolated
workspaces. Source availability, valid contracts, compilation and numeric equivalence
are separate claims. The project does not certify strategy profitability.

Original material: **QRT Solutions**, [MIT](LICENSE). See [third-party notices](THIRD_PARTY_NOTICES.md),
[contributing](CONTRIBUTING.md), [security](SECURITY.md) and [release conditions](docs/release.md).

## Agent knowledge base

The [knowledge base](https://github.com/QRT-Solutions/seminario_2-public/tree/main/base_de_conocimientos) contains 50 Markdown documents, a catalog and an agent
routing index. Start with [LLM_INDEX.md](https://github.com/QRT-Solutions/seminario_2-public/tree/main/base_de_conocimientos/LLM_INDEX.md). Referenced images
are not present in the source folder. Original attribution is preserved.
