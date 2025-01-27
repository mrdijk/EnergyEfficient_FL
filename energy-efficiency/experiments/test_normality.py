import pandas as pd
import os
import argparse
from scipy.stats import shapiro
import utils

def test_normality(df: pd.DataFrame, exp_dirs):
    # Perform Shapiro-Wilk normality test
    columns_to_test = ['total_energy_difference']
    not_normal = {col: 0 for col in columns_to_test}
    normal = {col: 0 for col in columns_to_test}

    # Test normality for each column
    for column in columns_to_test:
        data = df[column].values
        print(f"Data: {data}")
        # Ensure data used is at least 3 values
        if len(data) >= 3:
            stat, p = shapiro(data)
            # Use threshold to determine if the p-value is considered not normal distribution
            if p < 0.01:
                not_normal[column] += 1
                print(f"Not normal distribution for column: {column}")
            else:
                normal[column] += 1
            # Print stastic and p-value
            print(f"Statistic (Shapiro-Wilk test): {stat}, p-value: {p}")
        else:
            print(f"Not enough data points for normality test in column: {column}")

    # Print results
    for column in columns_to_test:
        print(f"Total not normal distributions for {column}: {not_normal[column]}")
        print(f"Total normal distributions for {column}: {normal[column]}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run normality test on energy efficiency experiment data")
    parser.add_argument("archetype", type=str, choices=["ComputeToData", "DataThroughTTP"], 
                        help="Archetype to test normality from.")
    parser.add_argument("prefix", type=str, choices=["baseline", "caching", "compression"], help="Prefix of the experiment folders")
    args = parser.parse_args()

    # Load the data
    df, exp_dirs = utils.load_experiment_results(args.prefix, args.archetype)

    if df.empty:
        print("No data loaded. Exiting.")
    else:
        # Perform normality test
        test_normality(df, exp_dirs)