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
python3.10 execute_experiments.py <data_steward> <exp-reps> <job-id-only-unique-id>
# For example:
python3.10 execute_experiments.py uva 15 10942c74
```
Running the scripts from this location is crucial, since the imports are assuming the scripts are run from this location.