#!/usr/bin/env bash
# Simulated hot signal on the seeded tape. Not a forecast.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/out"

echo "smoke: signal"
bash "$ROOT/scripts/run_soft.sh" /workspace/aura-market/soft/market/signal_sim.aura \
  >"$ROOT/out/signal_sim.txt" 2>"$ROOT/out/signal_sim.err"
cat "$ROOT/out/signal_sim.txt"
if [[ -s "$ROOT/out/signal_sim.err" ]]; then
  cat "$ROOT/out/signal_sim.err" >&2
fi
fail=0
grep -q 'SIM signal not-a-forecast' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'SIG_ZERO=18 OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'SIG_ZERO_DRIFT=39 OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'SIG_CALM=30 OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'SIG_DRIFT=-108 OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'SIG_INV=4 OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'SIG_QUOTE=97,5,103,5 OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'SIG_SHIFT=96,5,102,5 OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'SIG_CALL=1 OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'SIG_NEG=() OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'SIG_TAG=signal_drop OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'SIG_AFTER=0 OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'LAW_HS=3 OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'LAW_SZ=5 OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'LIVE_REGIME=calm OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'LEDGER_N=1 OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'ENT_ACT_0=drop OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'ENT_TICK_0=0 OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'ENT_BASE_0=18 OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'ENT_TRIAL_0=30 OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'ENT_PACK_0=3,5,0 OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'ENT_REASON_0=drift-fail OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'ENT_DRIFT_BASE=39 OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'ENT_DRIFT_TRIAL=-108 OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'ENT_BODY_0=(lambda (drift inv imb) drift) OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'LEDGER_DROP_MUT=signal OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'ENGINE_MUTS=0 OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'M0_WIDE=18 OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'TICK=0 OK' "$ROOT/out/signal_sim.txt" || fail=1
grep -q 'MARKET_SIGNAL_OK' "$ROOT/out/signal_sim.txt" || fail=1
if grep -q 'MARKET_SIGNAL_FAIL\|WANT' "$ROOT/out/signal_sim.txt"; then
  fail=1
fi
if grep -qiE 'error:|unbound variable' "$ROOT/out/signal_sim.txt" "$ROOT/out/signal_sim.err"; then
  fail=1
fi
if [[ "$fail" -ne 0 ]]; then
  echo "smoke_signal: MARKET_SIGNAL_OK checks failed" >&2
  exit 1
fi
echo "smoke_signal: MARKET_SIGNAL_OK"
