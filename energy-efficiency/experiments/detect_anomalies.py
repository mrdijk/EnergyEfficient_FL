import pandas as pd
from sklearn.cluster import DBSCAN
import argparse
import utils
import os

# Detect anomalies using DBSCAN
def execute_DBSCAN_AD_algorithm(df: pd.DataFrame, exp_dirs):
    column_to_use = 'total_energy_difference'
    X = df[[column_to_use]].values

    # DBSCAN parameters, increase eps to detect fewer anomalies
    # TODO: play around with the eps value, starting with a low one and then gradually making it higher
    # so you can see anomalies and manually decide to remove them, such as based on the calculated mean
    dbscan = DBSCAN(eps=47, min_samples=3)
    labels = dbscan.fit_predict(X)

    # Anomalies are labeled as -1
    anomalies = df[labels == -1]
    anomaly_indices = anomalies.index.tolist()

    print("Anomalies detected:")
    for idx in anomaly_indices:
        exp_dir_path, exp_rep_dir = exp_dirs[idx]
        file_path = os.path.join(exp_dir_path, exp_rep_dir, utils.EXP_FILENAME)
        print(f"File: {file_path}")
        print(anomalies.loc[idx])

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run energy efficiency experiment")
    parser.add_argument("archetype", type=str, choices=["ComputeToData", "DataThroughTTP"], 
                        help="Archetype to detect anomalies from.")
    parser.add_argument("prefix", type=str, help="Prefix of the experiment folders")
    args = parser.parse_args()

    # Load the data
    df, exp_dirs = utils.load_experiment_results(args.prefix, args.archetype)

    if df.empty:
        print("No data loaded. Exiting.")
    else:
        # Call your new DBSCAN-based function
        execute_DBSCAN_AD_algorithm(df, exp_dirs)

