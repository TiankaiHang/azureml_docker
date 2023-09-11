#!/bin/bash

set +e

nccl_version=$(python -c "import torch;print(torch.cuda.nccl.version())")
echo $nccl_version
echo "LD_LIBRARY_PATH:$LD_LIBRARY_PATH"

return 0