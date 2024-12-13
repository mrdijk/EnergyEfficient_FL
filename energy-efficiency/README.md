# Energy Efficiency in DYNAMOS
Project for Collin Poetoehena's Master thesis on energy efficiency in DYNAMOS.

Follow the getting started guide to get DYNAMOS up and running, including the Prometheus setup for gathering energy consumption metrics.

This project contains of two parts:
1. **Data collection**: see data-collection folder.
2. **Data analysis**: see data-analysis folder.

## Getting Started
- [Getting Started with DYNAMOS](docs/getting-started/0_Getting-Started.md)


# Running the energy efficiency pipeline
## Prerequisites
Install dependencies:
```sh
# Ensure usage of Python 3.10
sudo apt install python3.10
# Verify installation:
python3.10 --version
# Install pip 
sudo apt install python3-pip
# Verify installation:
pip --version

# Navigate to the energy-efficiency folder
cd energy-efficiency
# Install requirements using pip
pip install -r requirements.txt
```

## Running data collection
Navigate to the energy-efficiency/data-collection folder and run the main python file:
```sh
# Navigate to energy-efficiency/data-collection folder
cd energy-efficiency/data-collection
# Run specific scripts (assuming Python is installed in WSL environment and the command is run in a WSL terminal)
python3.10 get_metrics.py
```
Running the scripts from this location is crucial, since the imports are assuming the scripts are run from this location.


## Running data analysis (AD and RCA)
Navigate to the energy-efficiency/data-analysis folder and run the main python file:
```sh
# Navigate to energy-efficiency/data-analysis folder
cd energy-efficiency/data-analysis
# Run specific scripts (assuming Python is installed in WSL environment and the command is run in a WSL terminal)
python3.10 main.py
```
Running the scripts from this location is crucial, since the imports are assuming the scripts are run from this location.