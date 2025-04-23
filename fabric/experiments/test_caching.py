import requests
import time
import constants
import argparse

# This file is used for the demo video where the caching implementation is presented. 
# To execute this script on the FABRIC k8s-control-plane node, add it at the same location as the constants.py and execute_experiments.py, such as:
# ./upload_to_remote.sh ../experiments/test_caching.py ~/.ssh/slice_key ../fabric_config/ssh_config_upload_script ubuntu dynamos-node "~/experiments"
# You can run it on the node in SSH with the following command to view the results in the console: python3 test_caching.py 

# Main function to execute the test
def run_test():
    # ================================================ Action 1: without caching ================================================
    print("================================================================================================")
    # Perform an action that changes the request so the cache is reset. For example, switch archetypes to ComputeToData:
    archetype = constants.ARCHETYPES[0]
    print(f"Switching archetypes to {archetype}...")
    # Switch on this archetype by updating the weight
    request_body_arch = constants.INITIAL_REQUEST_BODY_ARCH
    # Add weight to request body (setting weight of ComputeToData higher or lower than DataThroughTTP switches archetypes)
    request_body_arch["weight"] = constants.WEIGHTS[archetype]
    print(f"Request body for archetype update: {request_body_arch}")
    # Execute request, using specific headers for updating archetype this time for FABRIC Kubernetes environment (contains correct host)
    response_archetype_update = requests.put(constants.UPDATE_ARCH_URL, json=request_body_arch, headers=constants.HEADERS_UPDATE_ARCH)
    # Print result
    print(f"Switching archetype completed with status: {response_archetype_update.status_code}, execution time: {response_archetype_update.elapsed.total_seconds()}s")
    # Apply short idle period after switching archetypes
    print("Resting for short period before executing next experiments (after switching archetypes)...")
    time.sleep(5)

    # Get request URL based on used data_steward, use ComputeToData archetype first
    data_steward = constants.ARCH_DATA_STEWARDS[archetype]
    data_request_url = constants.REQUEST_URLS[data_steward]
    print(f"Using data steward: {data_steward}, URL:{data_request_url}")

    print(f"\nAction 1: without cache...")
    # Request approval
    print(f"Requesting approval...")
    print(f"Request body for approval: {constants.REQUEST_BODY_APPROVAL}")
    # Execute request approval
    act1_response_approval = requests.post(constants.APPROVAL_URL, json=constants.REQUEST_BODY_APPROVAL, headers=constants.HEADERS_APPROVAL)
    act1_job_id = handle_request_approval_response(act1_response_approval)
    # Request data
    print(f"Requesting data...")
    # Construct data request body
    request_body = constants.INITIAL_REQUEST_BODY
    # Add job-id to request body
    request_body["requestMetadata"] = {"jobId": f"{act1_job_id}"}
    # Prepare headers, this contains specific FABRIC Kubernetes setup, where the Host is required in the headers (see fabric/dynamos/DYNAMOS_setup.ipynb curl example):
    headers = constants.HEADERS.copy()
    headers["Host"] = f"{data_steward}.{data_steward}.svc.cluster.local"
    # Execute data request, using specific headers created for FABRIC
    act1_response_data_request = requests.post(data_request_url, json=request_body, headers=headers)
    # Handle data request
    handle_data_request_response(act1_response_data_request)
    # Wait shortly before next request, also to catch my breath during the demo video presentation
    time.sleep(10)
    # ================================================ Action 2: Get from cache ================================================
    print(f"\nAction 2: with cache...")
    # Request approval
    print(f"Requesting approval...")
    # Execute request approval
    act2_response_approval = requests.post(constants.APPROVAL_URL, json=constants.REQUEST_BODY_APPROVAL, headers=constants.HEADERS_APPROVAL)
    act2_job_id = handle_request_approval_response(act2_response_approval)
    # Request data
    print(f"Requesting data...")
    # Change job id in request body
    request_body["requestMetadata"] = {"jobId": f"{act2_job_id}"}
    # Execute data request, reusing headers and body from previous request
    act2_response_data_request = requests.post(data_request_url, json=request_body, headers=headers)
    # Handle data request
    handle_data_request_response(act2_response_data_request)
    # Wait shortly before next request, also to catch my breath during the demo video presentation
    time.sleep(10)

    # ================================================ Action 3: different request, should perform request again ================================================
    print("\n================================================================================================")
    # Perform an action that changes the request so the cache is reset. For example, switch archetypes to DataThroughTTP:
    archetype = constants.ARCHETYPES[1]
    print(f"Switching archetypes to {archetype}...")
    # Switch on this archetype by updating the weight
    request_body_arch = constants.INITIAL_REQUEST_BODY_ARCH
    # Add weight to request body (setting weight of ComputeToData higher or lower than DataThroughTTP switches archetypes)
    request_body_arch["weight"] = constants.WEIGHTS[archetype]
    print(f"Request body for archetype update: {request_body_arch}")
    # Execute request, using specific headers for updating archetype this time for FABRIC Kubernetes environment (contains correct host)
    response_archetype_update = requests.put(constants.UPDATE_ARCH_URL, json=request_body_arch, headers=constants.HEADERS_UPDATE_ARCH)
    # Print result
    print(f"Switching archetype completed with status: {response_archetype_update.status_code}, execution time: {response_archetype_update.elapsed.total_seconds()}s")
    # Apply short idle period after switching archetypes
    print("Resting for short period before executing next experiments (after switching archetypes)...")
    time.sleep(10)

    # Get request URL based on used data_steward
    data_steward = constants.ARCH_DATA_STEWARDS[archetype]
    data_request_url = constants.REQUEST_URLS[data_steward]
    print(f"Using data steward: {data_steward}, URL:{data_request_url}")
    
    print(f"\nAction 3: without cache (different request: switched archetypes)...")
    # Request approval
    print(f"Requesting approval...")
    print(f"Request body for approval: {constants.REQUEST_BODY_APPROVAL}")
    # Execute request approval
    act3_response_approval = requests.post(constants.APPROVAL_URL, json=constants.REQUEST_BODY_APPROVAL, headers=constants.HEADERS_APPROVAL)
    act3_job_id = handle_request_approval_response(act3_response_approval)
    # Request data
    print(f"Requesting data...")
    # Construct data request body
    request_body = constants.INITIAL_REQUEST_BODY
    # Add job-id to request body
    request_body["requestMetadata"] = {"jobId": f"{act3_job_id}"}
    # Prepare headers, this contains specific FABRIC Kubernetes setup, where the Host is required in the headers (see fabric/dynamos/DYNAMOS_setup.ipynb curl example):
    headers = constants.HEADERS.copy()
    headers["Host"] = f"{data_steward}.{data_steward}.svc.cluster.local"
    # Execute data request, using specific headers created for FABRIC
    act3_response_data_request = requests.post(data_request_url, json=request_body, headers=headers)
    # Handle data request
    handle_data_request_response(act3_response_data_request)
    # Wait shortly before next request, also to catch my breath during the demo video presentation
    time.sleep(10)
    # ================================================ Action 4: get from cache again after different request ================================================
    print(f"\nAction 4: with cache...")
    # Request approval
    print(f"Requesting approval...")
    # Execute request approval
    act4_response_approval = requests.post(constants.APPROVAL_URL, json=constants.REQUEST_BODY_APPROVAL, headers=constants.HEADERS_APPROVAL)
    act4_job_id = handle_request_approval_response(act4_response_approval)
    # Request data
    print(f"Requesting data...")
    # Change job id in request body
    request_body["requestMetadata"] = {"jobId": f"{act4_job_id}"}
    # Execute data request, reusing headers and body from previous request
    act4_response_data_request = requests.post(data_request_url, json=request_body, headers=headers)
    # Handle data request
    handle_data_request_response(act4_response_data_request)
    # Wait shortly before next request, also to catch my breath during the demo video presentation
    time.sleep(10)

    # ================================================ Action 5: different request, should perform request again ================================================
    print("\n================================================================================================")
    # Perform an action that changes the request so the cache is reset. For example, change request approval:
    print(f"\nAction 5: without cache (different request: changed data providers)...")
    # Request approval
    print(f"Requesting approval...")
    # Change request body to change request for cache testing
    approval_body = constants.REQUEST_BODY_APPROVAL.copy()
    approval_body["dataProviders"] = ["UVA", "VU"]
    print(f"Request body for approval: {approval_body}")
    # Execute request approval
    act5_response_approval = requests.post(constants.APPROVAL_URL, json=approval_body, headers=constants.HEADERS_APPROVAL)
    act5_job_id = handle_request_approval_response(act5_response_approval)
    # Request data
    print(f"Requesting data...")
    # Construct data request body
    request_body = constants.INITIAL_REQUEST_BODY
    # Add job-id to request body
    request_body["requestMetadata"] = {"jobId": f"{act5_job_id}"}
    # Prepare headers, this contains specific FABRIC Kubernetes setup, where the Host is required in the headers (see fabric/dynamos/DYNAMOS_setup.ipynb curl example):
    headers = constants.HEADERS.copy()
    headers["Host"] = f"{data_steward}.{data_steward}.svc.cluster.local"
    # Execute data request, using specific headers created for FABRIC
    act5_response_data_request = requests.post(data_request_url, json=request_body, headers=headers)
    # Handle data request
    handle_data_request_response(act5_response_data_request)
    # Wait shortly before next request, also to catch my breath during the demo video presentation
    time.sleep(10)
    # ================================================ Action 6: get from cache again after different request ================================================
    print(f"\nAction 6: with cache...")
    # Request approval
    print(f"Requesting approval...")
    # Execute request approval
    act6_response_approval = requests.post(constants.APPROVAL_URL, json=approval_body, headers=constants.HEADERS_APPROVAL)
    act6_job_id = handle_request_approval_response(act6_response_approval)
    # Request data
    print(f"Requesting data...")
    # Change job id in request body
    request_body["requestMetadata"] = {"jobId": f"{act6_job_id}"}
    # Execute data request, reusing headers and body from previous request
    act6_response_data_request = requests.post(data_request_url, json=request_body, headers=headers)
    # Handle data request
    handle_data_request_response(act6_response_data_request)


def handle_request_approval_response(response_approval):
    # Extract relevant data from the response
    status_code_approval = response_approval.status_code
    execution_time_approval = response_approval.elapsed.total_seconds()
    print(f"Approval request completed with status: {status_code_approval}, execution time: {execution_time_approval}s")
    # Get job-id
    job_id = response_approval.json()["jobId"]
    print(f"Using job-id: {job_id}")
    return job_id

def handle_data_request_response(response_data_request):
    # Extract relevant data from the response
    status_code_data_request = response_data_request.status_code
    execution_time_data_request = response_data_request.elapsed.total_seconds()
    # Get the size of the response content in bytes
    response_size = len(response_data_request.content)
    print(f"Data request completed with status: {status_code_data_request}, execution time: {execution_time_data_request}s, response size: {response_size} bytes")


if __name__ == "__main__":
    # Execute the test for caching:
    run_test()
