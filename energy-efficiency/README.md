# Energy Efficiency in DYNAMOS
Project for Collin Poetoehena's Master thesis on energy efficiency in DYNAMOS.

Follow the getting started guide to get DYNAMOS up and running, including the Prometheus setup for gathering energy consumption metrics.

This project contains of two parts:
1. **Data collection**: see data-collection folder.
2. **Data analysis**: see data-analysis folder.

## Getting Started
- [Getting Started with DYNAMOS](docs/getting-started/0_Getting-Started.md)


# Running data collection
Navigate to the energy-efficiency/data-collection folder and run the main python file:
```sh
# Navigate to the energy-efficiency folder
cd energy-efficiency
# Install requirements using pip (only needs to be done once)
pip install -r requirements.txt

# Navigate to energy-efficiency/data-collection folder
cd data-collection
# Run specific scripts
python get_metrics.py
```
Running the scripts from this location is crucial, since the imports are assuming the scripts are run from this location.


# Running data analysis
Navigate to the energy-efficiency/data-analysis folder and run the main python file:
```sh
# Navigate to the energy-efficiency folder
cd energy-efficiency
# Install requirements using pip (only needs to be done once)
pip install -r requirements.txt

# Navigate to energy-efficiency/data-collection folder
cd data-collection
# Run specific scripts
python main.py
```
Running the scripts from this location is crucial, since the imports are assuming the scripts are run from this location.