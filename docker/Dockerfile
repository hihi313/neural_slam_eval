ARG DOCKER_ROOT=./docker
ARG CONDA_ENV=coslam
ARG CONDA_DIR=/miniconda
ARG CONDA_URL=https://repo.continuum.io/miniconda/Miniconda3-py39_4.10.3-Linux-x86_64.sh

#===============================================================================

FROM hihi313/co-slam:latest AS coslam
WORKDIR /tmp
USER root

ARG CONDA_ENV

# Make RUN commands use the new environment:
SHELL ["conda", "run", "-n", "base", "/bin/bash", "-c"]

# pack conda built env
RUN python3 -m pip install --no-cache-dir conda-pack \
    && conda pack --ignore-missing-files -n ${CONDA_ENV} -o ${CONDA_ENV}.tar.gz

#===============================================================================

FROM nvidia/cudagl:11.3.1-runtime-ubuntu20.04 AS conda
WORKDIR /tmp
USER root

ENV APT_SERVER=mirror://mirrors.ubuntu.com/mirrors.txt
ARG DOCKER_ROOT
ARG CONDA_DIR
ARG CONDA_URL
ARG SED_I="s#^\(\s*deb\s*\)\w*:\/\/\S*#\1${APT_SERVER}#g"

# Change faster apt server
RUN sed -i ${SED_I} /etc/apt/sources.list

COPY ./${DOCKER_ROOT}/install_conda.sh ./
RUN ./install_conda.sh ${CONDA_DIR} ${CONDA_URL} \
    && rm -rf /tmp/*
ENV PATH=${CONDA_DIR}/bin:${PATH}

#===============================================================================

From conda AS dpds
WORKDIR /tmp
USER root

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV TZ=Asia/Taipei
ARG DOCKER_ROOT
ARG CONDA_DIR
ARG CONDA_ENV
ARG DEBIAN_FRONTEND=noninteractive
ARG APT_DPDS=apt_packages.txt
ARG PY_DPDS=requirements.txt

COPY ${DOCKER_ROOT}/${APT_DPDS} ./
RUN apt update
RUN xargs apt install --yes --no-install-recommends < ${APT_DPDS} \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* ${APT_DPDS}

# recover conda env
COPY --from=coslam /tmp/${CONDA_ENV}.tar.gz ./
RUN mkdir -p ${CONDA_DIR}/envs/${CONDA_ENV} \
    && tar -xzf ${CONDA_ENV}.tar.gz -C ${CONDA_DIR}/envs/${CONDA_ENV}

RUN /bin/bash --login -c echo $PATH
# Make RUN commands use the new environment:
SHELL ["conda", "run", "-n", "coslam", "/bin/bash", "--login", "-c"]

COPY ${DOCKER_ROOT}/${PY_DPDS} ./
RUN python3 -m pip install --upgrade --no-cache-dir pip \
    && python3 -m pip install --no-cache-dir --requirement ${PY_DPDS} \
    && rm ${PY_DPDS}

# Clean up
RUN apt autoremove --purge --yes \
    && conda clean -ya \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /app

CMD ["bash", "--login"]

# TODO: remove ARG CONDA_URL