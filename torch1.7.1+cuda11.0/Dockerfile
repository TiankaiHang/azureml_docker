# FROM mcr.microsoft.com/azureml/base-gpu:latest 
FROM mcr.microsoft.com/azureml/openmpi4.1.0-cuda11.0.3-cudnn8-ubuntu18.04

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
RUN apt update
RUN apt install libgl1-mesa-glx -y

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

RUN pip install torch==1.7.1+cu110 torchvision==0.8.2+cu110 torchaudio==0.7.2 -f https://download.pytorch.org/whl/torch_stable.html


# Set CUDA_ROOT
RUN export CUDA_HOME="/usr/local/cuda"

RUN echo "azureml dockerfile finished!"
