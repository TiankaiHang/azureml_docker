# FROM mcr.microsoft.com/azureml/base-gpu:latest 
FROM mcr.microsoft.com/azureml/base-gpu:openmpi3.1.2-cuda10.1-cudnn7-ubuntu18.04

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
RUN pip install torch==1.7.0+cu101 torchvision==0.8.1+cu101 torchaudio==0.7.0 -f https://download.pytorch.org/whl/torch_stable.html
RUN conda install -y -c conda-forge pillow=6.2.1

RUN pip install terminaltables

# install mmediting
# RUN git clone https://github.com/open-mmlab/mmediting.git /mmediting
RUN git clone https://TiankaiHang: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@github.com/TiankaiHang/vsr.git /VSR
WORKDIR /VSR
ENV FORCE_CUDA="1"
RUN pip install mmcv-full==1.3.10 -f https://download.openmmlab.com/mmcv/dist/cu101/torch1.7.0/index.html
RUN pip install -r requirements.txt
RUN pip install lpips
RUN pip install --no-cache-dir -e .

# Set CUDA_ROOT
RUN export CUDA_HOME="/usr/local/cuda"

RUN echo "azureml dockerfile finished!"