#!/usr/bin/env bash
# Multi-round propose → gate → play. Default 3 rounds, horizon 24.
# MARKET_PROPOSE=1 calls MiniMax when a key file exists; otherwise fixtures.
# MARKET_PROPOSE=0 always uses soft/market/fixtures/burn (offline).
# Run: bash scripts/burn.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export MARKET_BURN_ROUNDS="${MARKET_BURN_ROUNDS:-3}"
export MARKET_HORIZON="${MARKET_HORIZON:-24}"
export MARKET_PROPOSE="${MARKET_PROPOSE:-1}"
mkdir -p "$ROOT/out"
keyfile="/home/box/.config/aura-build/minimax_api_key"

if [[ "$MARKET_PROPOSE" == "1" && -s "$keyfile" ]]; then
  dir="$ROOT/out/burn-rounds"
  rm -rf "$dir"
  mkdir -p "$dir"
  prev=""
  note="none"
  for ((r=1; r<=MARKET_BURN_ROUNDS; r++)); do
    out="$dir/${r}.lambda"
    echo "burn: propose round ${r}"
    if [[ -n "$prev" ]]; then
      python3 "$ROOT/scripts/propose_minimax.py" "$out" "$r" "$note" "$prev" \
        >/tmp/market-burn-propose.stdout 2>"$ROOT/out/burn_propose_${r}.stderr"
    else
      python3 "$ROOT/scripts/propose_minimax.py" "$out" "$r" "$note" \
        >/tmp/market-burn-propose.stdout 2>"$ROOT/out/burn_propose_${r}.stderr"
    fi
    cat "$ROOT/out/burn_propose_${r}.stderr" >&2 || true
    test -s "$out"
    echo "burn: round ${r} $(tr -d '\n' < "$out")"
    prev="$out"
    note="round ${r} wrote a lambda"
  done
  export MARKET_ROUND_DIR="/workspace/aura-market/out/burn-rounds"
else
  if [[ "$MARKET_PROPOSE" == "1" ]]; then
    echo "burn: no MiniMax key; fixture rounds" >&2
  else
    echo "burn: fixture rounds"
  fi
  export MARKET_ROUND_DIR="/workspace/aura-market/soft/market/fixtures/burn"
fi

echo "burn: rounds=${MARKET_BURN_ROUNDS} horizon=${MARKET_HORIZON} dir=${MARKET_ROUND_DIR}"
bash "$ROOT/scripts/run_soft.sh" /workspace/aura-market/soft/market/burn.aura \
  | tee "$ROOT/out/burn.txt"
grep -q 'MARKET_BURN_OK' "$ROOT/out/burn.txt"
grep -q 'KEEP reason=higher-score-stamp' "$ROOT/out/burn.txt"
grep -q 'DROP reason=lower-score-rollback' "$ROOT/out/burn.txt"
grep -E -q 'WORLD line=(host-sequential|fiber_live)' "$ROOT/out/burn.txt"
echo "burn: MARKET_BURN_OK"
