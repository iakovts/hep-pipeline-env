#!/bin/bash
#SBATCH -J hep-pipeline
#SBATCH -p batch
#SBATCH -t 06:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH -o logs/pipeline_%j.out
#SBATCH -e logs/pipeline_%j.err
#
# Submit the mg-pipeline as a SLURM batch job on Aristotle HPC.
#
# Usage (from the repo root):
#   mkdir -p logs
#   sbatch hpc_pipeline_job.sh [pipeline options]
#
# All arguments after the script name are forwarded verbatim to
# mg-pipeline/run.py. Examples:
#
#   sbatch hpc_pipeline_job.sh --stages madgraph,madspin,pythia,rivet
#   sbatch hpc_pipeline_job.sh --skip-rivet --quiet
#   sbatch hpc_pipeline_job.sh --resume --intermediate-dir /madgraph/Experiments_2
#
# Paths inside the container:
#   mg5_data/              -> /madgraph
#   mg5_data/mg-pipeline/  -> /madgraph/mg-pipeline/
#
# Note: --intermediate-dir paths must be under mg5_data/ so the container
# can see them. Use the /madgraph/ prefix when passing them explicitly, e.g.:
#   --intermediate-dir /madgraph/Experiments_2
#
# Prerequisites:
#   1. Bootstrap completed:  hpc_bootstrap.sh
#   2. mg-pipeline cloned:   git clone <repo> mg5_data/mg-pipeline
#   3. MadGraph/MadSpin scripts present in:
#        mg5_data/madgraph_scripts/
#        mg5_data/madspin_scripts/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIF="$SCRIPT_DIR/madgraph.sif"
MG5_DATA_DIR="$SCRIPT_DIR/mg5_data"
MARKER="$MG5_DATA_DIR/.bootstrap_done"
MG_PIPELINE="$MG5_DATA_DIR/mg-pipeline/run.py"

# ---------------------------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------------------------
if [[ ! -f "$SIF" ]]; then
    echo "Error: $SIF not found. Run hpc_bootstrap.sh first." >&2
    exit 1
fi

if [[ ! -f "$MARKER" ]]; then
    echo "Error: .bootstrap_done not found — run hpc_bootstrap.sh first." >&2
    exit 1
fi

if [[ ! -f "$MG_PIPELINE" ]]; then
    echo "Error: mg-pipeline not found at $MG5_DATA_DIR/mg-pipeline/" >&2
    echo "Clone it first:" >&2
    echo "  git clone <your-mg-pipeline-repo> mg5_data/mg-pipeline" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Load Apptainer module if not already on PATH
# ---------------------------------------------------------------------------
if ! command -v apptainer >/dev/null 2>&1; then
    module load gcc/14.2.0 apptainer
fi

echo "=== mg-pipeline batch job ==="
echo "Job ID:        ${SLURM_JOB_ID:-<interactive>}"
echo "SIF:           $SIF"
echo "Pipeline args: $*"
echo ""

# ---------------------------------------------------------------------------
# Run the pipeline inside the container
# ---------------------------------------------------------------------------
# source compile_all.sh to restore PATH, LD_LIBRARY_PATH, etc., then run
# the pipeline. The '-- "$@"' idiom passes this script's positional args
# into the bash -c string so "$@" inside correctly expands to them.
apptainer exec \
    --cleanenv \
    --bind "$MG5_DATA_DIR:/madgraph" \
    --bind "$SCRIPT_DIR/compile_all.sh:/madgraph/compile_all.sh" \
    "$SIF" \
    bash -c 'source /madgraph/compile_all.sh && cd /madgraph && python mg-pipeline/run.py "$@"' \
    -- "$@"
