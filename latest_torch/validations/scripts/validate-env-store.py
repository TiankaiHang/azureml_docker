import torch.distributed as dist
dist.init_process_group(backend="nccl")