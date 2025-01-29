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

def calculate_difference_percentage(val1, val2):
    """
    Calculate the percentage difference between two values.
    :param val1: Baseline mean value
    :param val2: Optimization mean value
    :return: Percentage difference
    """
    if val1 == 0:
        return 0  # Avoid division by zero
    return ((val1 - val2) / val1) * 100


def display_results(baseline_means_df: pd.DataFrame, means_df: pd.DataFrame, total_repetitions: int, prefix: str, archetype: str):
    # Helper function to display results
    # Calculate results
    energy_per_task = means_df["total_energy_difference"] / constants.NUM_EXP_ACTIONS
    # Print results for this archetype and implementation
    print("\n***************************************************************************")
    print(f"Implementation: {prefix}\nArchetype: {archetype}")
    print(f"    Total number of experiment repetitions used: {total_repetitions}")
    print(f"    Energy per task: {energy_per_task}")
    print("     Means for all columns:")
    print(means_df)
    # Show differences, with main first to show the difference with main
    print(f"    Mean energy difference with baseline: {calculate_difference_percentage(baseline_means_df['total_energy_difference'], means_df['total_energy_difference'])}%")
    print(f"    Mean exec time difference with baseline: {calculate_difference_percentage(baseline_means_df['average_exec_time'], means_df['average_exec_time'])}%")
    print("\n***************************************************************************")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run energy efficiency experiment")
    parser.add_argument("archetype", type=str, choices=["ComputeToData", "DataThroughTTP", "all"], 
                        help="Archetype to calculate means from.")
    args = parser.parse_args()

    # If all is selected, use all archetypes
    archetypes = constants.ARCHETYPES if args.archetype == "all" else [args.archetype]

    # Save means to display percentage differences later
    means_dict = {}
    repetitions_dict = {}

    # Load the data for each prefix and archetype (do archetype as the parent loop 
    # to ensure each implementation of the first archetype is shown first and then the second archetype)
    for archetype in archetypes:
        for prefix in constants.IMPLEMENTATIONS_PREFIXES:
            # Load the data (will load all experiments folders and its data with the prefix)
            df, exp_dirs = utils.load_experiment_results(prefix, archetype)
            # If data is not empty, calculate the mean values
            if not df.empty:
                # Calculate means
                total_repetitions = len(df)
                means = calculate_means(df)
                # Save the mean values and repetitions
                arch_impl_key = f"{constants.ARCHETYPE_ACRONYMS[archetype]}_{prefix}"
                means_dict[arch_impl_key] = means
                repetitions_dict[arch_impl_key] = total_repetitions
            else:
                print(f"No data loaded for prefix: {prefix} and archetype: {archetype}")
    
    # Logging purposes
    # print(f"Means dict: {means_dict}")

    # Display results for each implementation
    if len(means_dict) > 0:
        # For each archetype and implementation, print the results
        # (will also print baseline, but this can be used as verification, should be 0% difference)
        for archetype in archetypes:
            for prefix in constants.IMPLEMENTATIONS_PREFIXES:
                # Use baseline df of this archetype and the df of this implementation
                baseline_df = means_dict[f"{constants.ARCHETYPE_ACRONYMS[archetype]}_baseline"]
                impl_key = f"{constants.ARCHETYPE_ACRONYMS[archetype]}_{prefix}"
                impl_df = means_dict[impl_key]
                impl_repetitions = repetitions_dict[impl_key]
                # Logging purposes
                # print(f"Baseline df: {baseline_df}")
                # print(f"Impl df: {impl_df}")
                # Display results
                display_results(baseline_df, impl_df, impl_repetitions, prefix, archetype)