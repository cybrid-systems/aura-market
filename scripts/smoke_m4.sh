#!/usr/bin/env bash
# M4 causal features and six-integer packs. Re-checks M0 through M3.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/out"

bash "$ROOT/scripts/smoke_m3.sh"

echo "smoke: m4 features"
bash "$ROOT/scripts/run_soft.sh" /workspace/aura-market/soft/market/m4_smoke.aura \
  >"$ROOT/out/m4_smoke.txt" 2>"$ROOT/out/m4_smoke.err"
cat "$ROOT/out/m4_smoke.txt"
if [[ -s "$ROOT/out/m4_smoke.err" ]]; then
  cat "$ROOT/out/m4_smoke.err" >&2
fi
fail=0
grep -q 'SCORE_TIGHT=-5 OK' "$ROOT/out/m4_smoke.txt" || fail=1
grep -q 'SCORE_WIDE=18 OK' "$ROOT/out/m4_smoke.txt" || fail=1
grep -q 'M4_1_OK' "$ROOT/out/m4_smoke.txt" || fail=1
grep -q 'M4_2_OK' "$ROOT/out/m4_smoke.txt" || fail=1
grep -q 'M4_3_OK' "$ROOT/out/m4_smoke.txt" || fail=1
grep -q 'M4_4_OK' "$ROOT/out/m4_smoke.txt" || fail=1
grep -q 'M4_5_OK' "$ROOT/out/m4_smoke.txt" || fail=1
grep -q 'MARKET_M4_OK' "$ROOT/out/m4_smoke.txt" || fail=1
if grep -q 'MARKET_M4_FAIL\|M4_[0-9]_FAIL\|PACK3_FAIL\|PACK6_FAIL\|SIX_DROP_FAIL\|KEEP6_FAIL' "$ROOT/out/m4_smoke.txt"; then
  fail=1
fi
if grep -qiE 'error:|unbound variable' "$ROOT/out/m4_smoke.txt" "$ROOT/out/m4_smoke.err"; then
  fail=1
fi
if [[ "$fail" -ne 0 ]]; then
  echo "smoke_m4: MARKET_M4_OK checks failed" >&2
  exit 1
fi
echo "smoke_m4: MARKET_M4_OK"
