import os
import pandas as pd
import numpy as np
from pycaret.anomaly import *
# Import BIRCH libraries (sklearn comes from "pip install scikit-learn")
from sklearn.cluster import Birch
from sklearn import preprocessing
from scipy.spatial import distance
import argparse

# Path to the folder containing the experiment results
DATA_FOLDER = os.path.abspath(os.path.join(os.path.dirname(__file__), 'data'))
EXP_FILENAME = 'full_experiment_results.csv'

# Load all full_experiment_results.csv files into a single DataFrame
def load_experiment_results(prefix: str, archetype: str):
    print(f"Using data folder: {DATA_FOLDER}")
    # Set the prefix for all experiment folders
    prefix = f"{prefix}_{archetype}"
    print(f"Using prefix: {prefix}")
    # Get the directories in the data folder
    data_folder_exp_dirs = []
    for dir in os.listdir(DATA_FOLDER):
        if os.path.isdir(os.path.join(DATA_FOLDER, dir)) and prefix in dir:
            data_folder_exp_dirs.append(dir)

    # Get all files by going over each experiment folder
    all_files = []
    exp_dirs = []
    for exp_dir in data_folder_exp_dirs:
        # Get the experiment directory path
        exp_dir_path = os.path.join(DATA_FOLDER, exp_dir)
        print(f"Exp dir path: {exp_dir_path}")
        # Experiment repetitions
        exp_rep_dirs = os.listdir(exp_dir_path)
        print(f"Exp rep dirs: {exp_rep_dirs}")
        # Get the file paths
        for exp_rep_dir in exp_rep_dirs:
            file_path = os.path.join(exp_dir_path, exp_rep_dir, EXP_FILENAME)
            if os.path.isfile(file_path):
                all_files.append(file_path)
                exp_dirs.append((exp_dir_path, exp_rep_dir))
            else:
                print(f"File not found: {file_path}")

    # print(f"All files: {all_files}")
    if not all_files:
        print("No files found. Please check the directory structure and file names.")
        return pd.DataFrame(), []  # Return an empty DataFrame and empty list if no files are found

    df_list = [pd.read_csv(file) for file in all_files]
    return pd.concat(df_list, ignore_index=True), exp_dirs

def run_BIRCH_AD_with_smoothing(df: pd.DataFrame, column) -> bool:
    # Define anomaly detection threshold for BIRCH clustering
    ad_threshold = 0.045
    # Define window size for smoothing the data
    smoothing_window = 12
    # Extract the specific column for analysis
    test_df = df.loc[:, [column]]

    # Apply a rolling mean to smooth the column data (energy data e.g. CPU, memory, energy, etc.)
    column_data = test_df[column].rolling(window=smoothing_window, min_periods=1).mean()

    # Convert the smoothed series to a NumPy array
    x = np.array(column_data)
    # Replace NaN values with 0 to ensure no missing data is passed to the algorithm
    x = np.where(np.isnan(x), 0, x)
    # Normalize the data to ensure all values are on a similar scale
    normalized_x = preprocessing.normalize([x])
    # Reshape the normalized data to a 2D array as required by BIRCH
    X = normalized_x.reshape(-1, 1)

    # Initialize the BIRCH model with the specified parameters
    birch = Birch(branching_factor=50, n_clusters=None, threshold=ad_threshold, compute_labels=True)

    # Build the CF tree for the input data (i.e. perform clustering)
    birch.fit(X)
    # Use the fitted model to predict the cluster labels for the data
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

    # Check if there are any anomalies
    return test_df['anomaly_label'].sum() > 0

def execute_BIRCH_AD_algorithm(df: pd.DataFrame, exp_dirs: list):
    print("Start executing BIRCH AD algorithm...")
    anomalies = {}

    # Specify the column to check for anomalies
    column_to_check = 'total_energy_difference'

    # Run BIRCH algorithm and check for anomalies
    if run_BIRCH_AD_with_smoothing(df, column_to_check):
        for exp_dir_path, exp_rep_dir in exp_dirs:
            if exp_dir_path not in anomalies:
                anomalies[exp_dir_path] = []
            anomalies[exp_dir_path].append((exp_rep_dir, column_to_check))

    # Report the experiment folders that contain anomalies
    if anomalies:
        print("Anomalies detected in the following experiment folders:")
        for exp_dir_path, exp_rep_dirs in anomalies.items():
            for exp_rep_dir, column in exp_rep_dirs:
                print(f"{exp_dir_path}/{exp_rep_dir}: {column}")
    else:
        print("No anomalies detected.")

if __name__ == "__main__":
    # Add argument parser
    parser = argparse.ArgumentParser(description="Run energy efficiency experiment")
    parser.add_argument("archetype", type=str, choices=["ComputeToData", "DataThroughTTP"], 
                        help="The archetype to detect the anomalies from (must be 'ComputeToData' or 'DataThroughTTP')")
    parser.add_argument("prefix", type=str, help="The prefix of the experiment folders")
    # Parse args
    args = parser.parse_args()

    # Load the data
    df, exp_dirs = load_experiment_results(args.prefix, args.archetype)

    if df.empty:
        print("No data loaded. Exiting.")
    else:
        # Execute BIRCH AD algorithm
        execute_BIRCH_AD_algorithm(df, exp_dirs)