import requests
import json
import os
import time

from constants import PROMETHEUS_URL, METRIC_STEP


def query_prometheus(query, start_time=None, end_time=None):
    """
    TODO: Add docstring. Function to query Prometheus.

    
    """
    # Default is now and 30 minutes ago.
    if start_time is None or end_time is None:
        start_time, end_time = get_time_range()

    # Query Prometheus with a time range
    response = requests.get(
        f"{PROMETHEUS_URL}/api/v1/query_range",
        params={
            "query": query,
            "start": start_time,
            "end": end_time,
            "step": f"{METRIC_STEP}s",
        },
    )

    # If the query was successful, return the results
    if response.status_code == 200:
        return response.json()["data"]["result"]
    else:
        raise Exception(
            f"Query failed with status code {response.status_code}: {response.content}")


    # url = f'{PROMETHEUS_URL}/api/v1/query'
    # response = requests.get(url, params={'query': query})
    # if response.status_code == 200:
    #     return response.json()
    # else:
    #     raise Exception(
    #         f"Query failed with status code {response.status_code}: {response.content}")


def get_time_range(minutes_before=30):
    """
    Returns the current time and the time 'minutes_before' minutes ago.

    :param minutes_before: The number of minutes before the current time to calculate.
    :return: Tuple of (start_time, end_time) in seconds since the epoch.
    """
    # Get the current time
    end_time = time.time()
    # Calculate the start time (minutes_before minutes before the current time)
    start_time = end_time - (minutes_before * 60)

    return start_time, end_time

def save_energy_data_to_file(data, filename, indent=4):
    """
    TODO: Add docstring. Function to save energy data to a file.
    """
    # TODO: use pandas and write to csv
    output_dir = 'data'

    # Ensure the output directory exists
    os.makedirs(output_dir, exist_ok=True)

    # Save to a file in the specified directory
    output_file = os.path.join(output_dir, f'{filename}.json')

    # Write the data to the output file
    with open(output_file, 'w') as f:
        json.dump(data, f, indent=indent)

    print(f'Saved data to {output_file}')
