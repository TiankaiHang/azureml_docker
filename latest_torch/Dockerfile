# https://hub.docker.com/r/pytorch/pytorch/tags

# dvel mode has nvcc while runtime does not
FROM pytorch/pytorch:1.12.1-cuda11.3-cudnn8-devel

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
        libnccl2 \
        libnccl-dev \
        ca-certificates \
        libjpeg-dev \
        htop \ 
        sudo \
        g++ \
        gcc \
        apt-utils \
        libosmesa6-dev \
        net-tools

# upgrade
RUN pip install torch torchvision torchaudio --upgrade --extra-index-url https://download.pytorch.org/whl/cu113

# apex
RUN pip install packaging
RUN git clone https://github.com/NVIDIA/apex.git && \
    cd apex && \
    pip install -v --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" . &&\
    rm -rf ../apex