#!/usr/bin/env bash
# After heal, the AST mutation log forgets the rebind. The ledger does not.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/out"

echo "smoke: ledger"
bash "$ROOT/scripts/run_soft.sh" /workspace/aura-market/soft/market/ledger_smoke.aura \
  >"$ROOT/out/ledger_smoke.txt" 2>"$ROOT/out/ledger_smoke.err"
cat "$ROOT/out/ledger_smoke.txt"
if [[ -s "$ROOT/out/ledger_smoke.err" ]]; then
  cat "$ROOT/out/ledger_smoke.err" >&2
fi
fail=0
grep -q 'M0_TIGHT=-5 OK' "$ROOT/out/ledger_smoke.txt" || fail=1
grep -q 'M0_WIDE=18 OK' "$ROOT/out/ledger_smoke.txt" || fail=1
grep -q 'LEDGER_N=2 OK' "$ROOT/out/ledger_smoke.txt" || fail=1
grep -q 'LEDGER_SWAP=swap OK' "$ROOT/out/ledger_smoke.txt" || fail=1
grep -q 'LEDGER_SWAP_TICK=24 OK' "$ROOT/out/ledger_smoke.txt" || fail=1
grep -q 'LEDGER_HEAL=heal OK' "$ROOT/out/ledger_smoke.txt" || fail=1
grep -q 'LEDGER_HEAL_TICK=36 OK' "$ROOT/out/ledger_smoke.txt" || fail=1
grep -q 'LEDGER_HEAL_PACK=9,5,0 OK' "$ROOT/out/ledger_smoke.txt" || fail=1
grep -q 'LEDGER_HEAL_MUT=window OK' "$ROOT/out/ledger_smoke.txt" || fail=1
grep -q 'LAW_NOW_HS=3 OK' "$ROOT/out/ledger_smoke.txt" || fail=1
grep -q 'LAW_NOW_SZ=5 OK' "$ROOT/out/ledger_smoke.txt" || fail=1
grep -q 'ENGINE_MUTS=0 OK' "$ROOT/out/ledger_smoke.txt" || fail=1
grep -q 'LEDGER_TICK=36 OK' "$ROOT/out/ledger_smoke.txt" || fail=1
grep -q 'AUDIT tick=24 action=swap base=0 trial=1' "$ROOT/out/ledger_smoke.txt" || fail=1
grep -q 'AUDIT tick=36 action=heal base=1 trial=0' "$ROOT/out/ledger_smoke.txt" || fail=1
grep -q 'MARKET_LEDGER_OK' "$ROOT/out/ledger_smoke.txt" || fail=1
if grep -q 'MARKET_LEDGER_FAIL\|INVARIANT fail\|WANT=' "$ROOT/out/ledger_smoke.txt"; then
  fail=1
fi
if grep -qiE 'error:|unbound variable' "$ROOT/out/ledger_smoke.txt" "$ROOT/out/ledger_smoke.err"; then
  fail=1
fi
if [[ "$fail" -ne 0 ]]; then
  echo "smoke_ledger: MARKET_LEDGER_OK checks failed" >&2
  exit 1
fi
echo "smoke_ledger: MARKET_LEDGER_OK"
