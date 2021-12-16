# Some useful dockerfiles for Deep Learning

Supported: 

- torch1.10+cuda11.1  
    - horovod
    - deepspeed
    - mmcv==1.14
- torch1.7.1+cuda11.0  
- torch1.7+cuda10.1  
- torch1.8+cuda10.1  
- torch1.9_cuda11.1

## example for docker run

```!bash
SRC=/
DST=/home
DOCKER=tiankaihang/azureml_docker:horovod_deepspeed

if [ -z $CUDA_VISIBLE_DEVICES ]; then
   CUDA_VISIBLE_DEVICES='all'
fi
docker run --gpus '"'device=$CUDA_VISIBLE_DEVICES'"' --ipc=host --rm -it \
   --mount src=$SRC,dst=$DST,type=bind \
   -e NVIDIA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES \
   -w $DST $DOCKER \
   bash -c "bash"
```