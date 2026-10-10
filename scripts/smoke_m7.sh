#!/usr/bin/env bash
# M7 regime worldlines. Re-checks M0 through M6.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/out"

bash "$ROOT/scripts/smoke_m6.sh"

echo "smoke: m7 regimes"
bash "$ROOT/scripts/run_soft.sh" /workspace/aura-market/soft/market/m7_smoke.aura \
  >"$ROOT/out/m7_smoke.txt" 2>"$ROOT/out/m7_smoke.err"
cat "$ROOT/out/m7_smoke.txt"
if [[ -s "$ROOT/out/m7_smoke.err" ]]; then
  cat "$ROOT/out/m7_smoke.err" >&2
fi
fail=0
grep -q 'CALM_WIDE=18 OK' "$ROOT/out/m7_smoke.txt" || fail=1
grep -q 'CALM_TIGHT=-5 OK' "$ROOT/out/m7_smoke.txt" || fail=1
grep -q 'M0_WIDE=18 OK' "$ROOT/out/m7_smoke.txt" || fail=1
grep -q 'REGIME calm=18/18 drift=39/39 aggr=187/187' "$ROOT/out/m7_smoke.txt" || fail=1
grep -q 'REGIME calm=18/26 drift=39/8 aggr=187/114' "$ROOT/out/m7_smoke.txt" || fail=1
grep -q 'REGIME calm=18/28 drift=39/40 aggr=187/192' "$ROOT/out/m7_smoke.txt" || fail=1
grep -q 'WORLD line=fiber_live backend=[1-9][0-9]* joins=6/6' "$ROOT/out/m7_smoke.txt" || fail=1
grep -q 'WORLD line=host-sequential backend=[0-9]* joins=0/6' "$ROOT/out/m7_smoke.txt" || fail=1
grep -q 'MISS=host-sequential' "$ROOT/out/m7_smoke.txt" || fail=1
grep -q 'DROP_TRIAL=8 OK' "$ROOT/out/m7_smoke.txt" || fail=1
grep -q 'KEEP_TRIAL=28 OK' "$ROOT/out/m7_smoke.txt" || fail=1
grep -q 'LAW=(3 6 0)' "$ROOT/out/m7_smoke.txt" || fail=1
grep -q 'MARKET_M7_OK' "$ROOT/out/m7_smoke.txt" || fail=1
if grep -q 'MARKET_M7_FAIL\|MISS_FAIL\|CALM_DROP_FAIL\|REGIME_KEEP_FAIL\|KEEP_LAW_FAIL\|WANT=' "$ROOT/out/m7_smoke.txt"; then
  fail=1
fi
if grep -qiE 'error:|unbound variable' "$ROOT/out/m7_smoke.txt" "$ROOT/out/m7_smoke.err"; then
  fail=1
fi
if [[ "$fail" -ne 0 ]]; then
  echo "smoke_m7: MARKET_M7_OK checks failed" >&2
  exit 1
fi
echo "smoke_m7: MARKET_M7_OK"
