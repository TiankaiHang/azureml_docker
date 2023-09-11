#!/bin/bash

#
# UTILS
#

set -o pipefail

RED='\033[0;31m'
GREEN='\033[1;32m'
NC='\033[0m'

SUCCESS="${GREEN} [YES]"
FAILURE="${RED}  [NO]"

TABLE_LENGTH=31

VALIDATION_SCRATCH="/validations/scratch"
VALIDATION_LOGS="/validations/logs"
VALIDATION_ERROR_FILE="/validations/errors"

VALIDATION_RUNSETTINGS="${SINGULARITY_IMAGE_VALIDATIONS}/configs/default.runsettings.json"
if [[ ! -e $VALIDATION_RUNSETTINGS ]]; then
  VALIDATION_RUNSETTINGS="${SINGULARITY_IMAGE_VALIDATIONS}/utils/default.runsettings.json"
fi

#
# Print Utils
#
_print_test_header() {
  timeout=$(_get_runsetting "timeout")
  echo "-----------------------------------------------------------"
  echo "Retry timeout: ${timeout}s"
  echo "-----------------------------------------------------------"
  echo "Singularity image health report:"
}

_print_section_header() {
  test_type=$1
  level=$2

  if [[ "$test_type" == "scripts" ]]; then
    echo "-----------------------------------------------------------"
    echo "$level test $test_type ..................  passed"
    echo "-----------------------------------------------------------"
  elif [[ "$test_type" == "commands" ]]; then
    echo "-----------------------------------------------------------"
    echo "$level $test_type ..................  passed"
    echo "-----------------------------------------------------------"
  elif [[ "$test_type" == "apt" ]] || [[ "$test_type" == "pip" ]]; then
    echo "-----------------------------------------------------------"
    echo "$level $test_type packages ..............  installed"
    echo "-----------------------------------------------------------"
  else
    echo "-----------------------------------------------------------"
    echo "$level $test_type dependencies ..............  installed"
    echo "-----------------------------------------------------------"
  fi
}

_print_test_closer() {
  exit_code=$1
  echo "-----------------------------------------------------------"
  if [[ "$exit_code" == "0" ]]; then
    echo "Singularity image validation passed."
  else
    echo "Singularity image validation failed."
  fi
  echo "-----------------------------------------------------------"
}

_print_error_details() {
  test_type=$1
  name=$2
  level=$3
  err_msg="either installation or command missing or functionality test failure."
  if [[ "$test_type" == "apt" ]]; then
    err_msg="apt installation missing, run \"apt-get update && DEBIAN_FRONTEND=noninteractive && apt-get install -y $name\""
  elif [[ "$test_type" == "pip" ]]; then
    err_msg="pip installation missing, run \"pip install $name\""
  elif [[ "$test_type" == "commands" ]]; then
    err_msg="command not found"
  elif [[ "$test_type" == "scripts" ]]; then
    err_msg="functionality test failed"
  else
    echo "unknown test type: $test_type"
  fi
  err_type="Warning"
  if [[ "$level" == "Required" ]];then
    err_type="Failure"
  fi
  echo "***********************************************************"
  echo "$err_type Details: $name $err_msg" | tee -a ${VALIDATION_ERROR_FILE}
  echo "***********************************************************"
  cat "${VALIDATION_LOGS}/$test_type-$name.log" | tee -a ${VALIDATION_ERROR_FILE}
  echo "***********************************************************"
}

_print_result() {
  count=$(( TABLE_LENGTH - ${#1} ))
  spacing=$(printf '%*s' "$count" | tr ' ' ".")

  [[ "$2" == "0" ]] && logstring1=${SUCCESS} || logstring1=${FAILURE}

  echo -e "$1 $spacing $logstring1 ${NC}"
}

#
# TestSuite Utils
#

_get_runsetting() {
  setting_name=$1
  jq -rc ".$setting_name" $VALIDATION_RUNSETTINGS
}

_get_testsuite_dirs() {
  jq -rc '.testsuites|keys|.[]?' $VALIDATION_RUNSETTINGS
}

_get_testsuite_files() {
  suite_dir=$1
  jq -rc '.testsuites.'$suite_dir'|.[]?' $VALIDATION_RUNSETTINGS
}

_ls_if_exist() {
  dir=$1
  if [[ -d "$dir" ]]; then
    ls "$dir"
  fi
}

_get_test_list() {
  test_type=$1
  level=$2

  # Build Test Query
  query='.'$level'.'$test_type'|.[]?'

  suite_dirs=($(_get_testsuite_dirs))
  for suite_dir in "${suite_dirs[@]}"; do
    suite_file_config=$(_get_testsuite_files $suite_dir)
    if [[ "$suite_file_config" == "*" ]]; then
      for filename in $(_ls_if_exist "$SINGULARITY_IMAGE_VALIDATIONS/testsuites/$suite_dir"); do
        jq -rc $query $SINGULARITY_IMAGE_VALIDATIONS/testsuites/$suite_dir/$filename
      done
    else
      suite_files=($suite_file_config)
      for suite_file in "${suite_files[@]}"; do
          jq -rc $query "$SINGULARITY_IMAGE_VALIDATIONS/testsuites/$suite_dir/$suite_file.json"
      done
    fi
  done
}

_test() {
  test_type=$1
  pkg=$2

  name=$(_get_pkg_name "$pkg")
  cmd_output=$(_run "$test_type" "$name" 2>${VALIDATION_LOGS}/$test_type-$name.log | tee ${VALIDATION_LOGS}/$test_type-$name.log)
  result=$?

  # Check version if range is specified
  if [[ $pkg == *"="* ]]; then
    actual_version=$(_get_version "$test_type" "$name" "$cmd_output")
    expected_version=$(echo "$pkg" | cut -d"=" -f 3)

    _version_check "$pkg" "$expected_version" "$actual_version"
    result=$?
  fi

  return $result
}

_get_pkg_name() {
  pkg=$1

  if [[ $pkg == *"=="* ]]; then
    name=$(echo "$pkg" | cut -d"=" -f 1)
  elif [[ $pkg == *">="* ]]; then
    name=$(echo "$pkg" | cut -d"=" -f 1 | cut -d">" -f 1)
  elif [[ $pkg == *"<="* ]]; then
    name=$(echo "$pkg" | cut -d"=" -f 1 | cut -d"<" -f 1)
  else
    name=$pkg
  fi

  echo "$name"
}

_run() {
  test_type=$1
  name=$2

  if [[ $test_type == "pip" ]]; then
    python3 -m pip show "$name"
  elif [[ $test_type == "apt" ]]; then
    apt list --installed | grep "$name"
  elif [[ $test_type == "commands" ]]; then
    if [[ $name == "gosu" ]] || [[ $name == "tini" ]] || [[ $name == "nvcc" ]]; then
      $name --version
    elif [[ $name == "deepspeed" ]]; then
      $name -h
    elif [[ $name == "python" ]] || [[ $name == "python3" ]]; then
      which "$name"
    fi
  elif [[ $test_type == "scripts" ]]; then
    if [[ -f "${SINGULARITY_IMAGE_VALIDATIONS}/scripts/validate-$name.sh" ]]; then
      bash ${SINGULARITY_IMAGE_VALIDATIONS}/scripts/validate-$name.sh
    elif [[ -f "${SINGULARITY_IMAGE_VALIDATIONS}/scripts/validate-$name.py" ]]; then
      python3 ${SINGULARITY_IMAGE_VALIDATIONS}/scripts/validate-$name.py
    else
      echo "Skipping $name b/c validation script not found."
    fi
  fi
}

_check_validator_dependencies() {
  _test "apt" "jq"
  result=$?
  _print_result "jq" "$result"
  return $result
}

#
# Version Utils
#
_compare_versions() {
  ## Returns true if v1 >= v2, false if v1 < v2
  [[ "$2" == "*" ]] || [[ "$1" == "$2" ]] || test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

_get_version() {
  test_type="$1"
  name="$2"
  cmd_output="$3"

  if [[ $test_type == "pip" ]]; then
    echo "$cmd_output" | cut -d':' -f 3 | cut -d ' ' -f 2
  elif [[ $test_type == "apt" ]]; then
    echo "$cmd_output" | cut -d':' -f 3 | cut -d ' ' -f 2 | sed 's/[^0-9\.]*//g'
  elif [[ $test_type == "commands" ]]; then
    if [[ $name == "gosu" ]]; then
      echo "$cmd_output" | cut -d'(' -f 1
    elif [[ $name == "tini" ]]; then
      echo "$cmd_output" | cut -d' ' -f 3
    fi
  fi
}

_version_check() {
  pkg=$1
  expected_version=$2
  actual_version=$3

  result=1
  if [[ $pkg == *"=="* ]] && [[ "$actual_version" == "$expected_version" ]]; then
    result=0
  elif [[ $pkg == *">="* ]] && _compare_versions "$actual_version" "$expected_version"; then
    result=0
  elif [[ $pkg == *"<="* ]] && _compare_versions "$expected_version" "$actual_version"; then
    result=0
  fi

  return $result
}

#
# Network Utils
#
_get_available_port() {
  python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()'
}

#
# Process Utils
#
_verify_process_up() {
  process_name="$1"
  _retry pgrep --full $process_name
}

_cleanup_child_processes() {
    local pid="$1"
    local cleanup_self="${2:-false}"
    if children="$(pgrep -P "$pid")"; then
        for child in $children; do
            _cleanup_child_processes "$child" true
        done
    fi
    if [[ "$cleanup_self" == true ]]; then
        kill "$pid" 2> /dev/null
    fi
}

#
# Basic Utils
#
_compare() {
  [[ $1 == $2 ]] && return 0 || return 1
}

_retry() {
  command=$*
  retry_delay=2
  timeout=(_get_runsetting "timeout")
  max_retry_count=$((timeout/retry_delay))
  if [[ $max_retry_count == 0 ]]; then
    max_retry_count=1
  fi

  retry_count=0
  until [[ $retry_count -eq $max_retry_count ]]; do
    if $command; then
      return 0
    fi

    sleep $retry_delay
    retry_count=$((retry_count+1))
  done

  return 1
}

_wait_for_string_in_process() {
  logfile=$1
  expected_output=$2

  _verify_file_status ${logfile} 0

  if [[ "$?" -ne "0" ]]; then
    return 1
  fi

  (timeout 240 tail -F "${logfile}" &) | grep "${expected_output}" && return 0
  echo "Didn't find ${expected_output} in process log."
  return 1
}

#
# Exit Utils
#
_save_exit_code() {
  rc="$1"
  echo "${rc}" > ${VALIDATION_SCRATCH}/exitcode.txt
}

_load_exit_code() {
  cat ${VALIDATION_SCRATCH}/exitcode.txt
}

#
# Script Utils
#
_verify_string_in_file() {
  filename="$1"
  check_string="$2"

  cat "$filename" | grep "$check_string"
}

_verify_file_status() {
  filename="$1"
  should_exist="$2"

  _validate_file() {
    test -f "$filename"
    _compare "$?" "$should_exist"
  }

  _retry _validate_file
}

_run_curl_and_verify_status_code() {
  http_verb="$1"
  uri="$2"
  expected_output=$3

  _validate_curl() {
    actual_output=$(curl -I -X $http_verb $uri | head -n 1 | cut -d$' ' -f2)
    _compare "$actual_output" *"$expected_output"*
  }

  _retry _validate_curl
}

_run_ssh_command_and_verify_output() {
  ssh_cmd="$1 && exit"
  expected_output=$2
  port=$3

  _validate_ssh() {
    actual_output=$(gosu aiscuser ssh -p ${port} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -4 -v localhost $ssh_cmd $expected_output)
    _compare "$actual_output" *"$expected_output"*
  }

  _retry _validate_ssh
}