import torch.distributed as dist
dist.init_process_group(backend="nccl", init_method='tcp://127.0.0.1:19500', rank=0, world_size=1)