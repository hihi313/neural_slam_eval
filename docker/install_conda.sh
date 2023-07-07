#!/bin/bash --login

# Enable tracing
set -x

CONDA_DPDS=curl
CONDA_DIR=$1
CONDA_URL=$2

# Install dependencies
apt update
apt install --yes --no-install-recommends ${CONDA_DPDS}

# Install conda
curl -sLo ./miniconda.sh ${CONDA_URL}
chmod +x ./miniconda.sh
./miniconda.sh -b -p ${CONDA_DIR}
# echo "export PATH=${CONDA_DIR}/bin:${PATH}" >> ~/.bashrc
source ${CONDA_DIR}/bin/activate
conda init bash

# Remove dependencies
conda clean -ya
rm -rf /var/lib/apt/lists/* 
apt clean
apt purge --yes ${CONDA_DPDS}
apt autoremove --purge --yes
# Disable tracing
set +x