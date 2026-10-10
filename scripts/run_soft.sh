#!/usr/bin/env bash
# Shared Soft runner: tip aura inside ghcr.io/cybrid-systems/dev:v1.0.9.
# Soft runs natively in the container (no nested docker). Never build_soft4132.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AURA_SRC="${AURA_SRC:-/workspace/aura-grok}"
IMG="ghcr.io/cybrid-systems/dev:v1.0.9"
SRC="${1:?aura source path}"
shift || true

if docker info >/dev/null 2>&1; then
  DOCKER=(docker)
elif sudo docker info >/dev/null 2>&1; then
  DOCKER=(sudo docker)
else
  DOCKER=()
fi

if [[ ${#DOCKER[@]} -eq 0 ]]; then
  AURA_HOST="${AURA_BIN:-/workspace/aura-grok/build/aura}"
  if [[ ! -x "$AURA_HOST" ]]; then
    echo "run_soft: docker not available and ${AURA_HOST} is not executable" >&2
    exit 1
  fi
  export AURA_PATH="${AURA_PATH:-/workspace/aura-grok/lib}"
  export AURA_PIPELINE_STRICT="${AURA_PIPELINE_STRICT:-0}"
  export AURA_SANDBOX="${AURA_SANDBOX:-off}"
  export AURA_BIN="$AURA_HOST"
  exec "$AURA_HOST" "$SRC" "$@"
fi

exec "${DOCKER[@]}" run --rm -i --entrypoint /usr/local/bin/gosu \
  -v "${AURA_SRC}:/workspace/aura-grok" \
  -v "${ROOT}:/workspace/aura-market" \
  -w /workspace/aura-market \
  -e AURA_PATH=/workspace/aura-grok/lib \
  -e AURA_PIPELINE_STRICT=0 \
  -e AURA_SANDBOX=off \
  -e AURA_BIN=/workspace/aura-grok/build/aura \
  -e "MARKET_HORIZON=${MARKET_HORIZON:-}" \
  -e "MARKET_BURN_ROUNDS=${MARKET_BURN_ROUNDS:-}" \
  -e "MARKET_ROUND_DIR=${MARKET_ROUND_DIR:-}" \
  -e "MARKET_PROPOSE_FILE=${MARKET_PROPOSE_FILE:-}" \
  -e "MARKET_PROPOSE=${MARKET_PROPOSE:-}" \
  "${IMG}" \
  dev /usr/bin/stdbuf -oL -eL /workspace/aura-grok/build/aura "$SRC" "$@"
