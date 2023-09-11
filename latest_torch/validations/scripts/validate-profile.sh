#!/bin/bash

#
# Validate Profile
#

source ${SINGULARITY_IMAGE_VALIDATIONS}/utils/_utils.sh

validate_profile() {
    exit_code=0
    while read -r line; do
        var=$(echo $line | cut -d '=' -f1)
        actual_value="${!var}"
        expected_value=$(echo "${line//[$'\t\r\n']}" | cut -d '=' -f2)
        if [[ -z "$actual_value" ]]; then
            echo "Error: Expected environment variable $var not found."
            exit_code=1
        elif [[ -n $expected_value ]] && [[ "$expected_value" != "$actual_value" ]]; then
            echo "Error: Environment variable $var=$actual_value instead of expected value $var=$expected_value."
            exit_code=1
        fi
    done <${SINGULARITY_IMAGE_VALIDATIONS}/scripts/expected_variables.txt
    exit $exit_code
}

validate_profile