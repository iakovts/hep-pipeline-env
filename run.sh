#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MG5_DATA_DIR="$SCRIPT_DIR/mg5_data"
MG_PIPELINE_DIR="$MG5_DATA_DIR/mg-pipeline"

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is not available." >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Error: 'docker compose' is not available." >&2
  exit 1
fi

if [[ ! -d "$MG5_DATA_DIR" ]]; then
  echo "Error: $MG5_DATA_DIR does not exist. Run ./bootstrap.sh first." >&2
  exit 1
fi

if [[ ! -d "$MG_PIPELINE_DIR" ]]; then
  echo "Note: mg-pipeline not found at $MG_PIPELINE_DIR — clone it manually to run the pipeline:" >&2
  echo "  git clone https://github.com/iakovts/mg-pipeline $MG_PIPELINE_DIR" >&2
fi

cd "$SCRIPT_DIR"
exec docker compose run --rm madgraph_p3