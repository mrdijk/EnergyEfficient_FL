import pandas as pd
import matplotlib.pyplot as plt
import argparse
import utils
import os

def generate_box_plot(data_dict, column: str, archetype: str, ylabel: str, xlabel: str):
    data = [df[column].values for df in data_dict.values()]
    labels = list(data_dict.keys())

    # Generate box plot for the column
    # Set the x and y sizes
    plt.figure(figsize=(6, 6))
    plt.boxplot(data, labels=labels)
    # No title is set now, since it is added in thesis directly
    # plt.title(f'Box Plot for {column}')
    # Change labels accordingly
    plt.ylabel(ylabel)
    plt.xlabel(xlabel)
    fig_name = f'boxplot_{archetype}_{column}.png'
    plt.savefig(fig_name)
    plt.close()
    # Output file location that is clickable for the user
    print(f"Box plot saved to {os.path.join(os.getcwd(), fig_name)}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate box plot for energy efficiency experiment data")
    parser.add_argument("archetype", type=str, choices=["ComputeToData", "DataThroughTTP"], 
                        help="Archetype to generate box plot from.")
    parser.add_argument("column", type=str, choices=["total_energy_difference", "average_exec_time"], help="Column to generate box plot for")
    args = parser.parse_args()

    # All prefixes, i.e. implementations
    prefixes = ["baseline", "caching", "compression"]
    data_dict = {}

    # Set the labels that will be used (default is energy)
    ylabel = "Energy consumption (J)"
    xlabel = "Implementation"
    # Change y label if execution time is used
    if args.column == "average_exec_time":
        ylabel = "Execution time (s)"

    # Load the data for each prefix
    for prefix in prefixes:
        df, exp_dirs = utils.load_experiment_results(prefix, args.archetype)
        if not df.empty:
            data_dict[prefix] = df
        else:
            print(f"No data loaded for prefix: {prefix}")

    if not data_dict:
        print("No data loaded for any prefix. Exiting.")
    else:
        # Logging purposes
        print(f"Data dict used for box plot: {data_dict}")
        # Generate box plot
        generate_box_plot(data_dict, args.column, args.archetype, ylabel, xlabel)