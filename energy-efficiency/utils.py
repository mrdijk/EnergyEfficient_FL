import os
import time
import pandas as pd

def get_time_range(minutes_before=30):
    """
    Returns the current time and the time 'minutes_before' minutes ago.

    :param minutes_before: The number of minutes before the current time to calculate.
    :return: Tuple of (start_time, end_time) in seconds since the epoch.
    """
    # Get the current time
    end_time = time.time()
    # Calculate the start time (minutes_before minutes before the current time)
    start_time = end_time - (minutes_before * 60)

    return start_time, end_time

def save_energy_data_to_file(df: pd.DataFrame, filename: str):
    """
    TODO: Add docstring. Function to save energy data to a file.
    """
    output_dir = 'data'

    # Ensure the output directory exists
    os.makedirs(output_dir, exist_ok=True)

    # Save to a file in the specified directory
    output_file = os.path.join(output_dir, f'{filename}.csv')

    # Write the data to the output file
    df.to_csv(output_file, index=False)

    print(f'Saved data to {output_file}')
