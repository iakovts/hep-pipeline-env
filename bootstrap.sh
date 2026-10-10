#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MG5_DATA_DIR="$SCRIPT_DIR/mg5_data"
MG_PIPELINE_DIR="$MG5_DATA_DIR/mg-pipeline"
MG_PIPELINE_REPO="https://github.com/iakovts/mg-pipeline"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command '$1' was not found." >&2
    exit 1
  fi
}

require_command git
require_command docker

if ! docker compose version >/dev/null 2>&1; then
  echo "Error: 'docker compose' is not available." >&2
  exit 1
fi

mkdir -p "$MG5_DATA_DIR"

# Clone mg-pipeline into the workspace (skipped if already present).
if [[ -d "$MG_PIPELINE_DIR/.git" ]]; then
  echo "mg-pipeline already exists at $MG_PIPELINE_DIR"
elif [[ -e "$MG_PIPELINE_DIR" ]]; then
  echo "Error: $MG_PIPELINE_DIR exists but is not a git checkout." >&2
  exit 1
else
  echo "Cloning mg-pipeline into $MG_PIPELINE_DIR"
  git clone "$MG_PIPELINE_REPO" "$MG_PIPELINE_DIR"
fi

cd "$SCRIPT_DIR"
docker compose build
exec docker compose run --rm madgraph_p3