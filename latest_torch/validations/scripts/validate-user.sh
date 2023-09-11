#!/bin/bash

#
# Validate User
#
set -e
source ${SINGULARITY_IMAGE_VALIDATIONS}/utils/_utils.sh

validate_user() {
    output=$(gosu aiscuser whoami)
    if [[ "aiscuser" == "$output" ]]; then
        exit 0
    else
        >&2 echo "$output"
        exit 1
    fi
}

validate_user