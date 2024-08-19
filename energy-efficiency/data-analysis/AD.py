from datetime import datetime
import os
import shutil
from typing import List, Union
from pycaret.anomaly import *
import numpy as np
import pandas as pd
# Import BIRCH libraries (sklearn comes from "pip install scikit-learn")
from sklearn.cluster import Birch
from sklearn import preprocessing
from scipy.spatial import distance

def main():
    """
    Main function of the anomaly detection. 
    """
    power_to_energy_and_cpu_to_percentage()

    perform_time_analysis()                             

    # Create model training dataset from the normal experiment folder
    combine_normal_operations_and_train_AD_models() 

    # Create the Ground Truth
    create_ground_truth()

    # Execute BIRCH AD algorithm
    execute_BIRCH()


def power_to_energy_and_cpu_to_percentage() -> None:
    print("Converting power metrics to energy metrics...")

    for service in os.listdir(DATA_FOLDER):
        service_path = os.path.join(DATA_FOLDER, service)
        if not os.path.isdir(service_path):
            continue

        if service == "normal":            
            user_factors = [folder for folder in os.listdir(service_path) if os.path.isdir(os.path.join(service_path, folder))]
            for user in user_factors:            
                scenario_factors = [folder for folder in os.listdir(os.path.join(service_path, user)) if os.path.isdir(os.path.join(service_path, user, folder))]
                for scenario in scenario_factors:
                    scenario_path = os.path.join(service_path, user, scenario)
                    for file in os.listdir(scenario_path):
                        if file.endswith(".csv"):
                            convert_to_energy_and_cpu_percentage(
                                os.path.join(scenario_path, file), scenario_path, file, service
                            )
        else:          
            stress_factors = [folder for folder in os.listdir(service_path) if os.path.isdir(os.path.join(service_path, folder))]
            for stress in stress_factors:            
                user_factors = [folder for folder in os.listdir(os.path.join(service_path, stress)) if os.path.isdir(os.path.join(service_path, stress, folder))]
                for user in user_factors:            
                    scenario_factors = [folder for folder in os.listdir(os.path.join(service_path, stress, user)) if os.path.isdir(os.path.join(service_path, stress, user, folder))]
                    for scenario in scenario_factors:     
                        scenario_path = os.path.join(service_path, stress, user, scenario)
                        for file in os.listdir(scenario_path):
                            if file.endswith(".csv"):
                                convert_to_energy_and_cpu_percentage(
                                    os.path.join(scenario_path, file), scenario_path, file, service
                                )