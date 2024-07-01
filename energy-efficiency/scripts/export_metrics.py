import requests
import json
from utils import query_prometheus, RELEVANT_CONTAINER_METRICS

# Function to query specific metrics and save to a file
def export_specific_metrics():
    output_data = {}
    for metric in RELEVANT_CONTAINER_METRICS:
        print(f"Querying metric: {metric}")
        result = query_prometheus(metric)
        if result['status'] == 'success':
            output_data[metric] = result['data']['result']
        else:
            print(f"Failed to retrieve data for metric {metric}: {result['error']}")

    # Save to a file
    with open('specific_metrics.json', 'w') as f:
        json.dump(output_data, f, indent=4)

# Run the export
export_specific_metrics()
