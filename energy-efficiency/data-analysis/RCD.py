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

# Path to a 'normal' data folder for training the RCD model
TRAINING_DATA_FILE = os.path.join(
    ALGORITHMS_DATA_FOLDER, 'normal_energy_metrics_training.csv')

# Set the top-k parameter for the RCD model (number of root causes to identify)
K = 3

def main():
    """
    Main function for root cause analysis.
    """
    # Execute algorithm
    run_rcd()


def run_rcd():
    print("Start executing RCD Root Cause Analysis algorithm...")
    # Define the column name that should be dropped from the dataset
    col_to_drop = "time" 

    # Initialize the RCD model with specific configuration parameters
    model = RCD(config=RCD.config_class(
        # Significance level for statistical tests
        start_alpha=0.05,
        # Number of top root causes to identify
        k=K,
        # Number of bins to discretize continuous data
        bins=5,
        # Regularization parameter
        gamma=5,
        # Perform localized root cause analysis
        localized=True
    ))
    
    # Load the training dataset from the specified CSV file
    train_df = pd.read_csv(TRAINING_DATA_FILE)
    # Drop the specified column from the dataset
    train_df.drop(columns = col_to_drop, inplace=True)
    # Filter the dataset to only include columns that contain '_energy'
    train_df = train_df.filter(like='_energy')    
    
    # Load the testing dataset from the specified CSV file
    test_df = pd.read_csv(ENERGY_DATA_FILE)
    test_df.drop(columns = col_to_drop, inplace=True)
    test_df = test_df.filter(like='_energy')    
    
    # Use the RCD model to find root causes based on the training and testing data
    results = model.find_root_causes(train_df, test_df)
    # Print and save the results of the root cause analysis
    print_results(results.to_dict())


def print_results(results):
    # Extract the root cause nodes from the results dictionary
    nodes_list = [node[0] for node in results['root_cause_nodes']]

    # Define the filename for saving the results
    csv_filename = os.path.join(ALGORITHMS_DATA_FOLDER, 'RCD_RCA_results.csv')

    print(f"Saving RCD results data to {csv_filename}...")

    # Open the file in write mode and write the root cause nodes to it
    with open(csv_filename, mode='w', newline='') as file:
        writer = csv.writer(file)
        # Write the header for the CSV file
        writer.writerow(['Root Cause'])
        # Write each root cause node as a new row in the CSV file
        writer.writerows([[node] for node in nodes_list])