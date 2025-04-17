import os
import time
import pandas as pd
from datetime import datetime


def get_time_range(minutes_before=30) -> float:
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
    Function to save energy data to a file.
    """
    output_dir = 'data'

    # Ensure the output directory exists
    os.makedirs(output_dir, exist_ok=True)

    # Save to a file in the specified directory
    output_file = os.path.join(output_dir, f'{filename}.csv')

    # Write the data to the output file
    df.to_csv(output_file, index=False)

    # Output file location that is clickable for the user
    print(f'Saved data to {os.path.join(os.getcwd(), output_file)}')


def convert_float_time_to_string(float_time: float, format: str = "%Y-%m-%d %H:%M:%S") -> str:
    """
    Convert a float timestamp to a readable format string.

    Args:
        float_time (float): The float timestamp to convert.
        format (str): The format string for the output. Default is "%Y-%m-%d %H:%M:%S".

    Returns:
        str: The formatted time string.
    """
    # Convert float time to a datetime object
    dt_object = datetime.fromtimestamp(float_time)
    # Format the datetime object to a string
    readable_time_string = dt_object.strftime(format)
    return readable_time_string
