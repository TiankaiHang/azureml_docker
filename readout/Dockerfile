# https://hub.docker.com/r/pytorch/pytorch/tags

# dvel mode has nvcc while runtime does not
# FROM pytorch/pytorch:2.0.0-cuda11.7-cudnn8-devel

# docker used for singularity (cuda-11.6)
FROM nvcr.io/nvidia/pytorch:23.04-py3
ARG DEBIAN_FRONTEND=noninteractive

# install some basic tools
RUN apt-get update && apt-get install -y --no-install-recommends \
        --allow-change-held-packages \
        build-essential \
        autotools-dev \
        rsync \
        curl \
        cmake \
        wget \
        vim \
        tmux \
        htop \
        git \
        unzip \
        ca-certificates \
        libjpeg-dev \
        htop \ 
        sudo \
        g++ \
        gcc \
        apt-utils \
        libosmesa6-dev \
        net-tools

RUN export LIBRARY_PATH=/usr/local/lib:$LIBRARY_PATH
# Set timezone
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
# very important!!!!!!!
ENV CONDA_DIR /opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH
RUN ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "export PATH=/opt/conda/bin:$PATH" >> ~/.bashrc

# for instructpix2pix
RUN conda env create -f https://github.com/TiankaiHang/storage/releases/download/v4/environment.yaml
RUN conda init bash
RUN echo "conda activate readout" >> ~/.bashrc
# very important!!!!!!!
ENV PATH /opt/conda/bin:$PATH

RUN whereis python
RUN /opt/conda/envs/readout/bin/python -c "import pytorch_lightning as pl; print(pl.__version__)"
ENV CUDA_HOME "/usr/local/cuda-12.1"
RUN echo "Docker Built Successfully"