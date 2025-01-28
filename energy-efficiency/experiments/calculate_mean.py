import os
import pandas as pd
import argparse
import utils

# Calculate the mean for specified columns
def calculate_means(df: pd.DataFrame):
    # Use all data values from the full energy measurement results
    columns_to_calculate = [
        'idle_energy_total',
        'active_energy_total',
        'total_energy_difference',
        'average_exec_time'
    ]
    # Calculate the mean values
    means = df[columns_to_calculate].mean()
    return means

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run energy efficiency experiment")
    parser.add_argument("archetype", type=str, choices=["ComputeToData", "DataThroughTTP"], 
                        help="Archetype to detect anomalies from.")
    parser.add_argument("prefix", type=str, choices=["baseline", "caching", "compression"], help="Prefix of the experiment folders")
    args = parser.parse_args()

    # Load the data (will load all experiments folders and its data with the prefix)
    df, exp_dirs = utils.load_experiment_results(args.prefix, args.archetype)

    # TODO: calculate average and STD.

    if df.empty:
        print("No data loaded. Exiting.")
    else:
        # Print results
        total_runs = len(df)
        means = calculate_means(df)
        print(f"Total number of runs used: {total_runs}")
        print("Means for specified columns:")
        print(means)