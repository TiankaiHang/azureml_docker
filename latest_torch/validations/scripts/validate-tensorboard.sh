#!/bin/bash

#
# Validate Tensorboard
#
set -e
source ${SINGULARITY_IMAGE_VALIDATIONS}/utils/_utils.sh

check_tensorboard_process() {
  trap '_cleanup_tensorboard' EXIT
  port=$(_get_available_port)
  _setup_tensorboard "${port}"
  _tensorboard_tests "${port}"
}

_setup_tensorboard() {
  port="$1"

  if [[ ! -d ${SINGULARITY_USER_HOME}/tensorboard/logs ]]; then
    mkdir -p ${SINGULARITY_USER_HOME}/tensorboard/logs
    chown -R ${SINGULARITY_USER_NAME}:${SINGULARITY_USER_GROUP_NAME} ${SINGULARITY_USER_HOME}/tensorboard/logs
  fi

  if [[ -f /opt/.singularity/bin/tensorboard ]]; then
    TB_CMD=/opt/.singularity/bin/tensorboard
  else
    TB_CMD=tensorboard
  fi

  gosu aiscuser ${TB_CMD} --logdir ${SINGULARITY_USER_HOME}/tensorboard/logs --host localhost --path_prefix /root/tensorboard --port ${port} > ${VALIDATION_LOGS}/tensorboard_output.log 2>&1 &
}

_tensorboard_tests() {
  port="$1"

  _verify_process_up tensorboard
  results=$?

  # _wait_for_string_in_process ${VALIDATION_LOGS}/tensorboard_output.log "http://localhost:${port}/root/tensorboard/"
  # results=$((results + $?))

  # _run_curl_and_verify_status_code GET http://localhost:${port}/root/tensorboard/ 200
  # results2=$?

  # echo "Tensorboard Test Results: TensorboardStart-${results}|TensorboardConnect-${results2}" > ${VALIDATION_LOGS}/tensorboard-testresults.log

  # testresults=$((results + results2))
  if [[ "${results}" -ne "0" ]]; then
    exit 1
  fi
}

_cleanup_tensorboard() {
  # Cleanup
  rm -rf /root/tensorboard
  rm -rf ${SINGULARITY_USER_HOME}/tensorboard
  rm -rf /tmp/.tensorboard-info
  pkill -P $$
}

check_tensorboard_process