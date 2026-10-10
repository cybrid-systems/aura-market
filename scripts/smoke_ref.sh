#!/usr/bin/env bash
# Production reference: fee, halt, invariants, decision journal.
# The M0 tape stays fee-free.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/out"

echo "smoke: reference"
bash "$ROOT/scripts/run_soft.sh" /workspace/aura-market/soft/market/ref_smoke.aura \
  >"$ROOT/out/ref_smoke.txt" 2>"$ROOT/out/ref_smoke.err"
cat "$ROOT/out/ref_smoke.txt"
if [[ -s "$ROOT/out/ref_smoke.err" ]]; then
  cat "$ROOT/out/ref_smoke.err" >&2
fi
fail=0
grep -q 'M0_TIGHT=-5 OK' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'M0_WIDE=18 OK' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'M0_WIDE_AGAIN=18 OK' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'WINDOW tick=12 from=1 to=12 score=-15' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'WINDOW tick=24 from=13 to=24 score=1' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'WINDOW tick=36 from=25 to=36 score=9' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'WINDOW tick=48 from=37 to=48 score=10' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'LIVE_TICK=48 OK' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'LIVE_FAILS=0 OK' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'FEE_CASH=' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'FEE_PAID OK' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'FEE_UNITS=41 OK' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'FEE_FAILS=0 OK' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'HALT tick=8 reason=manual' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'HALT_INV=' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'HALT_TICK=20 OK' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'HALT_BOOK=0 OK' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'RESUME tick=20' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'RESUME_TICK=24 OK' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'HALT tick=1 reason=loss-floor' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'FLOOR_TICK=6 OK' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'AUDIT tick=24 action=swap base=0 trial=1' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'SWAP name=mk:law tick=24 reason=window' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'AUDIT tick=36 action=heal base=1 trial=0' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'HEAL name=mk:law tick=36 reason=window' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'HEAL_LAW OK' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'HEAL_SHADOW OK' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'HEAL_TICK=36 OK' "$ROOT/out/ref_smoke.txt" || fail=1
grep -q 'MARKET_REF_OK' "$ROOT/out/ref_smoke.txt" || fail=1
if grep -q 'MARKET_REF_FAIL\|INVARIANT fail\|WANT=' "$ROOT/out/ref_smoke.txt"; then
  fail=1
fi
if grep -qiE 'error:|unbound variable' "$ROOT/out/ref_smoke.txt" "$ROOT/out/ref_smoke.err"; then
  fail=1
fi
if [[ "$fail" -ne 0 ]]; then
  echo "smoke_ref: MARKET_REF_OK checks failed" >&2
  exit 1
fi
echo "smoke_ref: MARKET_REF_OK"
