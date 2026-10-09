#!/bin/bash
set -euo pipefail
#
# Interactive shell entry for the MadGraph HEP pipeline on Aristotle HPC.
# Equivalent of run.sh for the Apptainer-based HPC workflow.
#
# Usage (from the repo root, on a login node or compute node):
#   ./hpc_run.sh
#
# The HEP environment (PATH, LD_LIBRARY_PATH, etc.) is restored automatically
# by compile_all.sh at shell entry via the %runscript in madgraph.def.
#
# Prerequisites:
#   - madgraph.sif must exist (run hpc_bootstrap.sh first)
#   - .bootstrap_done must exist (hpc_bootstrap.sh creates this)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIF="$SCRIPT_DIR/madgraph.sif"
MARKER="$SCRIPT_DIR/mg5_data/.bootstrap_done"

if ! command -v apptainer >/dev/null 2>&1; then
    # Try loading the module if apptainer is not yet on PATH
    if command -v module >/dev/null 2>&1; then
        module load gcc/14.2.0 apptainer/1.3.4
    else
        echo "Error: apptainer is not available. Load it with:" >&2
        echo "  module load gcc/14.2.0 apptainer/1.3.4" >&2
        exit 1
    fi
fi

if [[ ! -f "$SIF" ]]; then
    echo "Error: $SIF not found." >&2
    echo "Run the bootstrap job first:" >&2
    echo "  mkdir -p logs && sbatch hpc_bootstrap.sh" >&2
    exit 1
fi

if [[ ! -f "$MARKER" ]]; then
    echo "Error: .bootstrap_done not found — HEP libraries have not been compiled yet." >&2
    echo "Run the bootstrap job first:" >&2
    echo "  mkdir -p logs && sbatch hpc_bootstrap.sh" >&2
    exit 1
fi

# To auto-source the HEP environment, run inside the container:
#   source /madgraph/compile_all.sh
# Alternative (if apptainer passes args correctly to bash):
#   apptainer exec ... bash --rcfile /madgraph/compile_all.sh
# Note: apptainer shell already gives an interactive shell; -i alone adds nothing here.
exec apptainer exec \
    --cleanenv \
    --bind "$SCRIPT_DIR/mg5_data:/madgraph" \
    --bind "$SCRIPT_DIR/compile_all.sh:/madgraph/compile_all.sh" \
    "$SIF" \
    bash --rcfile /madgraph/compile_all.sh
