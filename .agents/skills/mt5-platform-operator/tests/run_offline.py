#!/usr/bin/env python3
"""
mt5-platform-operator - Offline Test Runner and Validation Suite
QRT Solutions - Technical Platform Operator

Validates:
1. TaskExecutionContract JSON Schema (Draft-07) across all 10 operations (valid & invalid fixtures).
2. Discrimination against bare/synthetic payloads {task_id: "synthetic", operation: op}.
3. ExecutionEvidence JSON Schema (Draft-07) (completed/reused requirements, coherence flags, blocking_reason, query_payload).
4. This runner does NOT test agent recovery, checkpoint atomicity or live MT5 behavior.
5. Strict distinction between executed offline checks and unexecuted live MT5 calls.
"""

import sys
import os
import json


try:
    import jsonschema
    from jsonschema import Draft7Validator
except ImportError as err:
    print(f"FATAL: Instala la dependencia de tests jsonschema en tu entorno Python: {type(err).__name__}")
    sys.exit(1)

SKILL_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTRACT_SCHEMA_PATH = os.path.join(SKILL_ROOT, "assets", "task_execution_contract.schema.json")
EVIDENCE_SCHEMA_PATH = os.path.join(SKILL_ROOT, "assets", "execution_evidence.schema.json")

def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

# Load schemas
contract_schema = load_json(CONTRACT_SCHEMA_PATH)
evidence_schema = load_json(EVIDENCE_SCHEMA_PATH)

Draft7Validator.check_schema(contract_schema)
Draft7Validator.check_schema(evidence_schema)
contract_validator = Draft7Validator(contract_schema)
evidence_validator = Draft7Validator(evidence_schema)

passed_tests = 0
failed_tests = 0

def assert_valid(validator, payload, test_name):
    global passed_tests, failed_tests
    errors = list(validator.iter_errors(payload))
    if not errors:
        print(f"  [PASS] {test_name}")
        passed_tests += 1
        return True
    else:
        print(f"  [FAIL] {test_name}: Validación falló indebidamente:")
        for err in errors:
            print(f"         - {err.message} (path: {list(err.path)})")
        failed_tests += 1
        return False

def assert_invalid(validator, payload, test_name, expected_keyword=None):
    global passed_tests, failed_tests
    errors = list(validator.iter_errors(payload))
    if errors:
        print(f"  [PASS] {test_name} (Rechazado correctamente: {len(errors)} error/es)")
        passed_tests += 1
        return True
    else:
        print(f"  [FAIL] {test_name}: Payload inválido fue aceptado indebidamente!")
        failed_tests += 1
        return False

print("=" * 80)
print("INICIANDO SUITE DE VALIDACIÓN OFFLINE: mt5-platform-operator")
print("Autor Canónico: QRT Solutions")
print("=" * 80)

# ----------------------------------------------------------------------
# BLOQUE 1: TaskExecutionContract - Validación por Operación
# ----------------------------------------------------------------------
print("\n--- BLOQUE 1: Validación de Contratos por Operación ---")

# 1.1 capabilities
assert_valid(contract_validator, {
    "task_id": "TC-CAP-01",
    "operation": "capabilities"
}, "capabilities: payload mínimo válido")

assert_invalid(contract_validator, {
    "task_id": "",
    "operation": "capabilities"
}, "capabilities: rechaza task_id vacío")

# 1.2 query_status
assert_valid(contract_validator, {
    "task_id": "TC-STAT-01",
    "operation": "query_status",
    "run_id": "RUN-TEST-001"
}, "query_status: válido con run_id no vacío")

assert_invalid(contract_validator, {
    "task_id": "TC-STAT-02",
    "operation": "query_status"
}, "query_status: rechaza payload sin run_id")

assert_invalid(contract_validator, {
    "task_id": "TC-STAT-03",
    "operation": "query_status",
    "run_id": ""
}, "query_status: rechaza run_id vacío")

# 1.3 inspect_symbol
assert_valid(contract_validator, {
    "task_id": "TC-SYM-01",
    "operation": "inspect_symbol",
    "symbol": "EURUSD"
}, "inspect_symbol: válido con symbol")

assert_invalid(contract_validator, {
    "task_id": "TC-SYM-02",
    "operation": "inspect_symbol"
}, "inspect_symbol: rechaza payload sin symbol")

assert_invalid(contract_validator, {
    "task_id": "TC-SYM-03",
    "operation": "inspect_symbol",
    "symbol": ""
}, "inspect_symbol: rechaza symbol vacío")

# 1.4 history
assert_valid(contract_validator, {
    "task_id": "TC-HIST-01",
    "operation": "history",
    "target": {
        "symbol": "EURUSD",
        "period": "M15",
        "datetime_from": "2026-01-01T00:00:00Z",
        "datetime_to": "2026-01-02T00:00:00Z"
    }
}, "history: válido con target completo")

assert_valid(contract_validator, {
    "task_id": "TC-HIST-02",
    "operation": "history",
    "symbol": "EURUSD",
    "period": "M15",
    "datetime_from": "2026-01-01T00:00:00Z",
    "datetime_to": "2026-01-02T00:00:00Z"
}, "history: válido con campos a nivel raíz")

assert_invalid(contract_validator, {
    "task_id": "TC-HIST-03",
    "operation": "history"
}, "history: rechaza payload vacío sin target ni campos")

assert_invalid(contract_validator, {
    "task_id": "TC-HIST-04",
    "operation": "history",
    "target": { "symbol": "EURUSD" }
}, "history: rechaza target incompleto sin fechas ni period")

# 1.5 chart
assert_valid(contract_validator, {
    "task_id": "TC-CHART-01",
    "operation": "chart",
    "chart_action": { "action": "list" }
}, "chart: válido list de sólo lectura sin gates de mutación")

assert_valid(contract_validator, {
    "task_id": "TC-CHART-02",
    "operation": "chart",
    "chart_action": { "action": "open", "symbol": "EURUSD", "period": "M15" },
    "gates": { "mutation_approval": True }
}, "chart: open válido con symbol, period y mutation_approval: True")

assert_invalid(contract_validator, {
    "task_id": "TC-CHART-03",
    "operation": "chart",
    "chart_action": { "action": "open", "symbol": "EURUSD", "period": "M15" }
}, "chart: open rechaza si falta gates.mutation_approval")

assert_invalid(contract_validator, {
    "task_id": "TC-CHART-04",
    "operation": "chart",
    "chart_action": { "action": "open" },
    "gates": { "mutation_approval": True }
}, "chart: open rechaza si falta symbol/period")

assert_valid(contract_validator, {
    "task_id": "TC-CHART-05",
    "operation": "chart",
    "chart_action": { "action": "close", "chart_id": "CH-12345" },
    "gates": { "mutation_approval": True }
}, "chart: close válido con chart_id string y mutation_approval")

assert_invalid(contract_validator, {
    "task_id": "TC-CHART-06",
    "operation": "chart",
    "chart_action": { "action": "close" },
    "gates": { "mutation_approval": True }
}, "chart: close rechaza si falta chart_id")

assert_valid(contract_validator, {
    "task_id": "TC-CHART-07",
    "operation": "chart",
    "chart_action": { "action": "apply_template", "chart_id": "CH-12345", "template_filename": "clean.tpl" },
    "gates": { "mutation_approval": True }
}, "chart: apply_template válido con chart_id y template_filename")

assert_valid(contract_validator, {
    "task_id": "TC-CHART-08",
    "operation": "chart",
    "chart_action": { "action": "add_indicator", "chart_id": "CH-12345", "indicator_name": "RSI" },
    "gates": { "mutation_approval": True }
}, "chart: add_indicator válido con chart_id e indicator_name")

# 1.6 compile
assert_valid(contract_validator, {
    "task_id": "TC-COMP-01",
    "operation": "compile",
    "source_path": "Experts/MyEA.mq5",
    "output_path": "Experts/MyEA.ex5",
    "gates": { "mutation_approval": True }
}, "compile: válido con source, output y mutation_approval: True")

assert_invalid(contract_validator, {
    "task_id": "TC-COMP-02",
    "operation": "compile",
    "source_path": "Experts/MyEA.mq5",
    "output_path": "Experts/MyEA.ex5"
}, "compile: rechaza si falta gates.mutation_approval")

assert_invalid(contract_validator, {
    "task_id": "TC-COMP-03",
    "operation": "compile"
}, "compile: rechaza payload vacío")

# 1.7 cancel_run
assert_valid(contract_validator, {
    "task_id": "TC-CANC-01",
    "operation": "cancel_run",
    "run_id": "RUN-TEST-999",
    "gates": { "mutation_approval": True }
}, "cancel_run: válido con run_id y mutation_approval: True")

assert_invalid(contract_validator, {
    "task_id": "TC-CANC-02",
    "operation": "cancel_run",
    "run_id": "RUN-TEST-999"
}, "cancel_run: rechaza si falta gates.mutation_approval")

assert_invalid(contract_validator, {
    "task_id": "TC-CANC-03",
    "operation": "cancel_run",
    "gates": { "mutation_approval": True }
}, "cancel_run: rechaza si falta run_id")

# 1.8 extract_report
assert_valid(contract_validator, {
    "task_id": "TC-REP-01",
    "operation": "extract_report",
    "run_id": "RUN-TEST-001",
    "expected_output": "full_report_xml"
}, "extract_report: válido con run_id y expected_output")

assert_invalid(contract_validator, {
    "task_id": "TC-REP-02",
    "operation": "extract_report"
}, "extract_report: rechaza payload sin run_id ni expected_output")

# 1.9 backtest
valid_backtest_payload = {
    "task_id": "TC-BT-01",
    "operation": "backtest",
    "target": {
        "symbol": "EURUSD",
        "period": "M15",
        "datetime_from": "2020-01-01T00:00:00Z",
        "datetime_to": "2020-12-31T23:59:59Z"
    },
    "artifact": {
        "expert_path": "Experts\\ExpertPlaceholder.ex5",
        "inputs_path": "Profiles\\Tester\\inputs.set"
    },
    "tester_parameters": {
        "model": "m1 ohlc",
        "deposit": 10000.0,
        "currency": "USD",
        "leverage": 20,
        "execution_delay": 0
    },
    "gates": {
        "study_approval": True,
        "allow_oos": False,
        "quality_gate": {
            "min_quality_pct": 50.0,
            "reject_uninterpretable": True
        }
    },
    "expected_output": "full_report_xml"
}
assert_valid(contract_validator, valid_backtest_payload, "backtest: válido con configuración completa y gates")

assert_invalid(contract_validator, {
    "task_id": "TC-BT-02",
    "operation": "backtest"
}, "backtest: rechaza payload bare sin configuración")

invalid_bt_no_study = json.loads(json.dumps(valid_backtest_payload))
invalid_bt_no_study["gates"]["study_approval"] = False
assert_invalid(contract_validator, invalid_bt_no_study, "backtest: rechaza si gates.study_approval es False")

invalid_bt_no_qgate = json.loads(json.dumps(valid_backtest_payload))
del invalid_bt_no_qgate["gates"]["quality_gate"]
assert_invalid(contract_validator, invalid_bt_no_qgate, "backtest: rechaza si falta quality_gate")

# 1.10 optimization
valid_opt_payload = json.loads(json.dumps(valid_backtest_payload))
valid_opt_payload["operation"] = "optimization"
valid_opt_payload["tester_parameters"]["optimization"] = True
valid_opt_payload["tester_parameters"]["optimization_criterion"] = "sharpe_ratio_max"
valid_opt_payload["tester_parameters"]["optimization_ranges"] = {
    "InpPeriod": { "start": 10, "step": 5, "stop": 50 }
}
assert_valid(contract_validator, valid_opt_payload, "optimization: válido con rangos fijados por quant")

# 1.11 Prueba exhaustiva de discriminación contra bare/synthetic payloads:
print("\n--- 1.11 Prueba de rechazo de bare payloads {task_id: 'synthetic', operation: op} ---")
ops_requiring_fields = [
    "query_status",
    "inspect_symbol",
    "history",
    "chart",
    "compile",
    "cancel_run",
    "extract_report",
    "backtest",
    "optimization"
]
for op in ops_requiring_fields:
    bare_payload = {"task_id": "synthetic", "operation": op}
    assert_invalid(contract_validator, bare_payload, f"Rechazo de bare payload para operación '{op}'")

# ----------------------------------------------------------------------
# BLOQUE 2: ExecutionEvidence - Validación de Evidencia de Ejecución
# ----------------------------------------------------------------------
print("\n--- BLOQUE 2: Validación de ExecutionEvidence ---")

# 2.1 Backtest completado válido con run_id, huella, configuración y reporte
valid_evidence_completed = {
    "task_id": "TC-EV-01",
    "operation": "backtest",
    "status": "completed",
    "reused_cached_result": False,
    "run_id": "RUN-VALID-12345",
    "effective_fingerprint": "a" * 64,
    "execution_metadata": {
        "timestamp_utc": "2026-09-19T13:00:00Z",
        "terminal_time_local": "2026-09-19 16:00:00",
        "elapsed_seconds": 12.5
    },
    "effective_configuration": {
        "model": "m1 ohlc",
        "deposit": 10000.0,
        "currency": "USD",
        "leverage": 20,
        "execution_delay": 0
    },
    "raw_metrics": {
        "net_profit": 1500.0,
        "profit_factor": 1.75
    },
    "artifacts": {
        "report_path": "Files/report_TC-EV-01.xml"
    },
    "limitations_encountered": []
}
assert_valid(evidence_validator, valid_evidence_completed, "evidence: backtest completed válido con artefactos completos")

# 2.2 Backtest completado inválido: falta run_id o artefactos (el caso señalado en auditoría)
invalid_evidence_no_run_id = json.loads(json.dumps(valid_evidence_completed))
invalid_evidence_no_run_id["run_id"] = None
assert_invalid(evidence_validator, invalid_evidence_no_run_id, "evidence: rechaza backtest completed con run_id null")

invalid_evidence_no_artifacts = json.loads(json.dumps(valid_evidence_completed))
invalid_evidence_no_artifacts["artifacts"] = None
assert_invalid(evidence_validator, invalid_evidence_no_artifacts, "evidence: rechaza backtest completed sin artifacts")

invalid_evidence_no_config = json.loads(json.dumps(valid_evidence_completed))
invalid_evidence_no_config["effective_configuration"] = None
assert_invalid(evidence_validator, invalid_evidence_no_config, "evidence: rechaza backtest completed sin effective_configuration")

# 2.3 Coherencia status: reused exige reused_cached_result: True
valid_evidence_reused = json.loads(json.dumps(valid_evidence_completed))
valid_evidence_reused["status"] = "reused"
valid_evidence_reused["reused_cached_result"] = True
assert_valid(evidence_validator, valid_evidence_reused, "evidence: status reused con reused_cached_result: True es válido")

invalid_evidence_reused_flag = json.loads(json.dumps(valid_evidence_reused))
invalid_evidence_reused_flag["reused_cached_result"] = False
assert_invalid(evidence_validator, invalid_evidence_reused_flag, "evidence: rechaza status reused si reused_cached_result es False")

invalid_evidence_completed_flag = json.loads(json.dumps(valid_evidence_completed))
invalid_evidence_completed_flag["reused_cached_result"] = True
assert_invalid(evidence_validator, invalid_evidence_completed_flag, "evidence: rechaza status completed si reused_cached_result es True")

# 2.4 Status blocked / unsupported / uncertain exige blocking_reason
valid_evidence_blocked = {
    "task_id": "TC-EV-BLOCKED-01",
    "operation": "backtest",
    "status": "blocked",
    "reused_cached_result": False,
    "execution_metadata": { "timestamp_utc": "2026-09-19T13:00:00Z" },
    "blocking_reason": "study_approval_missing",
    "limitations_encountered": ["unauthorized_study"]
}
assert_valid(evidence_validator, valid_evidence_blocked, "evidence: blocked válido con blocking_reason")

invalid_evidence_blocked_no_reason = {
    "task_id": "TC-EV-BLOCKED-02",
    "operation": "backtest",
    "status": "blocked",
    "reused_cached_result": False,
    "execution_metadata": { "timestamp_utc": "2026-09-19T13:00:00Z" },
    "limitations_encountered": []
}
assert_invalid(evidence_validator, invalid_evidence_blocked_no_reason, "evidence: rechaza status blocked sin blocking_reason")

# 2.5 Consultas de solo lectura con query_payload
valid_query_evidence = {
    "task_id": "TC-EV-QRY-01",
    "operation": "inspect_symbol",
    "status": "completed",
    "reused_cached_result": False,
    "execution_metadata": { "timestamp_utc": "2026-09-19T13:00:00Z" },
    "query_payload": {
        "symbol": "EURUSD",
        "digits": 5,
        "spread": 10
    },
    "limitations_encountered": []
}
assert_valid(evidence_validator, valid_query_evidence, "evidence: consulta inspect_symbol con query_payload")

# Additional regression cases from independent review. Fixtures are synthetic.
import copy
for field in ["optimization_ranges", "optimization_criterion", "optimization"]:
    bad = copy.deepcopy(valid_opt_payload)
    del bad["tester_parameters"][field]
    assert_invalid(contract_validator, bad, "optimization: falta " + field)
bad = copy.deepcopy(valid_opt_payload)
bad["tester_parameters"]["optimization_ranges"] = {}
assert_invalid(contract_validator, bad, "optimization: rangos vacíos")
bad = copy.deepcopy(valid_opt_payload)
bad["tester_parameters"]["optimization_ranges"]["InpPeriod"]["step"] = 0
assert_invalid(contract_validator, bad, "optimization: paso cero")
bad = copy.deepcopy(valid_backtest_payload)
del bad["tester_parameters"]["execution_delay"]
assert_invalid(contract_validator, bad, "backtest: falta retardo explícito")
bad = copy.deepcopy(valid_backtest_payload)
bad["tester_parameters"]["execution_delay"] = -1
assert_valid(contract_validator, bad, "backtest: retardo aleatorio admitido")
bad = copy.deepcopy(valid_evidence_completed)
bad["effective_configuration"] = {}
assert_invalid(evidence_validator, bad, "evidence: configuración vacía")
bad = copy.deepcopy(valid_evidence_completed)
bad["effective_fingerprint"] = "not-a-hash"
assert_invalid(evidence_validator, bad, "evidence: huella no SHA256")
bad = copy.deepcopy(valid_query_evidence)
del bad["query_payload"]
assert_invalid(evidence_validator, bad, "evidence: consulta sin payload")
bad = copy.deepcopy(valid_evidence_blocked)
bad["reused_cached_result"] = True
assert_invalid(evidence_validator, bad, "evidence: bloqueo no puede certificar reutilización")

# ----------------------------------------------------------------------
# RESUMEN Y TRANSPARENCIA EPISTÉMICA
# ----------------------------------------------------------------------
print("\n" + "=" * 80)
print(f"RESULTADOS GLOBALES: {passed_tests} PASADOS | {failed_tests} FALLADOS")
print("=" * 80)
print("\n[TRANSPARENCIA EPISTÉMICA Y CONTROL OPERATIVO]")
print("1. Resultado de contratos y esquemas: consultar recuento y código de salida arriba.")
print("2. Recuperación del agente, persistencia atómica y descubrimiento en sesión nueva: NO PROBADOS.")
print("3. Comportamiento en Vivo contra Terminal MT5 (Nivel 3): NO EJECUTADO (CERO LLAMADAS A MT5/MCP).")
print("   Tal como se exigió en el protocolo, no se dispararon backtests vivos ni llamadas al terminal.")
print("=" * 80)

if failed_tests > 0:
    sys.exit(1)
else:
    sys.exit(0)
