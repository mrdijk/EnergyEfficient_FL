import requests
import json
import os

from constants import PROMETHEUS_URL

# Function to query Prometheus


def query_prometheus(query):
    url = f'{PROMETHEUS_URL}/api/v1/query'
    response = requests.get(url, params={'query': query})
    if response.status_code == 200:
        return response.json()
    else:
        raise Exception(
            f"Query failed with status code {response.status_code}: {response.content}")


# Save energy data to file
def save_energy_data_to_file(data, filename, indent=4):
    output_dir = 'data'

    # Ensure the output directory exists
    os.makedirs(output_dir, exist_ok=True)

    # Save to a file in the specified directory
    output_file = os.path.join(output_dir, f'{filename}.json')

    # Write the data to the output file
    with open(output_file, 'w') as f:
        json.dump(data, f, indent=indent)

    print(f'Saved data to {output_file}')
