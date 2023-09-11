#!/bin/bash

#
# Validate Image Processes
#

if [[ -z ${SINGULARITY_IMAGE_VALIDATIONS} ]]; then
  export SINGULARITY_IMAGE_VALIDATIONS=$(dirname "$(readlink -f "$0")")
fi

source ${SINGULARITY_IMAGE_VALIDATIONS}/utils/_utils.sh

_setup_tests() {
  mkdir -p ${VALIDATION_SCRATCH}
  mkdir -p ${VALIDATION_LOGS}
  mkdir -p "$(dirname "${VALIDATION_ERROR_FILE}")"
  touch ${VALIDATION_ERROR_FILE}
  chmod 666 ${VALIDATION_ERROR_FILE}
  _print_test_header
}

_run_tests() {
  test_type=$1
  level=$2
  exit_code=0
  test_list=$(_get_test_list "$test_type" "$level")
  if [[ -n $test_list ]]; then
    _print_section_header "$test_type" "$level"
    for pkg in $test_list; do
      _test "$test_type" "$pkg"
      result=$?
      _print_result "$name" "$result"

      if [[ "$result" != "0" ]]; then
        name=$(_get_pkg_name "$pkg")
        _print_error_details "$test_type" "$name" "$level"

        if [[ "$level" == "Required" ]]; then
          exit_code=1
        fi
      fi
    done
  fi

  return $exit_code
}

_cleanup_and_exit_tests() {
  _print_test_closer $?
  rm -rf "${VALIDATION_SCRATCH}"
}

start_tests() {
  trap '_cleanup_and_exit_tests' EXIT

  # Specify custom runsettings file to run different test suites in different environments.
  if [[ -n $1 ]]; then
    export VALIDATION_RUNSETTINGS="$1"
  fi

  # set validation error file, if provided. Write all the error messages in this file, so caller can consume and send them to container orchestrator on failure.
  if [[ -n $2 ]]; then
    VALIDATION_ERROR_FILE="$2"
  fi

  _setup_tests
  _save_exit_code 0

  if [[ ! -e $VALIDATION_RUNSETTINGS ]]; then
    echo "Specified runsettings file $VALIDATION_RUNSETTINGS does not exist. Please specify a valid runsettings file or leave args empty to use default runsettings."
    exit 1
  else
    echo "Using runsettings file: $VALIDATION_RUNSETTINGS."
  fi

  _print_section_header "health report" "Required"
  _check_validator_dependencies
  rc=$?
  if [[ $rc -ne 0 ]]; then
    exit $rc
  fi

  test_types=(commands apt pip scripts)
  levels=(Required Recommended)

  for type in "${test_types[@]}"; do
    for level in "${levels[@]}"; do
      _run_tests "$type" "$level"
      rc=$?
      if [[ $rc -ne 0 ]]; then
        _save_exit_code $rc
      fi
    done
  done

  exit "$(_load_exit_code)"
}

if [[ -f /etc/profile.d/singularity_env_variables_profile.sh ]]; then
  source /etc/profile.d/singularity_env_variables_profile.sh
fi

start_tests "$@"