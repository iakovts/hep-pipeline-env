#!/bin/bash

if [[ $_ == $0 ]] ; then
  echo "You need to source the script"
  exit 1
fi

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKER_FILE="$BASEDIR/.bootstrap_done"

# If running on lxplus, set up the ATLAS environment. Else we're on Docker.
# Running locally will probably need some more adjustments.
# Uncomment the block below if you need lxplus support:
#
# if [ -f /.dockerenv ] || grep -qa docker /proc/1/cgroup; then
#   echo "Inside Docker - skipping ATLAS setup"
# else
#   echo "On Host - setting up ATLAS environment"
#   . "${ATLAS_LOCAL_ROOT_BASE}/user/atlasLocalSetup.sh"
#   lsetup "gcc gcc620_x86_64_slc6"
#   lsetup "root 6.14.04-x86_64-slc6-gcc62-opt"
# fi

fetch_and_unpack() {
  local url="$1"
  local archive="$2"
  run_step wget "$url" -O "$archive" || return 1
  run_step tar -xf "$archive" || return 1
  rm -f "$archive"
}

run_step() {
  "$@"
  local status=$?
  [[ $status -eq 0 ]] || echo "Error: $*"
  return $status
}

# Get ROOT and run thisroot.sh to set up environment
# https://root.cern/download/root_v6.36.04.Linux-ubuntu22.04-x86_64-gcc11.4.tar.gz
### !!! This download precompiled root  for ubuntu22.04. 
get_root() {
  local version="6.36.04"
  local archive="root_v${version}.Linux-ubuntu22.04-x86_64-gcc11.4.tar.gz"
  local url="https://root.cern/download/${archive}"
  fetch_and_unpack "$url" "$archive" || return 1
  echo "ROOT Version: ${version} downloaded and extracted"
  # ROOT tarballs extract to a directory called "root"
  source "$BASEDIR/root/bin/thisroot.sh"
  echo "ROOT environment set up. ROOTSYS=${ROOTSYS}"
}

# Download madgraph - no need to compile
get_madgraph() {
  local version="3.5.13"
  local archive="MG5_aMC_v${version}.tar.gz"
  local url="https://launchpad.net/mg5amcnlo/3.0/3.6.x/+download/${archive}"
  fetch_and_unpack "$url" "$archive" || return 1
  echo "MadGraph Version: ${version} downloaded and extracted"
}

# Download and install LHAPDF
# https://lhapdf.hepforge.org/downloads/?f=LHAPDF-6.5.5.tar.gz
build_lhapdf() {
  local version="6.5.5"
  local archive="LHAPDF-${version}.tar.gz"
  local url="https://lhapdf.hepforge.org/downloads/?f=${archive}"
  fetch_and_unpack "$url" "$archive" || return 1
  run_step cd "LHAPDF-${version}" || return 1
  run_step ./configure PYTHON=python3 --prefix="$PWD/gcc620_x86_64-slc6" || return 1
  run_step make -j12 || return 1
  run_step make install || return 1
  export PATH="$PATH:$PWD/gcc620_x86_64-slc6/bin"
  run_step cd "$BASEDIR" || return 1
}

# Download and compile YODA
# https://yoda.hepforge.org/downloads?f=YODA-2.1.1.tar.gz
build_yoda() {
  local version="2.1.1"
  local archive="YODA-${version}.tar.gz"
  local url="https://yoda.hepforge.org/downloads/?f=${archive}"
  fetch_and_unpack "$url" "$archive" || return 1
  run_step cd "YODA-${version}" || return 1
  run_step ./configure --prefix="$PWD/gcc620_x86_64-slc6" --enable-root || return 1
  run_step make -j12 || return 1
  run_step make install || return 1
  run_step cd "$BASEDIR" || return 1
}

# Then download and compile fastjet
# https://fastjet.fr/repo/fastjet-3.4.0.tar.gz
build_fastjet() {
  local version="3.4.0"
  local archive="fastjet-${version}.tar.gz"
  local url="http://fastjet.fr/repo/${archive}"
  fetch_and_unpack "$url" "$archive" || return 1
  run_step cd "fastjet-${version}" || return 1
  run_step ./configure --enable-allcxxplugins --prefix="$PWD/gcc620_x86_64-slc6" || return 1
  run_step make -j12 || return 1
  run_step make install || return 1
  run_step cd "$BASEDIR" || return 1
}

# Then download and compile fjcontrib
# https://fastjet.fr/contrib/downloads/fjcontrib-1.056.tar.gz
build_fjcontrib() {
  local version="1.056"
  local archive="fjcontrib-${version}.tar.gz"
  local url="http://fastjet.hepforge.org/contrib/downloads/${archive}"
  fetch_and_unpack "$url" "$archive" || return 1
  run_step cd "fjcontrib-${version}" || return 1
  run_step ./configure --prefix="$PWD/gcc620_x86_64-slc6" --fastjet-config="$BASEDIR/fastjet-3.4.0/gcc620_x86_64-slc6/bin/fastjet-config" || return 1
  run_step make -j12 || return 1
  run_step make install || return 1
  run_step make fragile-shared-install || return 1
  run_step cd "$BASEDIR" || return 1
}

# Then download and compile HepMC3
# https://hepmc.web.cern.ch/hepmc/releases/HepMC3-3.3.1.tar.gz
build_hepmc3() {
  local version="3.3.1"
  local archive="HepMC3-${version}.tar.gz"
  local url="http://hepmc.web.cern.ch/hepmc/releases/${archive}"
  fetch_and_unpack "$url" "$archive" || return 1
  run_step cd "HepMC3-${version}" || return 1
  run_step mkdir build || return 1
  run_step cd build || return 1
  run_step cmake -DCMAKE_INSTALL_PREFIX="$PWD/gcc620_x86_64-slc6" -DHEPMC3_ENABLE_ROOTIO:BOOL=OFF -DHEPMC3_ENABLE_PYTHON:BOOL=OFF -Dmomentum:STRING=GEV -Dlength:STRING=MM ../ || return 1
  run_step cmake --build . -j12 || return 1
  run_step cmake --install . || return 1
  run_step cd "$BASEDIR" || return 1
}

# Then download and compile RIVET
# https://rivet.hepforge.org/downloads/?f=Rivet-4.1.1.tar.gz
build_rivet() {
  local version="4.1.1"
  local archive="Rivet-${version}.tar.gz"
  local url="https://rivet.hepforge.org/downloads/?f=${archive}"
  fetch_and_unpack "$url" "$archive" || return 1
  run_step cd "Rivet-${version}" || return 1
  run_step ./configure --prefix="$PWD/gcc620_x86_64-slc6" \
    --with-yoda="$BASEDIR/YODA-2.1.1/gcc620_x86_64-slc6" \
    --with-fastjet="$BASEDIR/fastjet-3.4.0/gcc620_x86_64-slc6" \
    --with-fjcontrib="$BASEDIR/fjcontrib-1.056/gcc620_x86_64-slc6" \
    --with-hepmc="$BASEDIR/HepMC3-3.3.1/build/gcc620_x86_64-slc6" || return 1
  run_step make -j12 || return 1
  run_step make install || return 1
  run_step cd "$BASEDIR" || return 1
}

# Download and compile pythia
# https://pythia.org/download/pythia83/pythia8316.tgz
build_pythia() {
  local version="8316"
  local archive="pythia${version}.tgz"
  local url="https://www.pythia.org/download/pythia83/${archive}" 
  fetch_and_unpack "$url" "$archive" || return 1
  run_step cd "pythia${version}" || return 1
  run_step ./configure --prefix="$PWD/gcc620_x86_64-slc6" \
    --with-fastjet3="$BASEDIR/fastjet-3.4.0/gcc620_x86_64-slc6" \
    --with-hepmc3="$BASEDIR/HepMC3-3.3.1/build/gcc620_x86_64-slc6" \
    --with-lhapdf6="$BASEDIR/LHAPDF-6.5.5/gcc620_x86_64-slc6" \
    --with-rivet="$BASEDIR/Rivet-4.1.1/gcc620_x86_64-slc6" \
    --with-yoda="$BASEDIR/YODA-2.1.1/gcc620_x86_64-slc6" \
    --with-root="$ROOTSYS" || return 1
  run_step make -j12 || return 1
  run_step make install || return 1
  run_step cd "$BASEDIR" || return 1
}

# Set up environment variables for all compiled libraries
setup_env() {
  local PYTHON_VERSION
  PYTHON_VERSION="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
  local LHAPDF_DIR="$BASEDIR/LHAPDF-6.5.5/gcc620_x86_64-slc6"
  local YODA_DIR="$BASEDIR/YODA-2.1.1/gcc620_x86_64-slc6"
  local FASTJET_DIR="$BASEDIR/fastjet-3.4.0/gcc620_x86_64-slc6"
  local FJCONTRIB_DIR="$BASEDIR/fjcontrib-1.056/gcc620_x86_64-slc6"
  local HEPMC3_DIR="$BASEDIR/HepMC3-3.3.1/build/gcc620_x86_64-slc6"
  local RIVET_DIR="$BASEDIR/Rivet-4.1.1/gcc620_x86_64-slc6"
  local PYTHIA_DIR="$BASEDIR/pythia8316/gcc620_x86_64-slc6"
  local PYTHIA_EXAMPLES_DIR="$BASEDIR/pythia8316/examples"
  local MG5_DIR="$BASEDIR/MG5_aMC_v3_5_13"
  local MG5_HEPTOOLS_DIR="$MG5_DIR/HEPTools"
  local LHAPDF_PYTHON_DIR="$LHAPDF_DIR/lib/python${PYTHON_VERSION}/site-packages"
  local YODA_PYTHON_DIR="$YODA_DIR/lib/python${PYTHON_VERSION}/site-packages"
  local RIVET_PYTHON_DIR="$RIVET_DIR/lib/python${PYTHON_VERSION}/site-packages"

  if [[ -r "$BASEDIR/root/bin/thisroot.sh" ]]; then
    source "$BASEDIR/root/bin/thisroot.sh"
  fi

  if [[ -r "$BASEDIR/Rivet-4.1.1/rivetenv.sh" ]]; then
    source "$BASEDIR/Rivet-4.1.1/rivetenv.sh"
  fi

  export PATH="$MG5_DIR/bin:$MG5_HEPTOOLS_DIR/bin:$LHAPDF_DIR/bin:$YODA_DIR/bin:$FASTJET_DIR/bin:$RIVET_DIR/bin:$PYTHIA_DIR/bin:$PYTHIA_EXAMPLES_DIR:$PATH"
  export LD_LIBRARY_PATH="$MG5_HEPTOOLS_DIR/lib:$LHAPDF_DIR/lib:$YODA_DIR/lib:$FASTJET_DIR/lib:$FJCONTRIB_DIR/lib:$HEPMC3_DIR/lib:$RIVET_DIR/lib:$PYTHIA_DIR/lib:$PYTHIA_EXAMPLES_DIR:${LD_LIBRARY_PATH:-}"
  export PYTHONPATH="$LHAPDF_PYTHON_DIR:$YODA_PYTHON_DIR:$RIVET_PYTHON_DIR:${PYTHONPATH:-}"
  # Explicit env vars consumed by mg-pipeline's config.py resolution logic
  export PYTHIA8="$PYTHIA_DIR"
  export PYTHIA8_EXAMPLES="$PYTHIA_EXAMPLES_DIR"
  export MADGRAPH="$MG5_DIR"
  export RIVET_ROOT="$RIVET_DIR"

  echo "Environment variables set for all HEP libraries."
}

# Compile Pythia examples needed by the pipeline
post_build() {
  echo "Installing Python dependencies..."
  python -m pip install six matplotlib --user || return 1

  echo "Compiling Pythia examples..."
  run_step cd "$BASEDIR/pythia8316/examples" || return 1
  run_step make main134 || return 1
  run_step cd "$BASEDIR" || return 1

  echo "Cloning LHC-DMWG model repository into MadGraph models..."
  run_step git clone https://github.com/LHC-DMWG/model-repository.git /tmp/model-repository || return 1
  run_step mkdir -p "$BASEDIR/MG5_aMC_v3_5_13/models" || return 1
  run_step cp -r /tmp/model-repository/models/. "$BASEDIR/MG5_aMC_v3_5_13/models/" || return 1
  rm -rf /tmp/model-repository

  echo "Post-build steps complete."
}

main() {
  get_root || return 1
  get_madgraph || return 1
  build_lhapdf || return 1
  build_yoda || return 1
  build_fastjet || return 1
  build_fjcontrib || return 1
  build_hepmc3 || return 1
  build_rivet || return 1
  build_pythia || return 1
  post_build || return 1
  setup_env
  mkdir -p "$BASEDIR/analysis" "$BASEDIR/madspin_scripts" "$BASEDIR/madgraph_scripts"
  touch "$MARKER_FILE"
  echo "compile_all.sh script finished"
}

if [[ -f "$MARKER_FILE" ]]; then
  setup_env
else
  main "$@" || return 1
fi
