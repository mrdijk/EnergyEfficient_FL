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


## FABRIC addition
You can run exactly the same steps above if you create an SSH tunnel for Prometheus on localhost:9090. This way, you can use the same constants.py values for Prometheus, since it is then tunneled to localhost:9090 from this local machine, which means you can still get the data from this machine. See fabric/dynamos/DYNAMOS_setup.ipynb notebook for how to set up an SSH tunnel for Prometheus on your local machine in detail. In short:
```sh
# Get Prometheus service NodePort 
kubectl get svc prometheus-kube-prometheus-prometheus -n monitoring
# Create SSH tunnel from the location you connect to the FABRIC nodes with SSH in a terminal, such as (of course change NodePort after localhost: and IP of ubuntu node):
ssh -i ~/.ssh/slice_key -F ssh_config -L 9090:localhost:32471 ubuntu@2001:610:2d0:fabc:f816:3eff:fe1f:b201
# See for more information the above specified notebook
```
Then with the SSH tunnel open, execute the above steps like you would locally.

However, if you want to collect the data in the FABRIC Jupyter Hub environment, you can also follow the steps in the fabric/experiments/energy_efficiency_pipeline.ipynb notebook. Note: this is more complex and more steps than the above approach, so the above one is recommended and preferred.