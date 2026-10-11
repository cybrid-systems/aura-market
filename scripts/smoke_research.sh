#!/usr/bin/env bash
# Simulated research loop on the seeded tape. Not a market.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/out"

echo "smoke: research"
bash "$ROOT/scripts/run_soft.sh" /workspace/aura-market/soft/market/research_sim.aura \
  >"$ROOT/out/research_sim.txt" 2>"$ROOT/out/research_sim.err"
cat "$ROOT/out/research_sim.txt"
if [[ -s "$ROOT/out/research_sim.err" ]]; then
  cat "$ROOT/out/research_sim.err" >&2
fi
fail=0
grep -q 'R1_TRIAL=-5 OK' "$ROOT/out/research_sim.txt" || fail=1
grep -q 'R1_TAG=propose_drop OK' "$ROOT/out/research_sim.txt" || fail=1
grep -q 'R2_TRIAL=0 OK' "$ROOT/out/research_sim.txt" || fail=1
grep -q 'R3_TRIAL=36 OK' "$ROOT/out/research_sim.txt" || fail=1
grep -q 'R3_TAG=propose_keep OK' "$ROOT/out/research_sim.txt" || fail=1
grep -q 'R3_SCORE=36 OK' "$ROOT/out/research_sim.txt" || fail=1
grep -q 'R4_BASE=36 OK' "$ROOT/out/research_sim.txt" || fail=1
grep -q 'R4_TRIAL=-4 OK' "$ROOT/out/research_sim.txt" || fail=1
grep -q 'R4_TAG=propose_drop OK' "$ROOT/out/research_sim.txt" || fail=1
grep -q 'R4_SZ=3 OK' "$ROOT/out/research_sim.txt" || fail=1
grep -q 'LEDGER_N=4 OK' "$ROOT/out/research_sim.txt" || fail=1
grep -q 'ENT_PACK_0=1,3,2 OK' "$ROOT/out/research_sim.txt" || fail=1
grep -q 'ENT_PACK_1=9,5,0 OK' "$ROOT/out/research_sim.txt" || fail=1
grep -q 'ENT_PACK_2=3,3,0 OK' "$ROOT/out/research_sim.txt" || fail=1
grep -q 'ENT_PACK_3=2,2,2 OK' "$ROOT/out/research_sim.txt" || fail=1
grep -q 'LEDGER_DROP_MUT=propose OK' "$ROOT/out/research_sim.txt" || fail=1
grep -q 'M0_WIDE=18 OK' "$ROOT/out/research_sim.txt" || fail=1
grep -q 'MARKET_RESEARCH_OK' "$ROOT/out/research_sim.txt" || fail=1
if grep -q 'MARKET_RESEARCH_FAIL\|WANT' "$ROOT/out/research_sim.txt"; then
  fail=1
fi
if grep -qiE 'error:|unbound variable' "$ROOT/out/research_sim.txt" "$ROOT/out/research_sim.err"; then
  fail=1
fi
if [[ "$fail" -ne 0 ]]; then
  echo "smoke_research: MARKET_RESEARCH_OK checks failed" >&2
  exit 1
fi
echo "smoke_research: MARKET_RESEARCH_OK"
