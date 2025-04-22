import pandas as pd
from sklearn.cluster import DBSCAN
import argparse
import utils
import os
import shutil

def execute_DBSCAN_AD_algorithm(df: pd.DataFrame, exp_dirs, anomaly_folders):
    # Detect anomalies using DBSCAN
    column_to_use = 'total_energy_difference'
    X = df[[column_to_use]].values

    # DBSCAN parameters, increase eps to detect fewer anomalies
    # TODO: when using this first try to play around with these values to somewhat manually control
    # which are anomalies, mainly use eps. The current threshold is used for earlier anomaly detection and could be good already.
    dbscan = DBSCAN(eps=70, min_samples=3)
    labels = dbscan.fit_predict(X)

    # Anomalies are labeled as -1
    anomalies = df[labels == -1]
    anomaly_indices = anomalies.index.tolist()

    # Print anomalies
    print(f"Anomalies detected ({len(anomaly_indices)} anomalies):")
    for idx in anomaly_indices:
        exp_dir_path, exp_rep_dir = exp_dirs[idx]
        file_path = os.path.join(exp_dir_path, exp_rep_dir, utils.EXP_FILENAME)
        print(f"File: {file_path}")
        print(anomalies.loc[idx])
        anomaly_folders.add(os.path.join(exp_dir_path, exp_rep_dir))

def check_runs_results(exp_dirs, anomaly_folders):
    # Check runs_results.csv for status codes not equal to 200
    for exp_dir_path, exp_rep_dir in exp_dirs:
        file_path = os.path.join(exp_dir_path, exp_rep_dir, 'runs_results.csv')
        if os.path.isfile(file_path):
            runs_df = pd.read_csv(file_path)
            anomalies = runs_df[(runs_df['appr_status_code'] != 200) | (runs_df['data_status_code'] != 200)]
            if not anomalies.empty:
                print(f"Anomalies in {file_path}:")
                print(anomalies)
                anomaly_folders.add(os.path.join(exp_dir_path, exp_rep_dir))
        else:
            print(f"File not found: {file_path}")

def remove_anomaly_folders(anomaly_folders):
    # Remove experiment folders found to be anomalies
    for folder in anomaly_folders:
        if os.path.exists(folder):
            shutil.rmtree(folder)
            print(f"Removed folder: {folder}")
        else:
            print(f"Folder not found: {folder}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run energy efficiency experiment")
    parser.add_argument("archetype", type=str, choices=["ComputeToData", "DataThroughTTP"], 
                        help="Archetype to detect anomalies from.")
    parser.add_argument("prefix", type=str, choices=["baseline", "caching", "compression"], help="Prefix of the experiment folders")
    parser.add_argument("--remove", action="store_true", help="Remove anomaly folders")
    parser.add_argument("--data_type", type=str, choices=["normal", "fabric"], default="normal", 
                        help="Data type to use, i.e., the data folder to use for this analysis. Defaults to 'normal'.")
    args = parser.parse_args()

    # Load the data (will load all experiments folders and its data with the prefix)
    df, exp_dirs = utils.load_experiment_results(args.prefix, args.archetype, args.data_type)

    if df.empty:
        print("No data loaded. Exiting.")
    else:
        anomaly_folders = set()

        # Check runs_results.csv for status codes not equal to 200
        # Do this before checking for anomaly result values since these have more priority
        check_runs_results(exp_dirs, anomaly_folders)

        # Print empty line between functions
        print("")

        # Call DBSCAN function to detect anomalies
        execute_DBSCAN_AD_algorithm(df, exp_dirs, anomaly_folders)

        # Print combined list of folders containing anomalies
        print(f"\nFolders containing anomalies: ({len(anomaly_folders)} total anomalies)")
        for folder in anomaly_folders:
            print(folder)

        # Remove anomaly folders if the argument is set to True
        if args.remove:
            remove_anomaly_folders(anomaly_folders)