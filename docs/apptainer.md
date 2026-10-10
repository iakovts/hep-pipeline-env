## Apptainer (HPC)

Docker is not available on the Aristotle HPC. Apptainer (formerly Singularity)
is provided instead and works with the same `compile_all.sh` workflow.

> **Aristotle-specific assumption:** `hpc_run.sh` and `hpc_pipeline_job.sh` are
> tuned for Aristotle, where the user's home directory is NFS-mounted and
> writable inside the container. This means `pip install --user` and MadGraph's
> own internal package installs work correctly without extra configuration.
> On other HPC systems where the home directory is read-only inside the
> container, you may need to set `PYTHONUSERBASE` to a writable path or install
> packages to a custom `--target` directory.

## HPC-specific files

| File | Purpose |
|------|---------|
| `madgraph.def` | Apptainer definition file (equivalent of `Dockerfile`) |
| `hpc_bootstrap.sh` | One-time setup: builds `.sif` and compiles the HEP stack |
| `hpc_run.sh` | Interactive shell entry (equivalent of `run.sh`) |
| `hpc_pipeline_job.sh` | Batch job template for running the full pipeline via `mg-pipeline` |

## First-time setup (bootstrap)

Transfer the repository to your HPC home directory, then run the bootstrap
**directly on the login node**:

```bash
cd hep-pipeline-env
chmod +x hpc_bootstrap.sh hpc_run.sh hpc_pipeline_job.sh
mkdir -p logs
bash hpc_bootstrap.sh
```

Alternatively, submit as a batch job (useful if the build is very long):

```bash
sbatch hpc_bootstrap.sh
# Monitor with:
squeue -u $USER
tail -f logs/bootstrap_<jobid>.out
```

`hpc_bootstrap.sh` will:
1. Build `madgraph.sif` from `madgraph.def` using `apptainer build --fakeroot` (~5 min)
2. Create `mg5_data/` if it does not exist
3. Run `compile_all.sh` inside the container to compile all HEP libraries (~60–120 min)

When it finishes, `mg5_data/.bootstrap_done` is created. Re-running the script
skips steps that are already done.

## Day-to-day interactive use

After bootstrap completes, enter the container with:

```bash
./hpc_run.sh
```

This opens an interactive shell inside the Ubuntu 22.04 container. On entry, source
the environment:

```bash
source /madgraph/compile_all.sh
```

This restores `PATH`, `LD_LIBRARY_PATH`, and all other HEP environment variables
for the session. You only need to do this once per shell — all subprocesses
(including pipeline stages) will inherit the correct environment.

You are automatically your HPC user inside the container — no UID remapping is needed
(Apptainer handles this natively).

## Running the pipeline with sbatch

`hpc_pipeline_job.sh` is a ready-made sbatch template that runs the full
MadGraph→MadSpin→Pythia→Rivet pipeline inside the container using `mg-pipeline`.
See [running the pipeline](running-the-pipeline.md) for prerequisites.

All arguments after the script name are forwarded verbatim to `mg-pipeline/run.py`:

```bash
mkdir -p logs

# Run the full pipeline
sbatch hpc_pipeline_job.sh --stages madgraph,madspin,pythia,rivet

# Skip Rivet, run quietly
sbatch hpc_pipeline_job.sh --skip-rivet --quiet

# Resume an existing experiment
sbatch hpc_pipeline_job.sh --resume --intermediate-dir /madgraph/Experiments_2
```

The job sources `compile_all.sh` automatically, so no manual `source` is needed
in batch mode.

## Key differences from Docker

| | Docker | Apptainer (HPC) |
|---|---|---|
| Image file | Layers in daemon | `madgraph.sif` (single file) |
| Build image | `docker compose build` | `bash hpc_bootstrap.sh` (or `sbatch`) |
| Bootstrap HEP stack | `./bootstrap.sh` | `bash hpc_bootstrap.sh` (or `sbatch`) |
| Enter environment | `./run.sh` | `./hpc_run.sh` |
| User inside container | Remapped via entrypoint | Automatically your HPC user |
| Persistent data | `mg5_data/` bind mount | Same `mg5_data/` bind mount |
| Run pipeline as batch job | — | `sbatch hpc_pipeline_job.sh [args]` |
