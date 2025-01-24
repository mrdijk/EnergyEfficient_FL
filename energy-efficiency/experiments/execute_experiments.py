import requests
import time
import csv
import constants
import argparse
import os

# Function to query Prometheus for energy consumption
def get_energy_consumption():
    # Query Prometheus
    response = requests.get(
        f"{constants.PROMETHEUS_URL}/api/v1/query",
        params={
            # Use range query, as we found that this was the most reliable in our thesis
            "query": constants.PROM_ENERGY_QUERY_RANGE
        },
    )
    # Parse the response JSON
    response_json = response.json()
    # print(f"Prometheus response status code: {response.status_code}")
    # print(f"Prometheus response: {response_json}")

    # Extract the energy data
    energy_data = {}
    # If the query was successful, return the results
    if response.status_code == 200:
        # Construct as readable energy data for each container
        for result in response_json['data']['result']:
            # Extract the container name
            container_name = result['metric'][constants.PROM_KEPLER_CONTAINER_LABEL]
            # Extract the actual result (value[0] is the timestamp)
            value = result['value'][1]
            energy_data[container_name] = value
        # Return result
        return energy_data

    # If request failed, return empty
    return {}

# Main function to execute the experiment
def run_experiment(archetype: str):
    results = []
    # Get request URL based on used data_steward
    data_steward = constants.ARCH_DATA_STEWARDS[archetype]
    data_request_url = constants.REQUEST_URLS[data_steward]
    print(f"Using data steward: {data_steward}, URL:{data_request_url}")
    
    # TODO: uncomment idle energy when done.
    # # Phase 1: Idle period
    # # Wait idle period
    # print("Waiting for idle period...")
    # time.sleep(constants.IDLE_PERIOD)
    # # Measure energy after idle (end_idle/start_active)
    # idle_energy = get_energy_consumption()
    # print(f"Idle Energy: {idle_energy} (in J)")

    # Phase 2: Active period
    runs = {}
    # Record the start time of the active period
    active_start_time = time.time()
    # Execute the runs for this experiment (active state)
    for run in range(constants.NUM_EXP_ACTIONS):
        print(f"\nStarting action {run + 1}/{constants.NUM_EXP_ACTIONS}...")
        # Execute request approval
        response_approval = requests.post(constants.APPROVAL_URL, json=constants.REQUEST_BODY_APPROVAL, headers=constants.HEADERS_APPROVAL)
        # Extract relevant data from the response
        status_code_approval = response_approval.status_code
        execution_time_approval = response_approval.elapsed.total_seconds()
        print(f"Approval request completed with status: {status_code_approval}, execution time: {execution_time_approval}s")
        # Get job-id
        job_id = response_approval.json()["jobId"]
        print(f"Using job-id: {job_id}")

        # Construct data request body
        request_body = constants.INITIAL_REQUEST_BODY
        # Add job-id to request body
        request_body["requestMetadata"] = {"jobId": f"{job_id}"}
        # Execute data request
        response_data_request = requests.post(data_request_url, json=request_body, headers=constants.HEADERS)
        # Extract relevant data from the response
        status_code_data_request = response_data_request.status_code
        execution_time_data_request = response_data_request.elapsed.total_seconds()
        print(f"Data request completed with status: {status_code_data_request}, execution time: {execution_time_data_request}s")
        
        # Save run data
        runs[run] = {} # TODO: save run info, data request as well as approval
        # Apply interval between requests (if not last run of sequence) 
        if (run + 1) != constants.NUM_EXP_ACTIONS:
            print("Waiting before next action...")
            time.sleep(6)

    # Before measuring the active energy, make sure the active period has passed for equal comparisons
    elapsed_time = time.time() - active_start_time
    # Add a few seconds to make sure a new Prometheus scrape is present
    remaining_time = (constants.ACTIVE_PERIOD + 2) - elapsed_time
    # If still time left to wait, sleep until the 2 minutes have passed
    if remaining_time > 0:
        print(f"Waiting for the remaining {remaining_time} seconds...")
        time.sleep(remaining_time)
    # Measure energy after active period (end_active) after the active period
    active_energy = get_energy_consumption()
    print(f"Active Energy: {active_energy} (in J)")

    # # TODO: construct results, with runs, idle_energy, active_energy, etc.

    # # Save experiment results 
    # save_results(results)


def save_results(results):
    print("Saving experiment results to file...")
    # TODO: change to CSV file only, two files for each experiment:
    # runs.csv (each run: run_nr,status_code,execution_time)
    # experiment.csv (<forEachContainerEnergy, for idle and active>,TotalEnergy,average for execution time)
    # TODO: exec time is based on runs

    # TODO: make it save some sort of a timestamp with the filenames to distinquish between them,
    # add it in that folder with the timestamp, then also the files with that timestamp
    
    # Ensure the output directory exists    
    output_dir = 'data'
    os.makedirs(output_dir, exist_ok=True)

    # Save to a file in the specified directory
    # output_file = os.path.join(output_dir, f'{filename}.csv')

    # # Write the data to the output file
    # # df.to_csv(output_file, index=False)

    # # Output file location that is clickable for the user
    # print(f'Saved data to {os.path.join(os.getcwd(), output_file)}')
    
    # Save to CSV
    csv_file = "experiment_results.csv"
    with open(csv_file, mode="w", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=results[0].keys())
        writer.writeheader()
        writer.writerows(results)
    print(f"Results saved to {csv_file}")

    # Save to text file
    txt_file = "experiment_results.txt"
    with open(txt_file, mode="w") as file:
        for result in results:
            file.write(f"{result}\n")
    print(f"Results saved to {txt_file}")
    


if __name__ == "__main__":
    # Add argument parser
    parser = argparse.ArgumentParser(description="Run energy efficiency experiment")
    parser.add_argument("archetypes", type=str, nargs='+', choices=["ComputeToData", "DataThroughTTP"], 
                        help="The archetypes to use for the experiment (must be 'ComputeToData' and/or 'DataThroughTTP')")
    parser.add_argument("exp_reps", type=int, help="The number of times the experiment should be repeated")
    parser.add_argument("exp_name", type=str, help="The name of the experiment (will be used in output files)")
    # Parse args
    args = parser.parse_args()

    # Execute experiment for each archetype and the number of repetitions
    for archetype in args.archetypes:
        print(f"Starting experiments for archetype: {archetype}")
        # Switch on this archetype by updating the weight
        request_body = constants.INITIAL_REQUEST_BODY_ARCH
        # Add weight to request body (setting weight of ComputeToData higher or lower than DataThroughTTP switches archetypes)
        request_body["weight"] = constants.WEIGHTS[archetype]
        print(f"Request body for archetype update: {request_body}")
        # Execute request
        response_archetype_update = requests.put(constants.UPDATE_ARCH_URL, json=request_body, headers=constants.HEADERS_APPROVAL)
        # Print result
        print(f"Switching archetype completed with status: {response_archetype_update.status_code}, execution time: {response_archetype_update.elapsed.total_seconds()}s")

        # Apply short idle period after switching archetypes
        print("Resting for short period before executing next experiments (after switching archetypes)...")
        time.sleep(30)

        # Execute experiments for the number of repetitions for this implementation (with the selected archetype)
        exp_reps = args.exp_reps
        for exp_rep in range(exp_reps):
            # Print a new line before each experiment repetition
            print(f"\nStarting experiment repetition {exp_rep + 1}/{exp_reps} for archetype {archetype}...")
            # Run experiment with args
            run_experiment(archetype)

            # Apply short rest period before the next experiment (if not last experiment of sequence) 
            if (exp_rep + 1) != exp_reps:
                print("Resting for a short period before doing next experiment repetition...")
                time.sleep(30)