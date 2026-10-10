# Running the pipeline

`mg-pipeline` is a Python orchestration tool that drives the
MadGraph→MadSpin→Pythia→Rivet pipeline. It is maintained in a
separate repository and is not bundled here, but is designed to run inside
this container environment.

> **Note:** `mg-pipeline` is **not** cloned automatically. Clone it
> manually into `mg5_data/` (see below). Once the public URL is final,
> the automatic clone in `bootstrap.sh` / `hpc_bootstrap.sh` can be re-enabled
> (look for the `TODO` markers in those scripts).

## Setup

After bootstrap, clone `mg-pipeline` into `mg5_data/`:

```bash
git clone <your-mg-pipeline-repo> mg5_data/mg-pipeline
```

<!-- TODO: restore the public URL once mg-pipeline is published.
     Upstream: https://github.com/iakovts/mg-pipeline -->

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
