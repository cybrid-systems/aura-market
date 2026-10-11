#!/usr/bin/env bash
# Simulated research risk gate. Not a live limit.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/out"

echo "smoke: risk"
bash "$ROOT/scripts/run_soft.sh" /workspace/aura-market/soft/market/risk_sim.aura \
  >"$ROOT/out/risk_sim.txt" 2>"$ROOT/out/risk_sim.err"
cat "$ROOT/out/risk_sim.txt"
if [[ -s "$ROOT/out/risk_sim.err" ]]; then
  cat "$ROOT/out/risk_sim.err" >&2
fi
fail=0
grep -q 'SIM risk not-a-limit' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'M0_WIDE=18 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'RISK_INV_MAX=6 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'RISK_LOSS_MAX=60 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'R1_RAW=24 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'R1_INV=9 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'R1_PEN=67 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'R1_TAG=risk-inv OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'R1_PACK=2,2,0 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'R2_RAW=28 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'R2_INV=5 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'R2_PEN=61 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'R2_TAG=risk-loss OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'R2_PACK=3,6,0 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'R3_BASE=18 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'R3_RAW=36 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'R3_INV=6 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'R3_PEN=58 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'R3_TAG=keep OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'R3_PACK=3,3,0 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'LEDGER_N=3 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'ENT_ACT_0=drop OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'ENT_REASON_0=risk-inv OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'ENT_ACT_1=drop OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'ENT_REASON_1=risk-loss OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'ENT_ACT_2=keep OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'ENT_BASE_2=18 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'ENT_TRIAL_2=36 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'ENT_REASON_2=risk-ok OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'LAW_HS=3 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'LAW_SZ=3 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'FEE=0 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'HALT=0 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'TICK=0 OK' "$ROOT/out/risk_sim.txt" || fail=1
grep -q 'MARKET_RISK_OK' "$ROOT/out/risk_sim.txt" || fail=1
if grep -q 'MARKET_RISK_FAIL\|WANT' "$ROOT/out/risk_sim.txt"; then
  fail=1
fi
if grep -qiE 'error:|unbound variable' "$ROOT/out/risk_sim.txt" "$ROOT/out/risk_sim.err"; then
  fail=1
fi
if [[ "$fail" -ne 0 ]]; then
  echo "smoke_risk: MARKET_RISK_OK checks failed" >&2
  exit 1
fi
echo "smoke_risk: MARKET_RISK_OK"
