#!/usr/bin/env bash
# Simulated dataset versions on the seeded tape. Not a feed.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/out"

echo "smoke: data"
bash "$ROOT/scripts/run_soft.sh" /workspace/aura-market/soft/market/data_sim.aura \
  >"$ROOT/out/data_sim.txt" 2>"$ROOT/out/data_sim.err"
cat "$ROOT/out/data_sim.txt"
if [[ -s "$ROOT/out/data_sim.err" ]]; then
  cat "$ROOT/out/data_sim.err" >&2
fi
fail=0
grep -q 'SIM data versioned-tape not-a-feed' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'M0_WIDE=18 OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'DATA_V0_WIDE=18 OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'DATA_V0_330=36 OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'DATA_V1_WIDE=17 OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'DATA_V1_PNL=86 OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'DATA_V1_PEN=69 OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'DATA_V1_INV=8 OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'DATA_V1_FAIR=96 OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'DATA_V1_FILLS=10 OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'DATA_V1_330=34 OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'DATA_IDEA=3,3,0 OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'DATA_MISMATCH=data-mismatch OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'LEDGER_N=1 OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'ENT_ACT_0=drop OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'ENT_TICK_0=0 OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'ENT_BASE_0=18 OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'ENT_TRIAL_0=18 OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'ENT_REASON_0=data-mismatch OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'ENT_FIT_0=v0 OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'ENT_ON_0=v1 OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'FEE=0 OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'HALT=0 OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'TICK=0 OK' "$ROOT/out/data_sim.txt" || fail=1
grep -q 'MARKET_DATA_OK' "$ROOT/out/data_sim.txt" || fail=1
if grep -q 'MARKET_DATA_FAIL\|WANT' "$ROOT/out/data_sim.txt"; then
  fail=1
fi
if grep -qiE 'error:|unbound variable' "$ROOT/out/data_sim.txt" "$ROOT/out/data_sim.err"; then
  fail=1
fi
if [[ "$fail" -ne 0 ]]; then
  echo "smoke_data: MARKET_DATA_OK checks failed" >&2
  exit 1
fi
echo "smoke_data: MARKET_DATA_OK"
