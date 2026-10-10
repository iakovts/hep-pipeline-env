# hep-pipeline-env

A Docker/Apptainer environment for running a high-energy physics Monte Carlo
pipeline: **MadGraph → MadSpin → Pythia → Rivet**.

This repository supports two deployment targets:

- **[Apptainer (HPC)](apptainer.md)** — for HPC clusters where Docker is unavailable (e.g. Aristotle)
- **[Docker](docker.md)** — for local workstations and CI

Both targets share the same `compile_all.sh` build script and `mg5_data/`
workspace layout.

## Where to next

- [Apptainer (HPC)](apptainer.md) — build `.sif`, run on the cluster, batch jobs
- [Docker](docker.md) — first-time bootstrap and day-to-day use on a workstation
- [Running the pipeline](running-the-pipeline.md) — running `mg-pipeline` inside this environment
- [Troubleshooting](troubleshooting.md) — common issues
