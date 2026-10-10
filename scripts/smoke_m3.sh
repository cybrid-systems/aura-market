#!/usr/bin/env bash
# M3 panel minimum. Also re-checks M0, M1, and M2.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/out"

bash "$ROOT/scripts/smoke_soft.sh"
bash "$ROOT/scripts/smoke_m1.sh"
bash "$ROOT/scripts/smoke_m2.sh"

echo "smoke: m3 panel"
bash "$ROOT/scripts/run_soft.sh" /workspace/aura-market/soft/market/m3_smoke.aura \
  >"$ROOT/out/m3_smoke.txt" 2>"$ROOT/out/m3_smoke.err"
cat "$ROOT/out/m3_smoke.txt"
if [[ -s "$ROOT/out/m3_smoke.err" ]]; then
  cat "$ROOT/out/m3_smoke.err" >&2
fi
fail=0
grep -q 'PANEL tag=mm-wide min=18 median=56' "$ROOT/out/m3_smoke.txt" || fail=1
grep -q 'PANEL tag=mm-tight min=-5 median=3' "$ROOT/out/m3_smoke.txt" || fail=1
grep -q 'PROPOSE tag=propose_drop' "$ROOT/out/m3_smoke.txt" || fail=1
grep -q 'SPEC_TRIAL=-4 OK' "$ROOT/out/m3_smoke.txt" || fail=1
grep -q 'MARKET_M3_OK' "$ROOT/out/m3_smoke.txt" || fail=1
grep -E -q 'WORLD line=(host-sequential|fiber_live)' "$ROOT/out/m3_smoke.txt" || fail=1
if grep -q 'MARKET_M3_FAIL\|M3_[0-9]_FAIL\|SPEC_DROP_FAIL\|SPEC_HEAL_FAIL' "$ROOT/out/m3_smoke.txt"; then
  fail=1
fi
if grep -q 'WORLD line=fiber_live' "$ROOT/out/m3_smoke.txt"; then
  python3 - "$ROOT/out/m3_smoke.txt" << 'PY' || fail=1
import re, sys
text = open(sys.argv[1]).read()
m = re.search(r"WORLD line=fiber_live backend=(\d+) joins=(\d+)/(\d+)", text)
if not m or m.group(2) != m.group(3) or int(m.group(1)) <= 0 or int(m.group(2)) <= 0:
    sys.exit(1)
PY
fi
if grep -qiE 'error:|unbound variable' "$ROOT/out/m3_smoke.txt" "$ROOT/out/m3_smoke.err"; then
  fail=1
fi
if [[ "$fail" -ne 0 ]]; then
  echo "smoke_m3: MARKET_M3_OK checks failed" >&2
  exit 1
fi
echo "smoke_m3: MARKET_M3_OK"
