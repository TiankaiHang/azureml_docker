# =====================================================================
FROM mcr.microsoft.com/azureml/openmpi4.1.0-cuda11.1-cudnn8-ubuntu18.04

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