from datetime import datetime
import os
import shutil
from typing import List, Union
from pycaret.anomaly import *
import numpy as np
import pandas as pd
# Import BIRCH libraries (sklearn comes from "pip install scikit-learn")
from sklearn.cluster import Birch
from sklearn import preprocessing
from scipy.spatial import distance
# Import utils
from utils import get_folder_path, unix_time_to_datetime

# Folder where the gathered energy metrics are stored
ENERGY_DATA_FOLDER = get_folder_path('data-collection/data', 1)
ENERGY_DATA_FILE = os.path.join(ENERGY_DATA_FOLDER, 'energy_metrics.csv')
# Folder where the algorithms data is stored
ALGORITHMS_DATA_FOLDER = get_folder_path('data')
print(ENERGY_DATA_FOLDER, ALGORITHMS_DATA_FOLDER)

def main():
    """
    Main function of the anomaly detection. 
    """
    # Convert the CPU metrics to percentage
    cpu_to_percentage()                      

    # # Create model training dataset with a 'normal' dataset
    # train_BIRCH_AD_model() 

    # # Create the Ground Truth
    # create_ground_truth()

    # # Execute BIRCH AD algorithm
    # execute_BIRCH()


def cpu_to_percentage() -> None:
    print("Converting CPU metrics to percentage...")

    # Read the CSV file and parse the 'time' column while converting Unix timestamps
    result_df = pd.read_csv(ENERGY_DATA_FILE, parse_dates=["time"], date_parser=unix_time_to_datetime)

    # Additional processing remains the same
    temp_df = pd.read_csv(ENERGY_DATA_FILE)

    # Convert the cpu metrics to percentage
    for col in result_df.columns:
        if col.endswith("_cpu"):
            # Multiply the value by 100 to get the cpu percentage
            temp_df[col] = result_df[col] * 100

    # Remove disk data due to the existing bug in Cadvisor
    columns_to_drop = [col for col in temp_df.columns if '_disk' in col]
    temp_df.drop(columns=columns_to_drop, inplace=True)
    
    # Save the converted file in the data folder
    output_file = os.path.join(ALGORITHMS_DATA_FOLDER, f'converted_energy_metrics.csv')
    print(f"Saving the converted data to {output_file}...")
    # Write the data to the output file
    temp_df.to_csv(output_file, index=False)
    

    
    
    


