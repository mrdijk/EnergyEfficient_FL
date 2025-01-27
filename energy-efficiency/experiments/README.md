# Energy Experiments
This folder contains relevant files related to the execution of experiments.

## Running experiments
### Prerequisites
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

# Navigate to the experiments folder
cd energy-efficiency/experiments
# Install requirements using pip
pip install -r requirements.txt
```

### Executing experiments
```sh
# Make sure Prometheus is port-forwarded (required for querying Prometheus for energy data), such as:
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090
# Access it at http://localhost:9090/

# Navigate to the experiments folder
cd energy-efficiency/experiments
# Run specific scripts (assuming Python is installed in WSL environment and the command is run in a WSL terminal)
python3.10 execute_experiments.py <archetypes> <exp_reps> <exp_name>
# For example for both archetypes:
python3.10 execute_experiments.py "ComputeToData" "DataThroughTTP" 30 "baseline"
# Or only one archetype and a different name
python3.10 execute_experiments.py "DataThroughTTP" 30 "caching"
```
Running the scripts from this location is crucial, since the imports are assuming the scripts are run from this location.


### Executing anomaly detection
```sh
python3.10 detect_anomalies.py "ComputeToData" "baseline"
# Or with a different prefix or archetype:
python3.10 detect_anomalies.py "DataThroughTTP" "caching"
```


### Executing mean calculation
```sh
python3.10 calculate_mean.py "ComputeToData" "baseline"
# Or with a different prefix or archetype:
python3.10 calculate_mean.py "DataThroughTTP" "caching"

# If you want to remove anomalies, add the --remove flag (BE CAREFUL: this will remove the experiment folders)
```