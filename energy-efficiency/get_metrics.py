from utils import get_time_range, save_energy_data_to_file
import numpy as np
import pandas as pd
import requests
from constants import QUERIES, METRIC_STEP, MAX_RESOLUTION, CONTAINERS, PROMETHEUS_URL, KEPLER_CONTAINER_NAME_LABEL, CADVISOR_CONTAINER_NAME_LABEL


def main():
    # Get the time using the util function
    start, end = get_time_range(15)

    # Get the data for all the queries
    df = pd.DataFrame(
        make_dict_list_equal(get_data(start, end))
    )

    # Save the data to a file
    save_energy_data_to_file(df, 'energy_metrics')


def exec_query(query, start_time, end_time):
    """
    TODO: Add docstring. Function to query Prometheus.
    """
    print(f"Querying Prometheus with query: {query}")
    print(f"Start time: {start_time}, End time: {end_time}")
    
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

        # Loop through the results
        for result in results:
            # Initialize container_name as None
            container_name = None

            # Check if the result contains specific keys (required to identify the container used)
            if not all(
                k not in result["metric"].keys() for k in [KEPLER_CONTAINER_NAME_LABEL, CADVISOR_CONTAINER_NAME_LABEL]
            ):
                return

            print(result["metric"].keys())

            # Get the container name from the result
            if KEPLER_CONTAINER_NAME_LABEL in result["metric"]:
                container_name = result["metric"][KEPLER_CONTAINER_NAME_LABEL]
            elif CADVISOR_CONTAINER_NAME_LABEL in result["metric"]:
                container_name = result["metric"][CADVISOR_CONTAINER_NAME_LABEL]
        
            # Only add the data if the container name is in the containers list
            if container_name in CONTAINERS:
                data[container_name] = result["values"]

        # Return the data
        return data
    else:
        raise Exception(
            f"Query failed with status code {response.status_code}: {response.content}")


def get_data_for_query(query, start, end):
    """
    Given a valid query, extracts the relevant data
    """
    # If all the data can be collected in only one request return the data
    if not (end - start) / METRIC_STEP > MAX_RESOLUTION:
        return exec_query(query, start, end)

    # Otherwise, collect the data in multiple requests
    data = {}
    start_time = start
    end_time = start
    while end_time < end:
        end_time = min(end_time + MAX_RESOLUTION, end)
        print(f"Querying data from {start_time} to {end_time}")
        # Get the data for the current time range
        d = exec_query(query, start_time, end_time)
        # Merge the data
        data = _merge(data, d)
        # Update the start time for the next query
        start_time = end_time + 1

    # Return the data
    return data


def _merge(x, y):
    """
    Merge two dictionaries of lists by appending the entries to the list.
    y will be append at the end of x.
    """
    data = x
    for key in y:
        data[key] = x.get(key, []) + y[key]
    return data


def get_data(start, end):
    """
    Get the data for all the different queries

    """
    # Use Default if start_time and end_time are not provided
    if start is None or end is None:
        start, end = get_time_range()

    data = {}

    # Get the data for each query (name, query)
    for name, query in QUERIES.items():
        print(f"Working on query for {name}...")
        # Use the util function to get the data for the query
        data[name] = get_data_for_query(query, start, end)

    columns = {}
    for m, containers in data.items():
        for c, info in containers.items():
            i = np.array(info)
            time = i[0:, 0]
            values = i[0:, 1]
            if len(columns) == 0:
                columns["time"] = time
            if len(columns["time"]) < len(time):
                columns["time"] = time
            columns[f"{c}_{m}"] = values
    return columns


def make_dict_list_equal(dict_list):
    l_min = float("inf")
    for key in dict_list:
        l_min = min(l_min, len(dict_list[key]))

    new_dict = {}
    for key, old_list in dict_list.items():
        new_list = old_list
        if len(old_list) > l_min:
            print(
                f"Discarding {len(old_list) - l_min} entries from the end of the column name {key}"
            )
            new_list = old_list[:l_min]
        new_dict[key] = new_list
    return new_dict


# TODO: old solution, remove later
# # Function to calculate energy consumption and save to a file
# def calculate_energy_consumption():
#     output_data = {}
#     # Query Prometheus to get the energy consumption
#     result = query_prometheus(PROMETHEUS_QUERIES['ENERGY_CONSUMPTION'])
#     # Check if the query was successful
#     if result['status'] == 'success':
#         # Add the data to the output with the key 'energy_consumption'
#         output_data['energy_consumption'] = result
#     else:
#         raise Exception(f"Failed to retrieve data: {result['error']}")

#     # Return the data
#     return output_data

# # Function to query relevant metrics
# def get_relevant_metrics():
#     output_data = {}

#     # Query and filter RELEVANT_KEPLER_CONTAINER_METRICS
#     for metric in RELEVANT_KEPLER_CONTAINER_METRICS:
#         # Query Prometheus to get the metric
#         result = query_prometheus(metric)
#         # Check if the query was successful
#         if result['status'] == 'success':
#             # Filter out metrics with 0 values (not measured in Kepler)
#             # The value will look like this: {metric: [{metric: {key: value}..., value: [timestamp, value]}]
#             filtered_data = [
#                 item for item in result if float(item['value'][1]) != 0
#             ]
#             if filtered_data:
#                 output_data[metric] = filtered_data
#         else:
#             print(f"Failed to retrieve data for metric {metric}: {result['error']}")

#     # Query and add RELEVANT_PROMETHEUS_CONTAINER_METRICS
#     for metric in RELEVANT_PROMETHEUS_CONTAINER_METRICS:
#         # Query Prometheus to get the metric
#         result = query_prometheus(metric)
#         # Check if the query was successful
#         if result['status'] == 'success':
#             # Add the data to the output with the key {metric}
#             output_data[metric] = result
#         else:
#             print(f"Failed to retrieve data for metric {metric}: {result['error']}")

#     # Return the data
#     return output_data
