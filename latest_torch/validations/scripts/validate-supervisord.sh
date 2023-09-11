#!/bin/bash

#
# Validate Supervisord
#
set -e
source ${SINGULARITY_IMAGE_VALIDATIONS}/utils/_utils.sh

check_supervisord_process() {
  trap '_cleanup_supervisord' EXIT
  port=$(_get_available_port)
  _setup_supervisord "${port}"
  _supervisord_tests "${port}"
}

_setup_supervisord() {
  port="$1"

  SUPERVISOR_CONFIG_FILE=${VALIDATION_SCRATCH}/supervisord.conf
  supervisor_config="[inet_http_server]
port = localhost:${port}
[supervisorctl]
serverurl = http://localhost:${port}
[supervisord]
nodaemon=true
user=root
logfile=${VALIDATION_LOGS}/supervisord.log
pidfile=${VALIDATION_LOGS}/supervisord.pid
childlogdir=${VALIDATION_SCRATCH}
logfile_maxbytes = 0
[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface
[program:foo]
command=/bin/ls
stdout_logfile=${VALIDATION_LOGS}/supervisord.log
stderr_logfile=${VALIDATION_LOGS}/supervisord.log
startsecs=0
startretries=0
autorestart=false"
  echo "$supervisor_config" > ${SUPERVISOR_CONFIG_FILE}

  supervisord -c ${SUPERVISOR_CONFIG_FILE} > ${VALIDATION_LOGS}/supervisord_output.log 2>&1 &
}

_supervisord_tests() {
  port="$1"

  _verify_process_up supervisord
  results=$?

  # _wait_for_string_in_process "${VALIDATION_LOGS}/supervisord_output.log" "supervisord started with pid"
  # results=$((results + $?))

  # _wait_for_string_in_process "${VALIDATION_LOGS}/supervisord_output.log" "foo entered RUNNING state"
  # results2=$?

  # echo "Supervisord Test Results: SupervisorStart-${results}|ProcessStart-${results2}" > ${VALIDATION_LOGS}/supervisord-testresults.log

  # testresults=$((results + results2))
  if [[ "${results}" -ne "0" ]]; then
    exit 1
  fi
}

_cleanup_supervisord() {
  # Cleanup
  set +e
  rm -rf ${VALIDATION_SCRATCH}/supervisor*
  pkill -P $$
}

check_supervisord_process