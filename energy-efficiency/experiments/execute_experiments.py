import requests
import time
import csv
import constants
import argparse

# Function to query Prometheus for energy consumption
def get_energy_consumption():
    # Query Prometheus
    response = requests.get(
        f"{constants.PROMETHEUS_URL}/api/v1/query",
        params={
            "query": constants.PROM_ENERGY_QUERY_TOTAL
        },
    )
    # Parse the response JSON
    response_json = response.json()
    print(f"Prometheus response status code: {response.status_code}")

    # Extract the energy data
    energy_data = {}
    # If the query was successful, return the results
    if response.status_code == 200:
        # Construct as readable energy data for each container
        for result in response_json['data']['result']:
            container_name = result['metric'][constants.PROM_KEPLER_CONTAINER_LABEL]
            value = result['value'][1]
            energy_data[container_name] = value
        # Print parsed result
        print(f"Prometheus response status code: {response.status_code}")

    return {}

# Main function to execute the experiment
def run_experiment(data_steward: str, job_id: str):
    results = []
    # Get request URL based on used data_steward
    request_url = constants.REQUEST_URLS[data_steward]
    print(f"Using data steward: {data_steward}, \nURL:{request_url}")
    # Set request body
    request_body = constants.INITIAL_REQUEST_BODY
    # Add job-id to request body
    request_body["requestMetadata"] = {"jobId": f"{constants.JOB_ID_PREFIX}{job_id}"}
    print(f"Using request body: {request_body}")

    # Step 1: Measure energy (start_idle)
    start_idle = get_energy_consumption()
    print(f"Start Idle Energy: {start_idle} J")
    # Wait idle period
    print("Waiting for idle period...")
    time.sleep(constants.IDLE_PERIOD)
    # Measure energy after idle (end_idle/start_active)
    end_idle_start_active = get_energy_consumption()
    print(f"End Idle/Start Active Energy: {end_idle_start_active} J")

    # Execute the runs for this experiment (active state)
    for run in range(constants.NUM_EXP_ACTIONS):
        print(f"Starting action {run + 1}/{constants.NUM_EXP_ACTIONS}...")

        # Execute data request
        response = requests.post(request_url, json=request_body, headers=constants.HEADERS)
        status_code = response.status_code
        execution_time = response.elapsed.total_seconds()
        print(f"Request completed with status: {status_code}, execution time: {execution_time}s")
        time.sleep(6)  # Interval between requests    

    # Measure energy after active period (end_active) after the active period
    # TODO: add here measuring it if constants.ACTIVE_PERIOD has passed
    end_active = get_energy_consumption()
    # TODO: also print elapsed time before measuring energy here
    print(f"End Active Energy: {end_active} J")

    # Calculate energy consumption for this experiment
    idle_energy = end_idle_start_active - start_idle
    active_energy = end_active - end_idle_start_active

    # Save results for this run
    results.append({
        "Run": run + 1,
        "Start Idle Energy (J)": start_idle,
        "End Idle Energy/Start Active (J)": end_idle_start_active,
        "End Active Energy (J)": end_active,
        "Idle Energy (J)": idle_energy,
        "Active Energy (J)": active_energy
    })

    # Save results to files
    save_results(results)

def save_results(results):
    print("Saving experiment results to file...")
    # TODO: change to CSV file only, two files for each experiment:
    # runs.csv (each run: run_nr,status_code,execution_time,etc.)
    # experiment.csv (energy_idle,energy_active,total_exec_time)
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
    parser.add_argument("data_steward", type=str, choices=["uva", "surf"], help="The data steward to use for the experiment (must be 'uva' or 'surf')")
    parser.add_argument("exp_reps", type=int, help="The number of times the experiment should be repeated")
    parser.add_argument("job_id", type=str, help="The job ID for the experiment (only the final unique id part)")
    args = parser.parse_args()

    # Execute experiment for the number of repetitions
    exp_reps = args.exp_reps
    for exp_rep in range(exp_reps):
        print(f"Starting experiment repetition {exp_rep + 1}/{exp_reps}...")
        # Run experiment with args
        run_experiment(args.data_steward, args.job_id)

        # Apply short rest period before the next experiment
        print("Resting for a short period...")
        time.sleep(10)  # Short rest period between runs