#!/usr/bin/env bash
# Simulated per-lot execution score. Not a venue fee.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/out"

echo "smoke: exec"
bash "$ROOT/scripts/run_soft.sh" /workspace/aura-market/soft/market/exec_sim.aura \
  >"$ROOT/out/exec_sim.txt" 2>"$ROOT/out/exec_sim.err"
cat "$ROOT/out/exec_sim.txt"
if [[ -s "$ROOT/out/exec_sim.err" ]]; then
  cat "$ROOT/out/exec_sim.err" >&2
fi
fail=0
grep -q 'SIM exec not-a-venue-fee' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'M0_WIDE=18 OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'EXEC_RATE=1 OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'EXEC_WIDE=-12 OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'EXEC_VOL=30 OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'EXEC_330=6 OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'EXEC_330_VOL=30 OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'EXEC_RAW=24 OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'EXEC_220=-21 OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'EXEC_220_VOL=45 OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'EXEC_TAG=exec_drop OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'LEDGER_N=1 OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'ENT_ACT_0=drop OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'ENT_TICK_0=0 OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'ENT_BASE_0=18 OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'ENT_TRIAL_0=24 OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'ENT_PACK_0=2,2,0 OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'ENT_REASON_0=exec OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'ENT_EXEC_BASE=-12 OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'ENT_EXEC_TRIAL=-21 OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'LAW_HS=3 OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'LAW_SZ=5 OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'FEE=0 OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'HALT=0 OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'TICK=0 OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'SCORE_Q_UNTOUCHED=15 OK' "$ROOT/out/exec_sim.txt" || fail=1
grep -q 'MARKET_EXEC_OK' "$ROOT/out/exec_sim.txt" || fail=1
if grep -q 'MARKET_EXEC_FAIL\|WANT' "$ROOT/out/exec_sim.txt"; then
  fail=1
fi
if grep -qiE 'error:|unbound variable' "$ROOT/out/exec_sim.txt" "$ROOT/out/exec_sim.err"; then
  fail=1
fi
if [[ "$fail" -ne 0 ]]; then
  echo "smoke_exec: MARKET_EXEC_OK checks failed" >&2
  exit 1
fi
echo "smoke_exec: MARKET_EXEC_OK"
