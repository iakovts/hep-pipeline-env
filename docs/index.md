## Overview

A Docker/Apptainer environment for running a high-energy physics Monte Carlo
pipeline: **MadGraph → MadSpin → Pythia → Rivet**.

This repository supports two deployment targets:

- **[Apptainer (HPC)](#apptainer-hpc)** — for HPC clusters where Docker is unavailable (e.g. Aristotle)
- **[Docker](#docker)** — for local workstations and CI

Both targets share the same `compile_all.sh` build script and `mg5_data/`
workspace layout.
- [Troubleshooting](troubleshooting.md) — common issues
