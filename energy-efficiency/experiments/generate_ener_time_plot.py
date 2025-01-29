import pandas as pd
import matplotlib.pyplot as plt
import argparse
import utils
import os
import constants

def generate_scatter_plot(data_dict, archetype: str, figsize, use_mean: bool):
    # Set columns to use
    columns_to_use = ['total_energy_difference', 'average_exec_time']
    # Create the figure
    plt.figure(figsize=figsize)

    # Plot each label and df
    for label, df in data_dict.items():
        # If use mean is selected, plot mean values
        if use_mean:
            mean_values = df[columns_to_use].mean()
            plt.scatter(mean_values['average_exec_time'], mean_values['total_energy_difference'], label=label)
        # Otherwise, plot all values
        else:
            plt.scatter(df['average_exec_time'], df['total_energy_difference'], label=label)

    xlabel = "Mean Execution Time (s)" if use_mean else "Execution Time (s)"
    plt.xlabel(xlabel)
    plt.ylabel("Energy Consumption (J)")
    plt.legend()
    fig_name = f'scatter_plot_{archetype}_mean.png' if use_mean else f'scatter_plot_{archetype}.png'
    plt.savefig(fig_name)
    plt.close()
    # Output file location that is clickable for the user
    print(f"Scatter plot saved to {os.path.join(os.getcwd(), fig_name)}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate scatter plot for energy efficiency experiment data")
    parser.add_argument("archetype", type=str, choices=["ComputeToData", "DataThroughTTP", "all"], 
                        help="Archetype to generate scatter plot from.")
    parser.add_argument("--mean", action="store_true", help="Use mean values for the scatter plot")
    args = parser.parse_args()

    data_dict = {}

    # If all is selected, use all archetypes and set different figsize
    archetypes = constants.ARCHETYPES if args.archetype == "all" else [args.archetype]
    figsize = (8, 6)    

    # Load the data for each prefix and archetype (do prefix as the parent loop 
    # to ensure implementations are shown next to each other)
    for prefix in constants.IMPLEMENTATIONS_PREFIXES:
        for archetype in archetypes:
            # Load the data (will load all experiments folders and its data with the prefix)
            df, exp_dirs = utils.load_experiment_results(prefix, archetype)
            if not df.empty:
                data_dict[f"{prefix}_{constants.ARCHETYPE_ACRONYMS[archetype]}"] = df
            else:
                print(f"No data loaded for prefix: {prefix} and archetype: {archetype}")

    if not data_dict:
        print("No data loaded for any prefix. Exiting.")
    else:
        # Logging purposes
        # print(f"Data dict used for scatter plot: {data_dict}")
        # Generate scatter plot
        generate_scatter_plot(data_dict, args.archetype, figsize, args.mean)