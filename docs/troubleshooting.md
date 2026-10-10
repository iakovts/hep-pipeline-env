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
