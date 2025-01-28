import pandas as pd
import matplotlib.pyplot as plt
import argparse
import utils

def generate_box_plot(df: pd.DataFrame, column: str):
    data = df[column].values
    print(f"Data: {data}")

    # Generate box plot for the column
    plt.figure(figsize=(10, 6))
    plt.boxplot(data, vert=False)
    plt.title(f'Box Plot for {column}')
    plt.xlabel('Values')
    plt.savefig(f'boxplot_{column}.png')
    plt.close()
    print(f"Box plot saved as boxplot_{column}.png")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate box plot for energy efficiency experiment data")
    parser.add_argument("archetype", type=str, choices=["ComputeToData", "DataThroughTTP"], 
                        help="Archetype to generate box plot from.")
    parser.add_argument("prefix", type=str, choices=["baseline", "caching", "compression"], help="Prefix of the experiment folders")
    parser.add_argument("column", type=str, help="Column to generate box plot for")
    args = parser.parse_args()

    # Load the data
    df, exp_dirs = utils.load_experiment_results(args.prefix, args.archetype)

    if df.empty:
        print("No data loaded. Exiting.")
    else:
        # Generate box plot
        generate_box_plot(df, args.column)