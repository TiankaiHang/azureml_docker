# https://hub.docker.com/r/pytorch/pytorch/tags

# dvel mode has nvcc while runtime does not
FROM pytorch/pytorch:2.0.0-cuda11.7-cudnn8-devel

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

RUN export LIBRARY_PATH=/usr/local/lib:$LIBRARY_PATH
# Set timezone
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
# very important!!!!!!!
RUN ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "export PATH=/opt/conda/bin:$PATH" >> ~/.bashrc
# very important!!!!!!!
ENV PATH /opt/conda/bin:$PATH
RUN conda update -n base conda

# for instructpix2pix
RUN conda env create -f https://github.com/timothybrooks/instruct-pix2pix/raw/main/environment.yaml
# RUN conda init bash
RUN echo "conda activate ip2p" >> ~/.bashrc

RUN echo "Docker Built Successfully"