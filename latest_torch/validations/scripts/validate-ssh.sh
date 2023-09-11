#!/bin/bash

#
# Validate Ssh
#
set -e
source ${SINGULARITY_IMAGE_VALIDATIONS}/utils/_utils.sh

check_ssh_process() {
  trap '_cleanup_ssh' EXIT
  port=$(_get_available_port)
  _setup_ssh "${port}"
  _ssh_tests "${port}"
}

_setup_ssh() {
  port="$1"

  mkdir -p -m 700 ${SINGULARITY_USER_HOME}/.ssh
  printf "Host *\nStrictHostKeyChecking no\nUserKnownHostsFile=/dev/null\nPasswordAuthentication no\n" >> ${SINGULARITY_USER_HOME}/.ssh/config

  ssh-keygen -b 2048 -t rsa -f ${SINGULARITY_USER_HOME}/.ssh/id_rsa -q -N "" <<<y 2>&1 >/dev/null
  chmod 600 ${SINGULARITY_USER_HOME}/.ssh/id_rsa
  mv ${SINGULARITY_USER_HOME}/.ssh/id_rsa.pub ${SINGULARITY_USER_HOME}/.ssh/authorized_keys
  chown -R ${SINGULARITY_USER_NAME}:${SINGULARITY_USER_GROUP_NAME} ${SINGULARITY_USER_HOME}/.ssh

  mkdir -p /var/run/sshd
  chmod 0755 /var/run/sshd
  if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
      # generate default key if missing
      ssh-keygen -A
  fi

  /usr/sbin/sshd -p ${port} -D -e > ${VALIDATION_LOGS}/sshd_output.log 2>&1 &
}

_ssh_tests() {
  port="$1"

  _verify_process_up ssh
  results=$?

  # _wait_for_string_in_process "${VALIDATION_LOGS}/sshd_output.log" "Server listening on"
  # results=$((results + $?))

  # _run_ssh_command_and_verify_output 'pwd' '/home/aiscuser' ${port}
  # results2=$?

  # echo "Ssh Test Results: SshdStart-${results}|SshAndRunCmd-${results2}" > ${VALIDATION_LOGS}/ssh-testresults.log

  # testresults=$((results + results2))
  if [[ "${results}" -ne "0" ]]; then
    exit 1
  fi
}

_cleanup_ssh() {
  # Cleanup
  rm -rf ${SINGULARITY_USER_HOME}/.ssh
  rm -rf ${SINGULARITY_USER_HOME}/.cache
  rm -rf /var/run/sshd
  rm -rf /run/sshd.pid
  rm -rf /run/motd.dynamic
  rm -rf /var/cache/motd-news
  pkill -P $$
}

check_ssh_process