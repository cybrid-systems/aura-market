#!/usr/bin/env bash
# Stack: M0 Soft order-book race (the only milestone so far).
# Re-checks the M0 evidence lines, then prints MARKET_SMOKE_OK.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/out"

bash "$ROOT/scripts/smoke_soft.sh"

txt="$ROOT/out/m0_smoke.txt"
for pat in 'RACE tight=' 'REJECT mid=' 'WORLD line=' 'KEEP mid=' 'DROP mid=' 'MARKET_M0_OK'; do
  if ! grep -q "$pat" "$txt"; then
    echo "smoke: missing '$pat'" >&2
    echo "MARKET_SMOKE_FAIL" >&2
    exit 1
  fi
done

echo "smoke: MARKET_SMOKE_OK"
