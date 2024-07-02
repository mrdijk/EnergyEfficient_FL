import requests
import os
import time
import pandas as pd

from constants import PROMETHEUS_URL, METRIC_STEP, CONTAINERS


def exec_query(query, start_time, end_time):
    """
    TODO: Add docstring. Function to query Prometheus.

    
    """
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
        # Initialize a dictoinary to store the data
        data = {}
        # Get the result from the response
        results = response.json()["data"]["result"]

        # TODO: check contains substring, because it includes some string id
        # Loop through the results
        for result in results:
            print(result["metric"].keys())
            # Check if the container name is in the result (Otherwise do nothing)
            if "container_name" in result["metric"]:
                # Get the container name from the result
                container_name = result["metric"]["container_name"]
                # Only add the data if the container name is in the containers list
                if container_name in CONTAINERS:
                    data[container_name] = result["values"]
        # Return the data
        return data
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

def _merge(x, y):
    """
    Merge two dictionaries of lists by appending the entries to the list.
    y will be append at the end of x.
    """
    data = x
    for key in y:
        data[key] = x.get(key, []) + y[key]
    return data

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

def save_energy_data_to_file(df: pd.DataFrame, filename: str):
    """
    TODO: Add docstring. Function to save energy data to a file.
    """
    output_dir = 'data'

    # Ensure the output directory exists
    os.makedirs(output_dir, exist_ok=True)

    # Save to a file in the specified directory
    output_file = os.path.join(output_dir, f'{filename}.csv')

    # Write the data to the output file
    df.to_csv(output_file, index=False)

    print(f'Saved data to {output_file}')
