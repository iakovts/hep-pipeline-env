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
