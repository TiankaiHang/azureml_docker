#!/bin/bash

#
# Validate Jupyter
#
set -e
source ${SINGULARITY_IMAGE_VALIDATIONS}/utils/_utils.sh

check_jupyter_process() {
  trap '_cleanup_jupyter' EXIT
  port=$(_get_available_port)
  _setup_jupyter "${port}"
  _jupyter_tests "${port}"
}

_setup_jupyter() {
  port="$1"

  mkdir -p ${SINGULARITY_USER_HOME}/.jupyter
  chown -R ${SINGULARITY_USER_NAME}:${SINGULARITY_USER_GROUP_NAME} ${SINGULARITY_USER_HOME}/.jupyter
  if [[ -f ${SINGULARITY_USER_HOME}/untitled ]]; then
    rm -f ${SINGULARITY_USER_HOME}/untitled
  fi
  JUPYTER_CONFIG_FILE=${SINGULARITY_USER_HOME}/.jupyter/jupyter_notebook_config.py
  notebook_config="c.NotebookApp.open_browser = False
c.NotebookApp.allow_origin = '*'
c.NotebookApp.allow_remote_access = True
c.NotebookApp.disable_check_xsrf = True
c.NotebookApp.base_url = '/root/'
c.NotebookApp.ip = '127.0.0.1'
c.NotebookApp.min_open_files_limit = 4096
c.NotebookApp.notebook_dir = '/home/aiscuser'
c.NotebookApp.port = ${port}
c.NotebookApp.token = ''"
  echo "$notebook_config" > ${JUPYTER_CONFIG_FILE}

if [[ -f /opt/.singularity/bin/jupyter ]]; then
  JUPYTER_CMD=/opt/.singularity/bin/jupyter
else
  JUPYTER_CMD=jupyter
fi

  gosu aiscuser ${JUPYTER_CMD} notebook > ${VALIDATION_LOGS}/jupyter_output.log  2>&1 &
}

_jupyter_tests() {
  port="$1"

  _verify_process_up jupyter
  results=$?

  # _wait_for_string_in_process "${VALIDATION_LOGS}/jupyter_output.log" "Use Control-C to stop this server and shut down all kernels"
  # results=$((results + $?))

  # # File Create
  # _run_curl_and_verify_status_code POST http://127.0.0.1:${port}/root/api/contents 201
  # results2=$?

  # _verify_file_status ${SINGULARITY_USER_HOME}/untitled 0
  # results2=$((results2 + $?))

  # # File List
  # _run_curl_and_verify_status_code GET http://127.0.0.1:${port}/root/api/contents 200
  # results3=$?

  # # File Delete
  # _run_curl_and_verify_status_code DELETE http://127.0.0.1:${port}/root/api/contents/untitled 204
  # results4=$?

  # _verify_file_status ${SINGULARITY_USER_HOME}/untitled 1
  # results4=$((results4 + $?))

  # # Start Kernel
  # _run_curl_and_verify_status_code POST http://127.0.0.1:${port}/root/api/kernels 201
  # results5=$((results + $?))

  # # Get Kernel
  # _run_curl_and_verify_status_code GET http://127.0.0.1:${port}/root/api/kernels 200
  # results6=$((results + $?))

  # echo "Jupyter Notebook Server http://127.0.0.1:${port} Test Results: ServerStart-${results}|FileCreate-${results2}|FileList-${results3}|FileDelete-${results4}|KernelCreate-${results5}|KernelGet-${results6}" > ${VALIDATION_LOGS}/jupyter-testresults.log

  # testresults=$((results + results2 +results3 +results4 + results5 + results6))
  if [[ "${results}" -ne "0" ]]; then
    exit 1
  fi
}

_cleanup_jupyter() {
  # Cleanup
  rm -f ${SINGULARITY_USER_HOME}/untitled*
  rm -rf ${SINGULARITY_USER_HOME}/.jupyter
  rm -rf ${SINGULARITY_USER_HOME}/.ipynb_checkpoints
  rm -rf ${SINGULARITY_USER_HOME}/.ipython
  rm -rf ${SINGULARITY_USER_HOME}/.local
  pkill -P $$
}

check_jupyter_process