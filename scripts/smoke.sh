#!/usr/bin/env bash
# Stack: M0 through M7, then the M5 grid, the M8 window, the live-book
# reference, the regime-shift value tape, optional live MiniMax (SKIP when
# no key), fixture burn.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/out"

bash "$ROOT/scripts/smoke_m7.sh"
bash "$ROOT/scripts/smoke_m5.sh"
bash "$ROOT/scripts/smoke_m8.sh"
bash "$ROOT/scripts/smoke_ref.sh"
bash "$ROOT/scripts/smoke_value.sh"

keyfile="/home/box/.config/aura-build/minimax_api_key"
if [[ ! -s "$keyfile" ]]; then
  echo "MARKET_M2_PROPOSE_LIVE_SKIP"
else
  echo "smoke: live MiniMax propose"
  live="$ROOT/out/live_pack.lambda"
  if python3 "$ROOT/scripts/propose_minimax.py" "$live" 1 "smoke" \
      >/tmp/market-propose.stdout 2>"$ROOT/out/live_propose.stderr"; then
    cat "$ROOT/out/live_propose.stderr" >&2 || true
    test -s "$live"
    echo "LIVE_LAMBDA $(head -c 200 "$live")"
    echo
    export MARKET_PROPOSE_FILE="/workspace/aura-market/out/live_pack.lambda"
    bash "$ROOT/scripts/run_soft.sh" /workspace/aura-market/soft/market/m2_live.aura \
      >"$ROOT/out/m2_live.txt" 2>"$ROOT/out/m2_live.err"
    cat "$ROOT/out/m2_live.txt"
    if [[ -s "$ROOT/out/m2_live.err" ]]; then
      cat "$ROOT/out/m2_live.err" >&2
    fi
    grep -q 'MARKET_M2_PROPOSE_LIVE_OK' "$ROOT/out/m2_live.txt"
    if grep -qiE 'error:|unbound variable' "$ROOT/out/m2_live.txt" "$ROOT/out/m2_live.err"; then
      echo "MARKET_M2_PROPOSE_LIVE_FAIL" >&2
      exit 1
    fi
    echo "MARKET_M2_PROPOSE_LIVE_OK"
  else
    cat "$ROOT/out/live_propose.stderr" >&2 || true
    echo "MARKET_M2_PROPOSE_LIVE_FAIL" >&2
    exit 1
  fi
fi

echo "smoke: fixture burn"
MARKET_PROPOSE=0 bash "$ROOT/scripts/burn.sh"

echo "smoke: MARKET_SMOKE_OK"
