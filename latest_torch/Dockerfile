# Thanks Jia Ning

FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

# Labels for the docker
LABEL description="This docker has pytorch 2.0 with cuda 11.8, and cudnn 8.0." \
      tag="pytorch2.0-cuda11.8-openmpi" \
      creator="ninja" tooltype="pytorch" \
      tooltypeversion="2.0" \
      createtime="03/15/2024"

USER root:root

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

ENV DEBIAN_FRONTEND=noninteractive

ENV LD_LIBRARY_PATH=/usr/local/cuda/extras/CUPTI/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64

ENV NCCL_DEBUG=INFO

ENV HOROVOD_GPU_ALLREDUCE=NCCL

RUN apt-get update && apt-get install -y --no-install-recommends \
    libmlx4-1 \
    libmlx5-1 \
    librdmacm1 \
    libibverbs1 \
    libmthca1 \
    libdapl2 \
    dapl2-utils openssh-client \
    openssh-server \
    iproute2 && \
    apt-get install -y \
    build-essential \
    bzip2 \
    git \
    tmux \
    wget \
    unzip \
    net-tools \
    libjpeg-dev \
    libpng-dev \
    ca-certificates \
    libopenblas-dev \
    libopencv-dev \
    libyaml-dev \
    ffmpeg libsm6 libxext6 \
    cpio software-properties-common && \
    apt-get update && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/anaconda.sh && \
    sh ~/anaconda.sh -b -p /opt/conda && \
    rm ~/anaconda.sh

ENV PATH=/opt/conda/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ENV OPENMPI_VERSION=4.1.5

RUN mkdir /tmp/openmpi && \
    cd /tmp/openmpi && \
    wget https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-${OPENMPI_VERSION}.tar.gz && \
    tar zxf openmpi-${OPENMPI_VERSION}.tar.gz && \
    cd openmpi-${OPENMPI_VERSION} && \
    ./configure --enable-orterun-prefix-by-default && \
    make -j $(nproc) all && \
    make install && \
    ldconfig && \
    rm -rf /tmp/openmpi

RUN export CUDA_HOME="/usr/local/cuda"

RUN pip install terminaltables

RUN pip install future tensorboard

RUN conda config --add channels conda-forge

# install pytorch2.0
RUN conda create -n torch python=3.10 -y
# RUN conda install -y numpy pyyaml scipy ipython mkl scikit-learn matplotlib pandas setuptools Cython h5py graphviz
# RUN conda activate torch
SHELL ["conda", "run", "-n", "torch", "/bin/bash", "-c"]
RUN conda install -y numpy pyyaml scipy ipython mkl scikit-learn matplotlib pandas setuptools Cython h5py graphviz

RUN conda clean -ya

# RUN conda install -y mkl-include cmake cffi typing cython

RUN pip install jinja2

# RUN git clone --recursive https://github.com/pytorch/pytorch -b v2.0.0-rc3 && \
#     cd pytorch && \
#     git submodule sync && \
#     git submodule update --init --recursive && \
#     pip install -r requirements.txt && \
#     export CMAKE_PREFIX_PATH=${CONDA_PREFIX:-"$(dirname $(which conda))/../"} && \
#     pip install .

RUN add-apt-repository ppa:ubuntu-toolchain-r/test && apt-get update && apt-get upgrade libstdc++6 -y && apt-get clean -y

# torch 2.0.1 stable release
RUN pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Add Tini
ENV TINI_VERSION v0.19.0
RUN wget --no-check-certificate --no-cookies --quiet https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-amd64 \
    && wget --no-check-certificate --no-cookies --quiet https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-amd64.sha256sum \
    && echo "$(cat tini-amd64.sha256sum)" | sha256sum -c

RUN apt-get install jq -y
RUN apt-get update && DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y netbase autossh pdsh supervisor \
    cifs-utils nfs-common mergerfs fuse
RUN pip install tensorboard

# check if valid for sing
# FROM singularitybase.azurecr.io/validations/base/singularity-tests:20220531T113427269 AS validator
# COPY --from=validator /validations /opt/microsoft/_singularity/validations/
# COPY validations /opt/microsoft/_singularity/validations/
# ENV SINGULARITY_IMAGE_ACCELERATOR=NVIDIA
# RUN /opt/microsoft/_singularity/validations/validator.sh

# xformers
RUN pip install ninja
RUN pip install -v -U git+https://github.com/facebookresearch/xformers.git@main#egg=xformers

# apex
RUN git clone https://github.com/NVIDIA/apex.git \
    && cd apex \
    && git checkout 741bdf50825a97664db08574981962d66436d16a \
    && pip install -v --disable-pip-version-check --no-cache-dir --no-build-isolation --config-settings "--build-option=--cpp_ext" --config-settings "--build-option=--cuda_ext" ./ --global-option="--cuda_ext" --global-option="--cpp_ext"


WORKDIR /root
ENTRYPOINT ["/bin/bash", "-c", "source activate torch && exec bash"] 