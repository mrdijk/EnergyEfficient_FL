import requests
import time
import constants
import argparse
import statistics

# This file is used for a simple experiment to test the archetype setups for a possible explanation on their difference. 
# To execute this script on the FABRIC k8s-control-plane node, add it at the same location as the constants.py and execute_experiments.py, such as:
# ./upload_to_remote.sh ../experiments/test_archetypes.py ~/.ssh/slice_key ../fabric_config/ssh_config_upload_script ubuntu dynamos-node "~/experiments"
# You can run it on the node in SSH with the following command to view the results in the console: python3 test_archetypes.py 
# You can also run this file locally by copying it temporarily to the energy-efficiency/experiments folder and executing it there.
# You can save the results by copying the logs in the console to a .log file in the data-fabric folder for example.

def switch_archetype(archetype):
    """
    Switches the system to use a specific archetype by modifying the weight
    in the request and sending an update to the appropriate endpoint.
    """
    print(f"Switching archetypes to {archetype}...")
    
    # Create body for archetype switch request
    request_body_arch = constants.INITIAL_REQUEST_BODY_ARCH
    request_body_arch["weight"] = constants.WEIGHTS[archetype]  # Set new weight
    
    # Send PUT request to update archetype
    response = requests.put(constants.UPDATE_ARCH_URL, json=request_body_arch, headers=constants.HEADERS_UPDATE_ARCH)
    print(f"Archetype switch response: {response.status_code}, time: {response.elapsed.total_seconds()}s")
    
    # Wait briefly to ensure the change propagates before next experiment
    time.sleep(5)

def run_requests(data_steward, data_request_url, approval_body, label, count=10):
    """
    Runs 'count' iterations of request approval + data request with a specified approval body.
    Measures and returns execution times of data requests.
    """
    print(f"\nRunning {label} ({count} iterations)...")
    exec_times = []

    for i in range(count):
        print(f"Iteration {i+1}/{count}...")

        # ============ STEP 1: Approval Request ============
        response_approval = requests.post(constants.APPROVAL_URL, json=approval_body, headers=constants.HEADERS_APPROVAL)
        job_id = handle_request_approval_response(response_approval)

        # ============ STEP 2: Data Request ============
        request_body = constants.INITIAL_REQUEST_BODY
        request_body["requestMetadata"] = {"jobId": f"{job_id}"}  # Embed job ID into metadata

        # Set correct host header based on steward (important for routing in Kubernetes)
        headers = constants.HEADERS.copy()
        headers["Host"] = f"{data_steward}.{data_steward}.svc.cluster.local"

        # Send data request and record execution time
        response_data = requests.post(data_request_url, json=request_body, headers=headers)
        exec_time = handle_data_request_response(response_data)
        exec_times.append(exec_time)

        # Short wait to avoid overloading or tight loops, similar to full experiments execution for thesis
        time.sleep(7)

    return exec_times

def handle_request_approval_response(response):
    """
    Handles response from approval request, logs status and time,
    and extracts the job ID needed for the data request.
    """
    print(f"Approval: Status {response.status_code}, Time {response.elapsed.total_seconds()}s")
    return response.json()["jobId"]

def handle_data_request_response(response):
    """
    Handles response from data request, logs status, time, and content size.
    Returns execution time.
    """
    exec_time = response.elapsed.total_seconds()
    print(f"Data: Status {response.status_code}, Time {exec_time}s, Size {len(response.content)} bytes")
    return exec_time

def print_summary(label, times):
    """
    Prints individual execution times and the mean for a given run.
    """
    print(f"\n--- {label} ---")
    for i, t in enumerate(times):
        print(f"Execution {i+1}: {t:.4f}s")
    print(f"Mean time: {statistics.mean(times):.4f}s")

def run_test():
    """
    Main test driver that runs two complete setups:
    Each archetype is tested with both standard and modified approval request bodies.
    """
    all_results = {}  # Dictionary to store all results

    # Iterate through the first two archetypes (e.g., ComputeToData, DataThroughTTP)
    for idx, archetype in enumerate(constants.ARCHETYPES[:2]):
        print(f"\n========== SETUP {idx+1} | Archetype: {archetype} ==========")
        
        # Switch to the selected archetype
        switch_archetype(archetype)

        # Lookup appropriate data steward and URL for this archetype
        data_steward = constants.ARCH_DATA_STEWARDS[archetype]
        data_request_url = constants.REQUEST_URLS[data_steward]

        # ---------- Test with standard approval request ----------
        result_key_1 = f"Arch{idx+1}_Standard"
        all_results[result_key_1] = run_requests(
            data_steward, data_request_url, constants.REQUEST_BODY_APPROVAL, label=result_key_1)

        # ---------- Test with modified approval request ----------
        modified_approval = constants.REQUEST_BODY_APPROVAL.copy()
        modified_approval["dataProviders"] = ["UVA", "VU"]  # Change providers
        result_key_2 = f"Arch{idx+1}_Modified"
        all_results[result_key_2] = run_requests(
            data_steward, data_request_url, modified_approval, label=result_key_2)

    # ========== Print Final Summary ==========
    print("\n================== RESULTS SUMMARY ==================")
    for label, times in all_results.items():
        print_summary(label, times)

# Entry point
if __name__ == "__main__":
    run_test()