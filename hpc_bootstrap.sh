#!/bin/bash
#SBATCH -J hep-bootstrap
#SBATCH -p batch
#SBATCH -t 03:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH -o logs/bootstrap_%j.out
#SBATCH -e logs/bootstrap_%j.err
#
# One-time first-run setup for the MadGraph HEP pipeline on Aristotle HPC.
#
# Usage (from the repo root):
#   mkdir -p logs
#   sbatch hpc_bootstrap.sh          # submit as a batch job (recommended for full build)
#   bash hpc_bootstrap.sh             # run directly on a login node (fine for testing)
#
# Note: the compile step takes ~60-120 min. Login nodes may have a session time
# limit, so sbatch is recommended for the first full build. All steps have skip
# guards, so re-running after an interruption will pick up where it left off.
#
# What this script does:
#   1. Loads the Apptainer module
#   2. Builds madgraph.sif from madgraph.def (if not already built)
#   3. Creates mg5_data/ (if missing)
#   4. (mg-pipeline is NOT cloned automatically — clone it manually, see below)
#   5. Runs compile_all.sh inside the container to build all HEP libraries
#
# After this job completes successfully, use hpc_run.sh for day-to-day use.
# You do NOT need to re-run this unless you delete mg5_data/ or madgraph.sif.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIF="$SCRIPT_DIR/madgraph.sif"
DEF="$SCRIPT_DIR/madgraph.def"
MG5_DATA_DIR="$SCRIPT_DIR/mg5_data"
MG_PIPELINE_DIR="$MG5_DATA_DIR/mg-pipeline"
# TODO: restore the automatic clone once the public mg-pipeline URL is final.
# The clone is disabled for now. Clone it manually into mg5_data/mg-pipeline
# when needed.
# MG_PIPELINE_REPO="https://github.com/iakovts/mg-pipeline"
# compile_all.sh writes .bootstrap_done to its BASEDIR (= mg5_data/ inside container)
MARKER="$MG5_DATA_DIR/.bootstrap_done"

echo "=== MadGraph HEP Pipeline Bootstrap ==="
echo "Working directory: $SCRIPT_DIR"
echo "Apptainer image:   $SIF"
echo ""

# ---------------------------------------------------------------------------
# 1. Load Apptainer module
# ---------------------------------------------------------------------------
module load gcc/14.2.0 apptainer/1.3.4

# ---------------------------------------------------------------------------
# 2. Build the .sif image if not already present
# ---------------------------------------------------------------------------
if [[ -f "$SIF" ]]; then
    echo "[1/4] madgraph.sif already exists — skipping build."
else
    echo "[1/4] Building madgraph.sif from madgraph.def (this takes ~5 min)..."
    apptainer build --fakeroot "$SIF" "$DEF"
    echo "      madgraph.sif built successfully."
fi

# ---------------------------------------------------------------------------
# 3. Create mg5_data workspace directory
# ---------------------------------------------------------------------------
if [[ -d "$MG5_DATA_DIR" ]]; then
    echo "[2/4] mg5_data/ already exists — skipping."
else
    echo "[2/4] Creating mg5_data/..."
    mkdir -p "$MG5_DATA_DIR"
fi

# ---------------------------------------------------------------------------
# 4. Clone mg-pipeline  (disabled — clone manually when needed)
# ---------------------------------------------------------------------------
# TODO: restore the automatic clone once the public mg-pipeline URL is final.
# if [[ -d "$MG_PIPELINE_DIR/.git" ]]; then
#     echo "[3/4] mg-pipeline already cloned — skipping."
# elif [[ -e "$MG_PIPELINE_DIR" ]]; then
#     echo "Error: $MG_PIPELINE_DIR exists but is not a git checkout." >&2
#     exit 1
# else
#     echo "[3/4] Cloning mg-pipeline..."
#     git clone "$MG_PIPELINE_REPO" "$MG_PIPELINE_DIR"
# fi

# ---------------------------------------------------------------------------
# 5. Run compile_all.sh inside the container to build all HEP libraries
# ---------------------------------------------------------------------------
if [[ -f "$MARKER" ]]; then
    echo "[4/4] .bootstrap_done marker found — HEP libraries already compiled."
    echo "      Delete $MARKER to force a full rebuild."
else
    echo "[4/4] Running compile_all.sh inside container..."
    echo "      This will download and compile ROOT, MadGraph, LHAPDF, YODA,"
    echo "      FastJet, fjcontrib, HepMC3, Rivet, Pythia8."
    echo "      Expected time: 60-120 min depending on node speed."
    echo ""
    # Bind mg5_data/ as /madgraph inside the container (mirrors Docker layout).
    # compile_all.sh is overlaid so BASEDIR resolves to /madgraph and all
    # libraries are installed into mg5_data/.
    apptainer exec \
        --cleanenv \
        --bind "$MG5_DATA_DIR:/madgraph" \
        --bind "$SCRIPT_DIR/compile_all.sh:/madgraph/compile_all.sh" \
        "$SIF" \
        bash -c 'cd /madgraph && source /madgraph/compile_all.sh'
    echo "      Done."
fi

echo ""
echo "=== Bootstrap complete ==="
echo "To enter the environment interactively, run: ./hpc_run.sh"
