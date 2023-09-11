#!/opt/conda/bin/python

#
# Validation script that checks if NCCL can be used for distributed communication.
# This should be run after MASTER_ADDR is up and ready. This script initializes
# torch.distributed process group using NCCL backend and checks if it can do a
# single all reduce.
#
# Main entrypoint in the script spawns GPU_PER_NODE_COUNT workers
# and joins the process group with world size set to GPU_PER_NODE_COUNT*WORLD_SIZE and
# rank set to (node_rank*num_gpus)+local_rank. Main entry point also creates a 
# queue that's used by workers to queue their result. Main entry point waits for
# all workers to finish before check results.
#
# Workers try to initialize process group and post their result to the queue.
# Also, each worker retries on any intermittent connection failure for 
# _nccl_distributed_communication_validation_max_runtime before giving up.
#
# Main entrypoint waits for all workers to finish and returns success or failure exit
# codes based on results from all workers. This script returns:
#    - Success - If all workers have queued DistributedInitCheckResult.SUCCESS.
#    - ENOTRECOVERABLE - If atleast one worker has hit any unknown failures or if all workers
#                        have not posted their results to the queue. This will happen in the
#                        following cases:
#                            - Any Worker sees repeated connectivity issues talking to MASTER_ADDR
#                            - Any worker runs into an unknown exception
#                            - All workers have not run to completion before _validation_max_runtime
#    - ENOPROTOOPT - If one worker sees NCCL related failure. This return code can be used to
#                    by repair/mitigation manager to disable this node.
#
from asyncio import events
from utils import ValidationResult, DistributedInitCheckResult, get_master_ip_addr, is_exception_retriable, validate_environment_variables
from datetime import timedelta
from datetime import datetime
from enum import Enum
from typing import Coroutine

import asyncio
import importlib
import os
import signal
import sys
import traceback
import time
import multiprocessing as pymp

class NcclValidationState(Enum):
    CONNECTION_LOST = 1
    VALIDATION_PENDING = 2
    VALIDATION_DONE = 3

# Skip this validation if this is not a multi-node ib enabled job.
if validate_environment_variables({'SINGULARITY_SKIP_NCCL_VALIDATION':'true'}, accept_empty=True):
    print("Skipped nccl validation due to override")
    sys.exit(0)
elif not validate_environment_variables({'BACKEND':'nccl', 'AISC_INFINIBAND_ENABLED':'true', 'NODE_COUNT':''}, accept_empty=True):
    print("Skipped nccl validation")
    sys.exit(0)
elif not int(os.environ["NODE_COUNT"]) > 1:
    print("Skipped nccl validation: " + os.environ["BACKEND"] + " IB_ENABLED=" + os.environ["AISC_INFINIBAND_ENABLED"] + " NODE_COUNT=" + os.environ["NODE_COUNT"])
    sys.exit(0)

if importlib.util.find_spec("torch") is None:
    print("Skipping NCCL validation as this is not a PyTorch container")
    sys.exit(0)

import torch.multiprocessing as mp
import torch
import torch.distributed as dist

# Timeout for getting IP address of Rank-0 node
_master_address_resolution_max_runtime = timedelta(minutes=1)
# Maximum runtime for this validation script
_validation_max_runtime = timedelta(minutes=5)
# Maximum time to wait for all containers to agree that we should run this
# validation
_max_bootstrap_time = timedelta(minutes=5)
# Total amount of time each process spends to check if it can initialize
# distributed communication
_nccl_distributed_communication_validation_max_runtime = timedelta(minutes=1)
# NCCL validation executor port
_nccl_validation_executor_port = 10000

class nccl_validation_executor_connection(asyncio.Protocol):
    '''Handles connection to executor and gets validation state'''
    '''from executor'''
    def __init__(self, state):
        self.state = state

    def connection_made(self, transport):
        self.peername, port = transport.get_extra_info('peername')

        print('NcclValidationBootstrapServer {} connected to client'.format(self, self.peername))

        self.transport = transport

    # Set result in the future once we have data from executor
    def data_received(self, data):
        message = data.decode()
        print('Received Data {} from {}'.format(message, self.peername))

        if message == '0':
            state = NcclValidationState.VALIDATION_DONE
        else:
            state = NcclValidationState.VALIDATION_PENDING

        self.state.set_result(state)

    def connection_lost(self, exc):
        print('Connection lost to {}'.format(self.peername))
        self.state.set_result(NcclValidationState.CONNECTION_LOST)

def validate_nccl_dist_communication(local_rank, master_addr, num_gpus, node_rank, world_size, completionQueue):
    """
    Each spawned process runs this to check if it can initialize distributed
    communication using NCCL
    """
    rank = (node_rank*num_gpus)+local_rank

    # Make a note of start time so we can use this to check if initialization
    # can be retried
    start_time = datetime.now()

    # Use MASTER_ADDR and MASTER_PORT to setup dist-url string
    init_str = 'tcp://' + master_addr + ':' + os.environ['MASTER_PORT']
    print('Rank-{0}: Using {1} as dist-url to initialize distributed communication'.format(str(local_rank), init_str))

    while True:
        try:
            print('Rank-{0}: Initializing process group'.format(str(local_rank)))

            # Try to setup process group
            dist.init_process_group(
                backend='nccl',
                init_method=init_str,
                world_size=world_size,
                rank=rank,
                timeout=_nccl_distributed_communication_validation_max_runtime)

            # Try a single all-reduce operation
            print('Rank-{0}: Initialized process group'.format(str(local_rank)))

            torch.cuda.set_device(local_rank)
            tensor = torch.ones(1).cuda(local_rank)

            dist.all_reduce(tensor)
            torch.cuda.synchronize(local_rank)

            # Queue result
            completionQueue.put(DistributedInitCheckResult.SUCCESS)

            print('Rank-{0}: Finished validating distributed init'.format(str(local_rank)))
            break
        # catch RuntimeErrors from PyTorch to check if there are known exceptions
        except RuntimeError as err:
            is_retriable, result = is_exception_retriable(err)

            # Retry exception
            if is_retriable:
                elapsed_time = datetime.now() - start_time
                if elapsed_time >= _nccl_distributed_communication_validation_max_runtime:
                    print('Rank-{0}: [Elapsed time: {1}] Hit retriable exception but not retrying due to timeout- {2}'.format(str(local_rank), str(elapsed_time), str(err)))
                    break
            else:
                print('Rank-{0}: Exiting with result - {1}. Hit nonretriable exception - {2}'.format(str(local_rank), str(result), str(err)))
                completionQueue.put(result)
                break

            print('Rank-{0}: [Elapsed time: {1}] Hit retriable exception - {2}'.format(str(local_rank), str(elapsed_time), str(err)))
            dist.destroy_process_group()
            continue
        except Exception as e:
            print('Rank-{0}: Exiting with result - {1} {2}'.format(str(local_rank), type(e).__name__, e))
            completionQueue.put(DistributedInitCheckResult.UNKNOWNFAILURE)
            traceback.print_exc()
            break

    print('Rank-{0}: Done'.format(str(local_rank)))
    sys.exit(0)

def should_run_validation():
    # Get start time so we can find out how long this has been running
    start_time = datetime.now()
    # Get the event loop required for async
    default_event_loop = asyncio.get_event_loop()

    while True:

        try:
            validation_state = default_event_loop.create_future()

            # Connect to the executor
            task = default_event_loop.create_connection(
                lambda: nccl_validation_executor_connection(validation_state),
                '127.0.0.1',
                _nccl_validation_executor_port)

            default_event_loop.run_until_complete(task)

            # Wait till the executor returns validation state
            default_event_loop.run_until_complete(validation_state)

            state = validation_state.result()

            print('Validation State - {}'.format(state))

            # If we are unable to get state then retry
            if state == NcclValidationState.CONNECTION_LOST:
                print('Lost connection to executor. Retrying..')
            elif state == NcclValidationState.VALIDATION_DONE:
                print('Validation is already done. Skip running validation')
                return False
            else:
                print('Executor returned NCCL validation is pending')
                return True

        except Exception as ex:
            print('Unable to fetch state due to {}'.format(ex))
        
        elapsed_time = datetime.now() - start_time

        if elapsed_time.total_seconds() > _max_bootstrap_time.total_seconds():
            print('Unable to get if validation needs to be executed. Skip running validation')
            return False
        else:
            # Wait before retrying
            time.sleep(5)

    return False

def main():
    # Setup parameters required for mp.spawn
    if not os.environ['GPU_PER_NODE_COUNT']:
        print('GPU_PER_NODE_COUNT environment variable not defined.')
        return int(ValidationResult.ENOTRECOVERABLE)
    else:
        num_processes = int(os.environ['GPU_PER_NODE_COUNT'])
        num_gpus = num_processes

    if not os.environ['NODE_RANK']:
        print('NODE_RANK environment variable not defined.')
        return int(ValidationResult.ENOTRECOVERABLE)
    else:
        node_rank = int(os.environ['NODE_RANK'])

    if not os.environ['NODE_COUNT']:
        print('NODE_COUNT environment variable not defined.')
        return int(ValidationResult.ENOTRECOVERABLE)
    else:
        num_nodes = int(os.environ['NODE_COUNT'])

    world_size = num_gpus*num_nodes

    run_validation = should_run_validation()

    if not run_validation:
        print('Skip running NCCL validation')
        return

    master_addr=get_master_ip_addr(os.environ['MASTER_ADDR'], _master_address_resolution_max_runtime)

    # Set start method to spawn so processes created using torch's spawn
    # can use mp Queue
    mp.set_start_method('spawn')

    # Create queue used by processes to store their result
    completionQueue = pymp.Queue()

    # Spawn processes
    print('Spawning '+str(num_processes)+' workers')

    # Each process runs torch.distributed.init_process_group and returns result
    context = mp.spawn(validate_nccl_dist_communication, nprocs=num_processes, join=False, args=(master_addr, num_gpus, node_rank, world_size, completionQueue,))

    # Make a note of start and remaining time so we can kill processes if they take
    # too long to run
    validation_start_time = datetime.now()
    remaining_time = _validation_max_runtime

    print('Waiting for {0} seconds for validation to finish.'.format(str(remaining_time.total_seconds())))

    # Wait for processes to complete and check the result
    while not context.join(timeout=remaining_time.total_seconds()):
        elapsed_time = datetime.now() - validation_start_time

        # If there are proccesses that have not completed yet. Check if we need to
        # kill them or wait for them to finish
        if elapsed_time >= remaining_time:
            # If we timedout waiting for processes to exit then kill all processes
            print('NCCL validation did not complete before timeout. Killing all processes')
            pids = context.pids()

            for pid in pids:
                try:
                    os.kill(pid, signal.SIGTERM)
                except:
                    #Ignore exceptions
                    pass
            break

            # Even though we killed remaining process we should check to see if
            # any of them ran into NCCL failures so don't return early here
        else:
            # Update remaining time
            print('Waiting for {0} seconds for all processes to exit.'.format(str(remaining_time.total_seconds())))
            remaining_time = _validation_max_runtime - elapsed_time

    # Check queue to see if we have results from all processes
    num_completion_queue_items = 0

    validation_result = ValidationResult.SUCCESS

    while not completionQueue.empty():
        result = completionQueue.get()

        # If atleast one process hit NCCL error then propagate this back so we
        # can mitigate it by disabling this node
        if result == DistributedInitCheckResult.NCCLFAILURE:
            print('Unable to validate due to NCCL issues in one of the spawned processes')
            validation_result = ValidationResult.ENOPROTOOPT
        # If atleast one process returns a failure that's not known then fail
        # validation
        elif result != DistributedInitCheckResult.SUCCESS:
            print('Unable to validate due to unrecoverable error in one of the spawned processes')
            validation_result = ValidationResult.ENOTRECOVERABLE

        num_completion_queue_items += 1

    # If we completed going through the queue without seeing any failures. Then
    # check if all processes have returned results. If we don't see results for
    # all processes we were probably stuck waiting for NCCL to initialize. At this
    # point, since we didn't observe any NCCL related failures we cannot return
    # NCCL related error code, so set this to ValidationResult.ENOTRECOVERABLE
    if validation_result == ValidationResult.SUCCESS and num_completion_queue_items != num_processes:
        validation_result = ValidationResult.ENOTRECOVERABLE

    return int(validation_result)

if __name__ == '__main__':
    try:
        sys.exit(main())
    except Exception as err:
        print('Unexpected exception: {0}'.format(str(err)))
        sys.exit(int(ValidationResult.ENOTRECOVERABLE))
