<!-- Generated from docs/ by scripts/build_readme.py — do not edit directly. -->

# hep-pipeline-env

A Docker/Apptainer environment for running a high-energy physics Monte Carlo
pipeline: **MadGraph → MadSpin → Pythia → Rivet**.

This repository supports two deployment targets:

- **[Apptainer (HPC)](docs/apptainer.md)** — for HPC clusters where Docker is unavailable (e.g. Aristotle)
- **[Docker](docs/docker.md)** — for local workstations and CI

Both targets share the same `compile_all.sh` build script and `mg5_data/`
workspace layout.

## Where to next

- [Apptainer (HPC)](docs/apptainer.md) — build `.sif`, run on the cluster, batch jobs
- [Docker](docs/docker.md) — first-time bootstrap and day-to-day use on a workstation
- [Running the pipeline](docs/running-the-pipeline.md) — running `mg-pipeline` inside this environment
- [Troubleshooting](docs/troubleshooting.md) — common issues

# Apptainer (HPC)

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
See [running the pipeline](docs/running-the-pipeline.md) for prerequisites.

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

# Docker

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (v20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2+)

## How Docker works here (read this first)

If you have never used Docker, the mental model is simple:

- A **container** is a disposable, isolated Linux machine that runs on your
  computer. It is created from an **image** (a snapshot of the OS + tools).
- Your work lives in **`mg5_data/`** on your host machine. That folder is
  *bind-mounted* into the container at `/madgraph`, so anything you create
  inside the container is really being written to `mg5_data/` on your host.
- The container itself is **throwaway**. This project starts it with
  `docker compose run --rm`, so when you `exit`, the container is deleted —
  but `mg5_data/` (and everything in it) **persists**. Nothing is lost.

So the workflow is always the same two commands:

| When | Command | What happens |
|------|---------|--------------|
| **First time only** | `./bootstrap.sh` | Builds the image and compiles the HEP stack (slow, one-off) |
| **Every time after** | `./run.sh` | Re-enters the environment instantly (no recompile) |

You do **not** need to run `bootstrap.sh` again after the first time. Just use
`./run.sh` whenever you want to work.

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/iakovts/hep-pipeline-env.git
cd hep-pipeline-env
```

### 2. First time only: run the bootstrap script

```bash
./bootstrap.sh
```

This creates `mg5_data/`, builds the Docker image, and starts the container for
the first time. On this first entry the HEP stack is downloaded and compiled
into `mg5_data/` — **this takes a long time (roughly 1–2 hours)** and only
happens once. When it finishes, a marker file `mg5_data/.bootstrap_done` is
written so future starts skip the compile.

> **Tip:** You can leave it running and come back later. If it is interrupted,
> just run `./bootstrap.sh` again — completed steps are skipped.

### 3. Exiting the container

When you are done working, type:

```bash
exit
```

This closes the shell and removes the container (because of `--rm`). Your files
in `mg5_data/` are untouched.

### 4. Re-entering later

To come back to the environment, run:

```bash
./run.sh
```

This starts a fresh container and restores the HEP environment automatically —
no recompilation. You can run this as many times as you like.

> **Note:** `./run.sh` will print a reminder if `mg-pipeline` has not been
> cloned yet (see [running the pipeline](docs/running-the-pipeline.md)). That is only
> a hint — the environment still opens normally.

### 5. Manual recovery or reloading

If you enter an already-running container with `docker compose exec`, or if you
want to reload the environment manually, source the script inside the container:

```bash
source compile_all.sh
```

On first bootstrap this downloads and compiles (in order):

1. **ROOT** — data analysis framework (precompiled binary)
2. **MadGraph5_aMC@NLO** — matrix element generator
3. **LHAPDF** — parton distribution function library
4. **YODA** — data analysis histogramming
5. **FastJet** + **fjcontrib** — jet clustering
6. **HepMC3** — event record format
7. **Rivet** — analysis framework
8. **Pythia 8** — parton shower / hadronisation

The first compilation takes a while. Subsequent container starts reuse the
compiled libraries in `mg5_data/` and restore the environment automatically.
You can still re-source the script manually if needed:

```bash
source compile_all.sh
```

> **Tip:** You can also call individual build functions after sourcing, e.g.
> `build_pythia`, to rebuild a single component.

## Manual alternative to bootstrap.sh

`./bootstrap.sh` is just a convenience wrapper. If you prefer to run the steps
yourself (or need to debug one of them):

```bash
mkdir -p mg5_data          # create the workspace first (see note below)
docker compose build       # build the image
docker compose run --rm madgraph_p3   # start the container (compiles on first run)
```

> **Why create `mg5_data/` manually?** Docker Compose auto-creates missing
> bind-mount directories as `root:root`. Creating it yourself (or letting
> `bootstrap.sh` do it) ensures it is owned by your user.

## File Permissions (PUID / PGID)

The container creates an internal user with UID/GID matching the `PUID`/`PGID`
environment variables from `docker-compose.yml` (default: 1000). Files written
to `mg5_data/` will be owned by this UID on the host, so you can read and edit
them without `sudo`.

Concretely, ownership is handled in three places:

1. `bootstrap.sh` creates `mg5_data/` on the host as **your** user.
2. `entrypoint.sh` runs as root, creates the `madgraph` user with
   `UID=PUID`/`GID=PGID`, and `chown`s the `/madgraph` mount point to that user.
3. All work runs via `gosu madgraph`, so every new file is owned by `PUID:PGID`.

> **Note:** The `chown` in step 2 is **not recursive** — it only fixes the
> top-level `/madgraph` directory. Files left over from an older run that are
> already owned by `root` will not be repaired automatically. If you hit this,
> fix them once with `sudo chown -R "$(id -u):$(id -g)" mg5_data/`.

To use a different UID/GID, edit `docker-compose.yml`:

```yaml
environment:
  - PUID=1001   # your host UID (run: id -u)
  - PGID=1001   # your host GID (run: id -g)
```

## Project Structure

```
.
├── Dockerfile           # Image definition (Ubuntu 22.04 + build tools)
├── docker-compose.yml   # Container configuration
├── entrypoint.sh        # Creates non-root user from PUID/PGID
├── compile_all.sh       # Downloads & compiles all HEP libraries
├── .dockerignore        # Excludes mg5_data from build context
├── mg5_data/            # Persistent workspace (bind-mounted into container)
└── README.md
```

# Running the pipeline

`mg-pipeline` is a Python orchestration tool that drives the
MadGraph→MadSpin→Pythia→Rivet pipeline. It is maintained in the
[mg-pipeline](https://github.com/iakovts/mg-pipeline) repository and is designed
to run inside this container environment.

> **Note:** `bootstrap.sh` / `hpc_bootstrap.sh` clone `mg-pipeline` into
> `mg5_data/mg-pipeline` automatically. If you skipped that, or want a fresh
> copy, clone it by hand:

## Setup

Clone `mg-pipeline` into `mg5_data/`:

```bash
git clone https://github.com/iakovts/mg-pipeline mg5_data/mg-pipeline
```

The `mg5_data/` directory is bind-mounted as `/madgraph` inside the container,
so the pipeline will be available at `/madgraph/mg-pipeline/` inside the container.

You will also need your MadGraph scripts and MadSpin cards in the corresponding
directories:

```
mg5_data/
  madgraph_scripts/    # .txt scripts consumed by MadGraph
  madspin_scripts/     # MadSpin decay card files
  analysis/            # Rivet analysis .cc files
  mg-pipeline/         # mg-pipeline checkout
```

## Running interactively

Inside the container (after `source /madgraph/compile_all.sh`):

```bash
cd /madgraph
python mg-pipeline/run.py --stages madgraph,madspin,pythia,rivet
python mg-pipeline/run.py --help   # see all options
```

## Running as a batch job

```bash
sbatch hpc_pipeline_job.sh --stages madgraph,madspin,pythia,rivet
```

`hpc_pipeline_job.sh` handles all module loading, container entry, and
environment setup automatically. Logs go to `logs/pipeline_<jobid>.out`.

# Troubleshooting

## Permission denied on `mg5_data/` files

Check that `PUID`/`PGID` in `docker-compose.yml` match your host user. Run
`id -u` and `id -g` to find your UID and GID.

## Compilation fails mid-way

The script sources all build functions into your shell. You can re-run just
the failing step:

```bash
source compile_all.sh   # loads the functions
build_pythia             # re-run only Pythia
```

## Container lost environment after restart

Libraries persist in `mg5_data/`, but environment variables (`PATH`,
`LD_LIBRARY_PATH`, etc.) don't survive restarts. Re-source the script to
restore them:

```bash
source compile_all.sh
```

## On the HPC (Apptainer)

On Aristotle the user's home directory is writable inside the container, so
`pip install --user` works without extra configuration. On other HPC systems
with a read-only home directory, set `PYTHONUSERBASE` to a writable path (or
install to a custom `--target` directory) before installing packages.
