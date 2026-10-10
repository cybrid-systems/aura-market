#!/usr/bin/env bash
# M5 grid search. No MiniMax. Re-checks the M0 tape.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/out"

bash "$ROOT/scripts/smoke_soft.sh"

echo "smoke: m5 grid"
export MARKET_SWARM_EVALS="${MARKET_SWARM_EVALS:-16}"
bash "$ROOT/scripts/run_soft.sh" /workspace/aura-market/soft/market/m5_smoke.aura \
  >"$ROOT/out/m5_smoke.txt" 2>"$ROOT/out/m5_smoke.err"
cat "$ROOT/out/m5_smoke.txt"
if [[ -s "$ROOT/out/m5_smoke.err" ]]; then
  cat "$ROOT/out/m5_smoke.err" >&2
fi
fail=0
grep -q 'M0_TIGHT=-5 OK' "$ROOT/out/m5_smoke.txt" || fail=1
grep -q 'M0_WIDE=18 OK' "$ROOT/out/m5_smoke.txt" || fail=1
grep -q 'M3_WIDE=18 OK' "$ROOT/out/m5_smoke.txt" || fail=1
grep -q 'WIN1=(3 3 0 0 0 0) OK' "$ROOT/out/m5_smoke.txt" || fail=1
grep -q 'WIN2=(3 3 0 0 0 0) OK' "$ROOT/out/m5_smoke.txt" || fail=1
grep -q 'BAD_TICK=10 OK' "$ROOT/out/m5_smoke.txt" || fail=1
grep -q 'panel=seq' "$ROOT/out/m5_smoke.txt" || fail=1
grep -q 'panel=fiber' "$ROOT/out/m5_smoke.txt" || fail=1
grep -q 'NESTED_SPAWN_FAIL' "$ROOT/out/m5_smoke.txt" || fail=1
grep -q 'WORLD line=fiber_live backend=[1-9][0-9]* joins=4/4' "$ROOT/out/m5_smoke.txt" || fail=1
grep -q 'MARKET_M5_OK' "$ROOT/out/m5_smoke.txt" || fail=1
if grep -q 'MARKET_M5_FAIL\|BAD_DROP_FAIL\|BOOK_TOUCH_FAIL\|WANT=' "$ROOT/out/m5_smoke.txt"; then
  fail=1
fi
if grep -qiE 'error:|unbound variable' "$ROOT/out/m5_smoke.txt" "$ROOT/out/m5_smoke.err"; then
  fail=1
fi
if [[ "$fail" -ne 0 ]]; then
  echo "smoke_m5: MARKET_M5_OK checks failed" >&2
  exit 1
fi
echo "smoke_m5: MARKET_M5_OK"
