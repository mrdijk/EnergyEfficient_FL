import os
import pandas as pd
import argparse
import utils

# Calculate the mean for specified columns
def calculate_means(df: pd.DataFrame):
    columns_to_calculate = [
        'idle_energy_total',
        'active_energy_total',
        'total_energy_difference',
        'average_exec_time'
    ]
    means = df[columns_to_calculate].mean()
    return means

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
        means = calculate_means(df)
        print("Means for specified columns:")
        print(means)