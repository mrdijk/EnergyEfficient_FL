import os
import pandas as pd
import argparse
import utils
import constants

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
    parser.add_argument("archetype", type=str, choices=["ComputeToData", "DataThroughTTP", "all"], 
                        help="Archetype to calculate means from.")
    args = parser.parse_args()

    # If all is selected, use all archetypes
    archetypes = constants.ARCHETYPES if args.archetype == "all" else [args.archetype]

    # Load the data for each prefix and archetype (do archetype as the parent loop 
    # to ensure implementations are shown next to each other)
    for archetype in archetypes:
        for prefix in constants.IMPLEMENTATIONS_PREFIXES:
            # Load the data (will load all experiments folders and its data with the prefix)
            df, exp_dirs = utils.load_experiment_results(prefix, archetype)
            # If data is not empty, calculate the mean values
            if not df.empty:
                # Calculate results
                total_repetitions = len(df)
                means = calculate_means(df)
                energy_per_task = means["total_energy_difference"] / constants.NUM_EXP_ACTIONS
                # Print results for this archetype and implementation
                print("\n***************************************************************************")
                print(f"Implementation: {prefix}\nArchetype: {archetype}")
                print(f"    Total number of experiment repetitions used: {total_repetitions}")
                print(f"    Energy per task: {energy_per_task}")
                print("     Means for specified columns:")
                print(means)
                print("\n***************************************************************************")
            else:
                print(f"No data loaded for prefix: {prefix} and archetype: {archetype}")