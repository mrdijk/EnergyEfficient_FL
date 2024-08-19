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
    

# TODO: only BIRCH needs to be trained, and the combinations can be skipped probably!
def combine_normal_operations_and_train_AD_models() -> None:
    """
    This function combines all the CSV files in the data/normal folder into a single CSV file.
    The combined file is stored in data/normal/normal_combined.csv.
    The combined file is also stored in the current working directory.

    The function returns nothing.
    """
    user_factors = [folder for folder in os.listdir(NORMAL_DATA_PATH) if os.path.isdir(os.path.join(NORMAL_DATA_PATH, folder))]
    for user in user_factors:        
        scenario_factors = [folder for folder in os.listdir(os.path.join(NORMAL_DATA_PATH, user)) if os.path.isdir(os.path.join(NORMAL_DATA_PATH, user, folder))]
        for scenario in scenario_factors:
            time_windows = [folder for folder in os.listdir(os.path.join(NORMAL_DATA_PATH, user, scenario)) if os.path.isdir(os.path.join(NORMAL_DATA_PATH, user, scenario, folder))]
            for time_window in time_windows:            
                # Initialize an empty list to store DataFrames
                dfs = []            
                trials = [folder for folder in os.listdir(os.path.join(NORMAL_DATA_PATH, user, scenario, time_window)) if os.path.isdir(os.path.join(NORMAL_DATA_PATH, user, scenario, time_window, folder))]
                for trial in trials:            
                    trial_path = os.path.join(NORMAL_DATA_PATH, user, scenario, time_window, trial)
                    # Iterate over all the files in the folder
                    for filename in os.listdir(trial_path):
                        if not filename.endswith(".csv"):
                            continue
                        if "combined" in filename:
                            continue
                        if not "data" in filename:
                            continue

                        # Ensure we only process CSV files, adjust the extension if necessary
                        file_path = os.path.join(trial_path, filename)
                        # Read the file data and append it to the list
                        df = pd.read_csv(file_path)
                        dfs.append(df)

                normal_df = create_combined_df(dfs, 'load_0', user, scenario, time_window)
                train_LSTM_AD_model(normal_df, user, scenario, time_window)
                train_pycaret_AD_models(normal_df, user, scenario, time_window)
            
def train_pycaret_AD_models(train_df, user, scenario, time_window):
    models_dir = create_dir_if_not_exists(
            os.path.join(AD_FOLDER, "anomaly_detection_models")
        )

    train_df.replace(0, np.nan, inplace=True)
    train_df["time"] = pd.to_datetime(train_df["time"], unit="s")
    
    # For each type of AD model to be used, create and train a model instance on the normal data
    for model in AD_MODELS:
        for column in train_df.columns:
            if "time" in column or "_energy" not in column:
                continue 
            print("Training anomaly detection models on normal data...")
            print(f"Training {model} model for {user}-{scenario} factors...")
            
            # Train model on Time & Energy dataframe
            col_data = train_df.loc[:, ["time", column]]
            setup(col_data, session_id = 123)
            
            # Train the model
            trained_model = create_model(model)
            
            resource_dir = create_dir_if_not_exists(
                os.path.join(models_dir, SYSTEM, time_window, f'{user}_{scenario}_{column}')
            )
            # Save the model
            save_model(
                trained_model,
                f"{resource_dir}/{model}_pipeline",
            )
    
    
    


