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
git clone <repo-url>
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
> cloned yet (see [running the pipeline](running-the-pipeline.md)). That is only
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
