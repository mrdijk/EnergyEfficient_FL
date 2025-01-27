import os
import pandas as pd

# Path to the folder containing the experiment results
DATA_FOLDER = os.path.abspath(os.path.join(os.path.dirname(__file__), 'data'))
EXP_FILENAME = 'full_experiment_results.csv'

# Load all full_experiment_results.csv files into a single DataFrame
def load_experiment_results(prefix: str, archetype: str):
    # print(f"Using data folder: {DATA_FOLDER}")
    # Set the prefix for all experiment folders
    prefix = f"{prefix}_{archetype}"
    # print(f"Using prefix: {prefix}")
    # Get the directories in the data folder
    data_folder_exp_dirs = []
    for dir in os.listdir(DATA_FOLDER):
        if os.path.isdir(os.path.join(DATA_FOLDER, dir)) and prefix in dir:
            data_folder_exp_dirs.append(dir)

    # Get all files by going over each experiment folder
    all_files = []
    exp_dirs = []
    for exp_dir in data_folder_exp_dirs:
        # Get the experiment directory path
        exp_dir_path = os.path.join(DATA_FOLDER, exp_dir)
        # print(f"Exp dir path: {exp_dir_path}")
        # Experiment repetitions
        exp_rep_dirs = os.listdir(exp_dir_path)
        # print(f"Exp rep dirs: {exp_rep_dirs}")
        # Get the file paths
        for exp_rep_dir in exp_rep_dirs:
            file_path = os.path.join(exp_dir_path, exp_rep_dir, EXP_FILENAME)
            if os.path.isfile(file_path):
                all_files.append(file_path)
                exp_dirs.append((exp_dir_path, exp_rep_dir))
            else:
                print(f"File not found: {file_path}")

    # print(f"All files: {all_files}")
    if not all_files:
        print("No files found. Please check the directory structure and file names.")
        return pd.DataFrame(), []  # Return an empty DataFrame and empty list if no files are found

    df_list = [pd.read_csv(file) for file in all_files]
    return pd.concat(df_list, ignore_index=True), exp_dirs