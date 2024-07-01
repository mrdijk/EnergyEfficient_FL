from utils import query_prometheus, save_energy_data_to_file
from constants import RELEVANT_PROMETHEUS_CONTAINER_METRICS, RELEVANT_KEPLER_CONTAINER_METRICS, PROMETHEUS_QUERIES

def main():
    # Export specific metrics
    export_specific_metrics()


# Function to calculate energy consumption and save to a file
def calculate_energy_consumption():
    result = query_prometheus(PROMETHEUS_QUERIES['ENERGY_CONSUMPTION'])
    output_data = []
    if result['status'] == 'success':
        data = result['data']['result']
        for item in data:
            pod_name = item['metric'].get('pod_name', 'unknown')
            container_name = item['metric'].get('container_name', 'unknown')
            namespace = item['metric'].get('container_namespace', 'unknown')
            node = item['metric'].get('node', 'unknown')
            power_watts = float(item['value'][1])
            output_data.append({
                'pod_name': pod_name,
                'container_name': container_name,
                'namespace': namespace,
                'node': node,
                'power_watts': power_watts
            })
    
        # Save to a file
        save_energy_data_to_file(output_data, 'energy_consumption')
    else:
        raise Exception(f"Failed to retrieve data: {result['error']}")

# Function to query relevant metrics
def export_specific_metrics():
    output_data = {}

    # Query and filter RELEVANT_KEPLER_CONTAINER_METRICS
    for metric in RELEVANT_KEPLER_CONTAINER_METRICS:
        result = query_prometheus(metric)
        if result['status'] == 'success':
            # Filter out metrics with 0 values (not measured in Kepler)
            # The value will look like this: {metric: [{metric: {key: value}..., value: [timestamp, value]}]
            filtered_data = [
                item for item in result['data']['result'] if float(item['value'][1]) != 0
            ]
            if filtered_data:
                output_data[metric] = filtered_data
        else:
            print(f"Failed to retrieve data for metric {metric}: {result['error']}")

    # Query and add RELEVANT_PROMETHEUS_CONTAINER_METRICS
    for metric in RELEVANT_PROMETHEUS_CONTAINER_METRICS:
        result = query_prometheus(metric)
        if result['status'] == 'success':
            output_data[metric] = result['data']['result']
        else:
            print(f"Failed to retrieve data for metric {metric}: {result['error']}")

    # Save to a file
    save_energy_data_to_file(output_data, 'energy_metrics')
