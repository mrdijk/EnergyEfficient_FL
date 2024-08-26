import csv
import os
import pandas as pd
from pyrca.analyzers.rcd import RCD
# Import utils
from utils import get_folder_path, unix_time_to_datetime

# Folder where the gathered energy metrics are stored
ENERGY_DATA_FOLDER = get_folder_path('data-collection/data', 1)
# Path to the energy metrics file (from get_metrics.py)
ENERGY_DATA_FILE = os.path.join(ENERGY_DATA_FOLDER, 'energy_metrics.csv')
# Folder where the algorithms data is stored
ALGORITHMS_DATA_FOLDER = get_folder_path('data')
# Path to the converted energy metrics file (after CPU conversion)
CONVERTED_ENERGY_DATA_FILE = os.path.join(
    ALGORITHMS_DATA_FOLDER, 'converted_energy_metrics.csv')

# Path to a 'normal' data folder
TRAINING_DATA_FILE = os.path.join(
    ALGORITHMS_DATA_FOLDER, 'converted_energy_metrics_training.csv')

K = 3
col_to_drop = "time" 

def main():
    """
    Main function of the anomaly detection.
    """
    # Execute BIRCH AD algorithm
    run_rcd()


def run_rcd():
    model = RCD(config=RCD.config_class(start_alpha=0.05, k = K, bins= 5, gamma=5, localized=True))
    
    train_df = pd.read_csv(TRAINING_DATA_FILE)
    train_df.drop(columns = col_to_drop, inplace=True)
    train_df = train_df.filter(like='_energy')    
    
    test_df = pd.read_csv(CONVERTED_ENERGY_DATA_FILE)
    test_df.drop(columns = col_to_drop, inplace=True)
    test_df = test_df.filter(like='_energy')    
    
    results = model.find_root_causes(train_df, test_df)
    print_results(results.to_dict())


def print_results(results):   
    # Extracting node names
    nodes_list = [node[0] for node in results['root_cause_nodes']]

    # Writing nodes_list to a CSV file
    csv_filename = f'{ALGORITHMS_DATA_FOLDER}\RCD_RCA_results.csv'

    with open(csv_filename, mode='w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(['Root Cause'])
        writer.writerows([[node] for node in nodes_list])

                            