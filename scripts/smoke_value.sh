#!/usr/bin/env bash
# Live book, regime change at tick 12. Heal restores code, not fills.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/out"

echo "smoke: value"
bash "$ROOT/scripts/run_soft.sh" /workspace/aura-market/soft/market/value_smoke.aura \
  >"$ROOT/out/value_smoke.txt" 2>"$ROOT/out/value_smoke.err"
cat "$ROOT/out/value_smoke.txt"
if [[ -s "$ROOT/out/value_smoke.err" ]]; then
  cat "$ROOT/out/value_smoke.err" >&2
fi
fail=0
grep -q 'M0_TIGHT=-5 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'M0_WIDE=18 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'CALM_W12=-15 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'CALM_W24=1 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'CALM_W36=9 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'CALM_W48=10 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'FROZEN_W24=7 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'FROZEN_SCORE=18 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'AUDIT tick=12 action=swap base=-1000000 trial=-15' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'AUDIT tick=24 action=heal base=7 trial=-20' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'HEAL name=mk:law tick=24 reason=window' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'POISON_CASH=514 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'POISON_FILLS=3 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'POISON_INV=-5 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'POISON_STUCK_FILLS=3 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'POISON_HEAL_LAW=3,5,0,0,0,0 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'POISON_HEAL_SHADOW=3,5,0,0,0,0 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'POISON_SCORE=-21 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'POISON_GAP=-39 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'POISON_END_LAW=3,5,0,0,0,0 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'POISON_REWIND=0 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'AUDIT tick=24 action=heal base=7 trial=7' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'TIE_SCORE=18 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'AUDIT tick=24 action=heal base=7 trial=-1' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'LEAN_GAP=2 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'LEAN_LAW=3,5,0,0,0,0 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'AUDIT tick=24 action=keep base=-15 trial=4' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'KEEP_LAW=3,3,0,0,0,0 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'KEEP_SHADOW=3,3,0,0,0,0 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'KEEP_GAP=4 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'STALE_GAP=-5 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'STALE_SHADOW=3,5,0,0,0,0 OK' "$ROOT/out/value_smoke.txt" || fail=1
grep -q 'MARKET_VALUE_OK' "$ROOT/out/value_smoke.txt" || fail=1
if grep -q 'MARKET_VALUE_FAIL\|INVARIANT fail\|WANT=' "$ROOT/out/value_smoke.txt"; then
  fail=1
fi
if grep -qiE 'error:|unbound variable' "$ROOT/out/value_smoke.txt" "$ROOT/out/value_smoke.err"; then
  fail=1
fi
if [[ "$fail" -ne 0 ]]; then
  echo "smoke_value: MARKET_VALUE_OK checks failed" >&2
  exit 1
fi
echo "smoke_value: MARKET_VALUE_OK"
