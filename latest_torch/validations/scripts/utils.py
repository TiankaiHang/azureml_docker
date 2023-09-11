#!/opt/conda/bin/python

from datetime import timedelta
from doctest import master
from enum import IntEnum

import os
import random
import re
import socket
import time
import traceback

# Enums used to indicate validation result
class ValidationResult(IntEnum):
    SUCCESS = 0,
    ENOPROTOOPT = 92,
    ENOTRECOVERABLE = 131,

# Enums used to indicate completion result for each process that's spawned
class DistributedInitCheckResult(IntEnum):
    SUCCESS = 0,
    NCCLFAILURE = 1,
    TCPCONNECTIONFAILURE = 2,
    UNKNOWNFAILURE = 3

def get_tcp_connection_error_regex():
    """
    Regular expression used to check if error is due to TCP store failures
    """
    error_regex = [
        "connect() timed out.",
        "Socket Timeout",
        "Connection reset by peer",
        "Connection closed by peer"
    ]

    return "|".join(["({})".format(error) for error in error_regex])

def get_nccl_connection_error_regex():
    """
    Regular expression used to check if error is due to NCCL failures
    """
    error_regex = [
        "ncclUnhandledCudaError",
        "ncclSystemError",
        "ncclInternalError",
    ]

    return "|".join(["({})".format(error) for error in error_regex])

def is_exception_retriable(err):
    """
    Helper function to check if error is retriable
    """
    if re.search(pattern=get_nccl_connection_error_regex(), string=str(err)):
        return (True, DistributedInitCheckResult.NCCLFAILURE)
    elif re.search(pattern=get_tcp_connection_error_regex(), string=str(err)):
        return (True, DistributedInitCheckResult.TCPCONNECTIONFAILURE)
    else:
        return (False, DistributedInitCheckResult.UNKNOWNFAILURE)

def validate_environment_variables(env_vars, accept_empty=False):
    """
    Helper function to check environment variables existence and values
    """
    if isinstance(env_vars, dict) and accept_empty:
        return all(x in os.environ.items() or (x[0] in os.environ.keys() and x[1] == '') for x in env_vars.items())
    elif isinstance(env_vars, dict):
        return all(x in os.environ.items() for x in env_vars.items())
    elif isinstance(env_vars, list):
        return all(x in os.environ.keys() for x in env_vars)
    else:
        return False


# Gets IP address of Rank-0 node
def get_master_ip_addr(master_hostname, timeout):
    total_runtime_in_seconds=timedelta(seconds=0)

    retry_count = 0

    while True:
        try:
            return socket.gethostbyname(master_hostname)
        except Exception as e:
            # Trace the exception
            print('Unable to get IP address due to exception {0} {1}'.format(type(e).__name__, e))
            traceback.print_exc()

            # If total runtime is more than timeout then return the exception
            if total_runtime_in_seconds > timeout:
                raise

            # Calculate back off interval using retry count
            retry_count += 1

            backoff_interval_in_milliseconds = timedelta(milliseconds=(10 ** retry_count + random.randint(0, 100)))

            print('Retrying [RetryCount: {0}] [BackoffInterval: {0} Seconds] [TotalRuntime: {1} Seconds]'.format(retry_count, backoff_interval_in_milliseconds.total_seconds(), total_runtime_in_seconds.total_seconds()))

            # Wait before retrying
            time.sleep(backoff_interval_in_milliseconds.total_seconds())

            total_runtime_in_seconds += backoff_interval_in_milliseconds