#!/usr/bin/env bash
# M6 score parts and fat-px. Re-checks M0 through M4.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/out"

bash "$ROOT/scripts/smoke_m4.sh"

echo "smoke: m6 parts"
bash "$ROOT/scripts/run_soft.sh" /workspace/aura-market/soft/market/m6_smoke.aura \
  >"$ROOT/out/m6_smoke.txt" 2>"$ROOT/out/m6_smoke.err"
cat "$ROOT/out/m6_smoke.txt"
if [[ -s "$ROOT/out/m6_smoke.err" ]]; then
  cat "$ROOT/out/m6_smoke.err" >&2
fi
fail=0
grep -q 'SCORE_TIGHT=-5 OK' "$ROOT/out/m6_smoke.txt" || fail=1
grep -q 'SCORE_WIDE=18 OK' "$ROOT/out/m6_smoke.txt" || fail=1
grep -q 'SCORE_Q=15 OK' "$ROOT/out/m6_smoke.txt" || fail=1
grep -q 'pnl=89' "$ROOT/out/m6_smoke.txt" || fail=1
grep -q 'pen_inv=71' "$ROOT/out/m6_smoke.txt" || fail=1
grep -q 'pen_adv=3' "$ROOT/out/m6_smoke.txt" || fail=1
grep -q 'REJECT mid=9 reason=fat-px' "$ROOT/out/m6_smoke.txt" || fail=1
grep -q 'ASK14=out' "$ROOT/out/m6_smoke.txt" || fail=1
grep -q 'PROPOSE tag=propose_drop' "$ROOT/out/m6_smoke.txt" || fail=1
grep -q 'FAT_TRIAL=0 OK' "$ROOT/out/m6_smoke.txt" || fail=1
grep -q 'MARKET_M6_OK' "$ROOT/out/m6_smoke.txt" || fail=1
if grep -q 'MARKET_M6_FAIL\|FAT_DROP_FAIL\|FAT_HEAL_FAIL\|ASK_REST_FAIL\|WANT=' "$ROOT/out/m6_smoke.txt"; then
  fail=1
fi
if grep -qiE 'error:|unbound variable' "$ROOT/out/m6_smoke.txt" "$ROOT/out/m6_smoke.err"; then
  fail=1
fi
if [[ "$fail" -ne 0 ]]; then
  echo "smoke_m6: MARKET_M6_OK checks failed" >&2
  exit 1
fi
echo "smoke_m6: MARKET_M6_OK"
