import requests
import json
from utils import query_prometheus, PROMETHEUS_QUERIES

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
        with open('energy_consumption.json', 'w') as f:
            json.dump(output_data, f, indent=4)
    else:
        raise Exception(f"Failed to retrieve data: {result['error']}")

# Run the calculation
calculate_energy_consumption()
