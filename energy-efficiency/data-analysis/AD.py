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

    # Training not required for BIRCH here, it is done in the BIRCH function itself

    # Create the Ground Truth
    create_ground_truth()

    # Execute BIRCH AD algorithm
    execute_BIRCH()


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


def run_BIRCH_AD_with_smoothing(temp_df: pd.DataFrame, df: pd.DataFrame, column):
    """
    Main function of the anomaly detection. 
    """
    # Define anomaly detection threshold for BIRCH clustering
    ad_threshold = 0.045
    # Define window size for smoothing the data
    smoothing_window = 12
    # Extract the time and the specific column for analysis
    test_df = df.loc[:, ["time", column]]

    # Iterate over each column in the test dataframe
    for svc, energy in test_df.items():
        # Skip the 'time' column since it's not relevant for clustering
        if svc != 'time':
            # Apply a rolling mean to smooth the energy data
            energy = energy.rolling(window=smoothing_window, min_periods=1).mean()

            # Convert the smoothed series to a NumPy array
            x = np.array(energy)
            # Replace NaN values with 0 to ensure no missing data is passed to the algorithm
            x = np.where(np.isnan(x), 0, x)
            # Normalize the data to ensure all values are on a similar scale
            normalized_x = preprocessing.normalize([x])
            # Reshape the normalized data to a 2D array as required by BIRCH
            X = normalized_x.reshape(-1, 1)

            # Initialize the BIRCH model with the specified parameters
            birch = Birch(branching_factor=50, n_clusters=None, threshold=ad_threshold, compute_labels=True)
            
            # Train the BIRCH model on the reshaped data
            birch.fit(X)
            # Use the trained model to predict the cluster labels for the data
            birch.predict(X)

            # Calculate the Euclidean distances (straight-line distance between two points in a plane or space) 
            # from each data point to all cluster centers. `X` contains the data points, and `birch.subcluster_centers_` 
            # contains the centers of the subclusters identified by BIRCH. `distance.cdist` computes the distance between 
            # each data point and each cluster center.
            distances = distance.cdist(X, birch.subcluster_centers_)
            # For each data point, find the minimum distance to any of the cluster centers.
            # This minimum distance represents how close the point is to the nearest cluster center.
            # A smaller distance indicates that the point is well represented by the cluster, while a 
            # larger distance might suggest that the point is an outlier or anomaly.
            min_distances = np.min(distances, axis=1)

            # Set a threshold to identify anomalies based on the distribution of minimum distances.
            # Here, the 95th percentile is chosen, meaning that points with a distance greater than 95% 
            # of all points are considered anomalies. This is based on the assumption that most data points 
            # should be near a cluster center, and only a few should be far away.
            threshold = np.percentile(min_distances, 95)

            # Label data points as anomalies (1) if their distance exceeds the threshold, else normal (0)
            test_df['anomaly_label'] = np.where(min_distances > threshold, 1, 0)
            
            # Update the original dataframe with the anomaly labels and scores
            temp_df = temp_df.assign(
                **{
                    # Anomaly labels (0 or 1)
                    f"{column}_Anomaly": test_df['anomaly_label'],
                    # Anomaly scores (distances)
                    f"{column}_Anomaly_Score": min_distances,
                }
            )
    
    # Return the updated dataframe with the anomaly information
    return temp_df



