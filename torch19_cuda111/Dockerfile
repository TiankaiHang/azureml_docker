# =====================================================================
# https://gitlab.com/nvidia/container-images/cuda/blob/master/dist/11.1.1/ubuntu18.04-x86_64/base/Dockerfile
FROM ubuntu:18.04

# LABEL maintainer "NVIDIA CORPORATION <cudatools@nvidia.com>"

RUN apt-get update && apt-get install -y wget && apt-get install -y --no-install-recommends \
    gnupg2 curl ca-certificates && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub | apt-key add - && \
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get purge --autoremove -y curl \
    && rm -rf /var/lib/apt/lists/*

ENV CUDA_VERSION 11.1.1
ENV CUDNN_VERSION 8.0.5.39

# For libraries in the cuda-compat-* package: https://docs.nvidia.com/cuda/eula/index.html#attachment-a
RUN apt-get update && apt-get install -y --no-install-recommends \
    cuda-cudart-11-1=11.1.74-1 \
    cuda-compat-11-1 \
    && ln -s cuda-11.1 /usr/local/cuda && \
    libcudnn8=$CUDNN_VERSION-1+cuda11.1 \
    && apt-mark hold libcudnn8 && \
    rm -rf /var/lib/apt/lists/*

ENV PATH="/root/miniconda3/bin:${PATH}"
ARG PATH="/root/miniconda3/bin:${PATH}"

RUN wget \
    https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && mkdir /root/.conda \
    && bash Miniconda3-latest-Linux-x86_64.sh -b \
    && rm -f Miniconda3-latest-Linux-x86_64.sh 

# Required for nvidia-docker v1
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf \
    && echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

# COPY NGC-DL-CONTAINER-LICENSE /

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=11.1 brand=tesla,driver>=418,driver<419 brand=tesla,driver>=440,driver<441 driver>=450"

# =====================================================================
# FROM mcr.microsoft.com/azureml/base-gpu:openmpi3.1.2-cuda10.1-cudnn7-ubuntu18.04

# Install basic dependencies
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
RUN ln -s /opt/miniconda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/miniconda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "export PATH=/opt/miniconda/bin:$PATH" >> ~/.bashrc
# very important!!!!!!!
ENV PATH /opt/miniconda/bin:$PATH
RUN conda update -n base conda

#ImportError: No module named ruamel.yaml
RUN conda install -c r -y conda python=3.7 pip=20.1.1

# Install general libraries
RUN conda install -y numpy scipy ipython mkl scikit-learn matplotlib pandas setuptools Cython h5py graphviz
#dcm read problem
RUN conda install -c conda-forge gdcm -y
RUN conda clean -ya
RUN conda install -y mkl-include cmake cffi typing cython
RUN conda install -y -c mingfeima mkldnn
# RUN pip install boto3 addict tqdm regex pyyaml opencv-python torchsummary azureml_core==1.10.0 azureml-sdk==1.10.0 albumentations pretrainedmodels efficientnet_pytorch scikit-image==0.15  yacs git+https://github.com/qiuzhongwei-USTB/ResNeSt.git tensorboard pydicom
RUN pip install boto3 addict tqdm regex pyyaml opencv-python torchsummary albumentations==0.4.6 pretrainedmodels efficientnet_pytorch scikit-image==0.15  yacs tensorboard==2.0.1 joblib

# Install pytorch
# RUN conda install pytorch torchvision cudatoolkit=10.1 -c pytorch
RUN pip3 install torch==1.9.0+cu111 torchvision==0.10.0+cu111 torchaudio==0.9.0 -f https://download.pytorch.org/whl/torch_stable.html
RUN conda install -y -c conda-forge pillow=6.2.1

RUN pip install mmcv-full==1.3.9 -f https://download.openmmlab.com/mmcv/dist/cu111/torch1.9.0/index.html
RUN pip install mmsegmentation
RUN pip install terminaltables
RUN pip install lpips

# install mmediting
RUN git clone https://github.com/open-mmlab/mmediting.git /mmediting
WORKDIR /mmediting

RUN pip install cython --no-cache-dir
RUN pip install --no-cache-dir -e .

# Set CUDA_ROOT
RUN export CUDA_HOME="/usr/local/cuda"

RUN echo "azureml dockerfile finished!"