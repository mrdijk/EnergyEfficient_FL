import os
import pandas as pd
import constants

# Path to the folder containing the experiment results
DATA_FOLDER = os.path.abspath(os.path.join(os.path.dirname(__file__), 'data'))
EXP_FILENAME = 'full_experiment_results.csv'

# Load all full_experiment_results.csv files into a single DataFrame
def load_experiment_results(prefix: str, archetype: str, data_type: str = constants.DATA_TYPE_NORMAL):
    """
    Load experiment results from a specific data folder based on the data type.

    :param prefix: Prefix for experiment folders
    :param archetype: Archetype for filtering folders
    :param data_type: Type of data folder to use (e.g., constants.DATA_TYPE_NORMAL or constants.DATA_TYPE_FABRIC). Default constants.DATA_TYPE_NORMAL
    :return: A tuple containing a concatenated DataFrame and a list of experiment directories
    """
    # Determine the data folder based on the data type
    if data_type not in constants.DATA_TYPE_FOLDERS:
        raise ValueError(f"Invalid data type: {data_type}. Must be one of {list(constants.DATA_TYPE_FOLDERS.keys())}.")
    
    data_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), constants.DATA_TYPE_FOLDERS[data_type]))
    print(f"Using data folder: {data_folder}")

    # Set the prefix for all experiment folders
    prefix = f"{prefix}_{archetype}"
    print(f"Using prefix: {prefix}")

    # Get the directories in the data folder
    data_folder_exp_dirs = []
    for dir in os.listdir(data_folder):
        if os.path.isdir(os.path.join(data_folder, dir)) and prefix in dir:
            data_folder_exp_dirs.append(dir)

    # Get all files by going over each experiment folder
    all_files = []
    exp_dirs = []
    for exp_dir in data_folder_exp_dirs:
        # Get the experiment directory path
        exp_dir_path = os.path.join(data_folder, exp_dir)
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


def interpret_guilford_scale(correlation: float) -> str:
    """
    Interpret a correlation value using the standard Guilford scale.
    Handles both positive and negative correlations symmetrically.

    :param correlation: Correlation coefficient (range: -1.0 to 1.0)
    :return: Interpretation string (e.g., "High positive correlation")
    """
    abs_corr = abs(correlation)

    if abs_corr < 0.2:
        strength = "Slight"
    elif abs_corr < 0.4:
        strength = "Low"
    elif abs_corr < 0.7:
        strength = "Moderate"
    elif abs_corr < 0.9:
        strength = "High"
    else:
        strength = "Very high"

    direction = "positive" if correlation > 0 else "negative" if correlation < 0 else "neutral"
    return f"{strength} {direction} correlation"
