#!/bin/bash

set +e

# Exit if this is not set. This environment variable is set only for machines with
# NVIDIA GPUs
if [[ -z "$SINGULARITY_NVIDIA_HOST_CUDA_VERSION" ]]; then
    echo "SINGULARITY_NVIDIA_HOST_CUDA_VERSION is not set. Skipping validation"
    exit 0
fi

if [[ -z "$GPU_PER_NODE_COUNT" || $GPU_PER_NODE_COUNT -lt 1 ]]; then
    echo "No GPUs projected into the container. Skipping validation"
    exit 0
fi

if [[ $AISC_CAPACITY_ID == ND*v4* ]]; then
    echo "Skipping validation on A100 instance types"
    exit 0
fi

# Get CUDA version in the container
nvidia_smi_output=$(nvidia-smi -q | grep CUDA)
echo "nvidia-smi reported CUDA version: $nvidia_smi_output"

ver=$(echo $nvidia_smi_output | awk -F: '{gsub(/ /, "", $2);print $2}')

# Check if the value follows the expected format
if [[ "$ver" =~ ^[0-9]+\.[0-9]+$ ]]; then
    # Convert it to an integer so it can be compared with the version in the host
    cuda_version=$(echo $ver | awk -F. '{print $1*1000+$2*10}')

    echo "Container CUDA version: $cuda_version"

    # Check if the container version is lower
    if [[ $SINGULARITY_NVIDIA_HOST_CUDA_VERSION -lt $cuda_version ]]; then
        echo "Error: Container CUDA Version ($cuda_version) is higher than host version ($SINGULARITY_NVIDIA_HOST_CUDA_VERSION)"
        exit 1
    fi
else
    echo "Unable to validate CUDA version in the container. Container CUDA Version ($ver) has incorrect format."
    exit 1
fi