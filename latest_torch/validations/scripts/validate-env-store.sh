#!/bin/bash
export RANK=0
export WORLD_SIZE=1
export MASTER_ADDR=127.0.0.1
export MASTER_PORT=19500
python /opt/microsoft/singularity-runtime-test/user/job/pytorch/validate-env-store.py