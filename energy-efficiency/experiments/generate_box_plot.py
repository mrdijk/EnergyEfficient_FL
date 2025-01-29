import pandas as pd
import matplotlib.pyplot as plt
import argparse
import utils
import os
import constants

def generate_box_plot(data_dict, archetype: str, figsize):
    # Get the energy values from the df
    data = [df["total_energy_difference"].values for df in data_dict.values()]
    labels = list(data_dict.keys())

    # Generate box plot for the column
    plt.figure(figsize=figsize)
    plt.boxplot(data, labels=labels)
    # No title is set now, since it is added in thesis directly
    # plt.title(f'Box Plot for {column}')
    # Change labels accordingly
    plt.ylabel("Energy consumption (J)")
    plt.xlabel("Implementation and Archetype acronym")
    fig_name = f'boxplot_{archetype}_energy.png'
    plt.savefig(fig_name)
    plt.close()
    # Output file location that is clickable for the user
    print(f"Box plot saved to {os.path.join(os.getcwd(), fig_name)}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate box plot for energy efficiency experiment data")
    parser.add_argument("archetype", type=str, choices=["ComputeToData", "DataThroughTTP", "all"], 
                        help="Archetype to generate box plot from.")
    args = parser.parse_args()

    data_dict = {}

    # If all is selected, use all archetypes and set different figsize
    archetypes = constants.ARCHETYPES if args.archetype == "all" else [args.archetype]
    figsize = (10, 6) if args.archetype == "all" else (6, 6)    

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
        # print(f"Data dict used for box plot: {data_dict}")
        # Generate box plot
        generate_box_plot(data_dict, args.archetype, figsize)