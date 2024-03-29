ARG CUDA_DOCKER_VERSION=11.3.1-cudnn8-devel-ubuntu18.04
FROM nvidia/cuda:${CUDA_DOCKER_VERSION}

# Arguments for the build. CUDA_DOCKER_VERSION needs to be repeated because
# the first usage only applies to the FROM tag.
# TensorFlow version is tightly coupled to CUDA and cuDNN so it should be selected carefully
ARG PYTORCH_VERSION=1.11.0+cu113
ARG PYTORCH_LIGHTNING_VERSION=1.2.9
ARG TORCHVISION_VERSION=0.12.0+cu113
ARG MY_NCCL_VERSION=2.9.8-1+cuda11.3

ARG PYSPARK_PACKAGE=pyspark==3.1.1
ARG SPARK_PACKAGE=spark-3.1.1/spark-3.1.1-bin-hadoop2.7.tgz

# Python 3.7 is supported by Ubuntu Bionic out of the box
ARG PYTHON_VERSION=3.8

# Set default shell to /bin/bash
SHELL ["/bin/bash", "-cu"]


RUN apt-get update && apt-get install -y --allow-downgrades --allow-change-held-packages --no-install-recommends \
        build-essential \
        cmake \
        g++-7 \
        git \
        curl \
        vim \
        wget \
        ca-certificates \
        libnccl2=${MY_NCCL_VERSION} \
        libnccl-dev=${MY_NCCL_VERSION} \
        libjpeg-dev \
        libpng-dev \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-dev \
        python${PYTHON_VERSION}-distutils \
        librdmacm1 \
        libibverbs1 \
        ibverbs-providers \
        openjdk-8-jdk-headless \
        openssh-client \
        openssh-server \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Open MPI
RUN wget --progress=dot:mega -O /tmp/openmpi-3.0.0-bin.tar.gz https://github.com/horovod/horovod/files/1596799/openmpi-3.0.0-bin.tar.gz && \
    cd /usr/local && \
    tar -zxf /tmp/openmpi-3.0.0-bin.tar.gz && \
    ldconfig && \
    mpirun --version

# Allow OpenSSH to talk to containers without asking for confirmation
RUN mkdir -p /var/run/sshd
RUN cat /etc/ssh/ssh_config | grep -v StrictHostKeyChecking > /etc/ssh/ssh_config.new && \
    echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config.new && \
    mv /etc/ssh/ssh_config.new /etc/ssh/ssh_config

RUN ln -s /usr/bin/python${PYTHON_VERSION} /usr/bin/python

RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    rm get-pip.py

# Install PyTorch
RUN pip install --no-cache-dir \
    torch==${PYTORCH_VERSION} \
    torchvision==${TORCHVISION_VERSION} \
    -f https://download.pytorch.org/whl/${PYTORCH_VERSION/*+/}/torch_stable.html
RUN pip install --no-cache-dir pytorch_lightning==${PYTORCH_LIGHTNING_VERSION}

RUN pip install --no-cache-dir future typing packaging
RUN pip install --no-cache-dir \
    h5py


# Install Spark stand-alone cluster.
RUN wget --progress=dot:giga "https://www.apache.org/dyn/closer.lua/spark/${SPARK_PACKAGE}?action=download" -O - | tar -xzC /tmp; \
    archive=$(basename "${SPARK_PACKAGE}") bash -c "mv -v /tmp/\${archive/%.tgz/} /spark"

# Install PySpark.
RUN pip install --no-cache-dir ${PYSPARK_PACKAGE}

# Install Horovod, temporarily using CUDA stubs
RUN git clone https://github.com/horovod/horovod.git 
RUN echo $(pwd)
WORKDIR /horovod
COPY . .
RUN python setup.py sdist && \
    ldconfig /usr/local/cuda/targets/x86_64-linux/lib/stubs && \
    bash -c "HOROVOD_GPU_ALLREDUCE=NCCL HOROVOD_NCCL_LINK=SHARED HOROVOD_WITH_PYTORCH=1 pip install --no-cache-dir horovod[pytorch]" && \
    horovodrun --check-build && \
    ldconfig

# Check all frameworks are working correctly. Use CUDA stubs to ensure CUDA libs can be found correctly
# when running on CPU machine
WORKDIR "/horovod/examples"
RUN ldconfig /usr/local/cuda/targets/x86_64-linux/lib/stubs && \
    python -c "import horovod.torch as hvd; hvd.init()" && \
    ldconfig

# apex
RUN git clone https://github.com/NVIDIA/apex.git &&\
    cd apex &&\
    pip install -v --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" . &&\
    rm -rf ../apex

# mmcv
RUN pip install mmcv-full==1.5.2 -f https://download.openmmlab.com/mmcv/dist/cu113/torch1.11.0/index.html

RUN pip install deepspeed mpi4py
RUN pip install ftfy regex tqdm pyspng h5py timm matplotlib tensorboard
RUN pip install decord lpips ujson einops opencv-python lpips ujson einops
RUN pip install git+https://github.com/openai/CLIP.git

RUN export CUDA_HOME="/usr/local/cuda"
RUN echo "azureml dockerfile finished!"