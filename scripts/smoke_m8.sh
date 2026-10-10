#!/usr/bin/env bash
# M8 rolling window. Fixture packs only. No search.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/out"

echo "smoke: m8 window"
bash "$ROOT/scripts/run_soft.sh" /workspace/aura-market/soft/market/m8_smoke.aura \
  >"$ROOT/out/m8_smoke.txt" 2>"$ROOT/out/m8_smoke.err"
cat "$ROOT/out/m8_smoke.txt"
if [[ -s "$ROOT/out/m8_smoke.err" ]]; then
  cat "$ROOT/out/m8_smoke.err" >&2
fi
fail=0
grep -q 'WINDOW tick=12 from=1 to=12 score=-15' "$ROOT/out/m8_smoke.txt" || fail=1
grep -q 'WINDOW tick=24 from=13 to=24 score=1' "$ROOT/out/m8_smoke.txt" || fail=1
grep -q 'WINDOW tick=36 from=25 to=36 score=9' "$ROOT/out/m8_smoke.txt" || fail=1
grep -q 'SWAP name=mk:law tick=36 reason=window' "$ROOT/out/m8_smoke.txt" || fail=1
grep -q 'WINDOW tick=48 from=37 to=48 score=10' "$ROOT/out/m8_smoke.txt" || fail=1
grep -q 'KEEP_LAW=(3 3 0 0 0 0) OK' "$ROOT/out/m8_smoke.txt" || fail=1
grep -q 'KEEP_SHADOW=(3 3 0 0 0 0) OK' "$ROOT/out/m8_smoke.txt" || fail=1
grep -q 'WINDOW tick=60 from=49 to=60 score=9' "$ROOT/out/m8_smoke.txt" || fail=1
grep -q 'SWAP name=mk:law tick=60 reason=window' "$ROOT/out/m8_smoke.txt" || fail=1
grep -q 'WINDOW tick=72 from=61 to=72 score=0' "$ROOT/out/m8_smoke.txt" || fail=1
grep -q 'HEAL name=mk:law tick=72 reason=window' "$ROOT/out/m8_smoke.txt" || fail=1
grep -q 'HEAL_LAW=(3 3 0 0 0 0) OK' "$ROOT/out/m8_smoke.txt" || fail=1
grep -q 'HEAL_SHADOW=(3 3 0 0 0 0) OK' "$ROOT/out/m8_smoke.txt" || fail=1
grep -q 'END_TICK=72 OK' "$ROOT/out/m8_smoke.txt" || fail=1
grep -q 'MARKET_M8_OK' "$ROOT/out/m8_smoke.txt" || fail=1
if grep -q 'MARKET_M8_FAIL\|WANT=' "$ROOT/out/m8_smoke.txt"; then
  fail=1
fi
if grep -qiE 'error:|unbound variable' "$ROOT/out/m8_smoke.txt" "$ROOT/out/m8_smoke.err"; then
  fail=1
fi
python3 - "$ROOT/out/m8_smoke.txt" << 'PY' || fail=1
import re, sys
text = open(sys.argv[1]).read()
ticks = [int(n) for n in re.findall(r"(?:SWAP|HEAL) name=mk:law tick=(\d+)", text)]
if ticks != [36, 60, 72]:
    sys.exit(1)
PY
if [[ "$fail" -ne 0 ]]; then
  echo "smoke_m8: MARKET_M8_OK checks failed" >&2
  exit 1
fi
echo "smoke_m8: MARKET_M8_OK"
