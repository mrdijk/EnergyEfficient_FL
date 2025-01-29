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
# First try to see what the anomalies are and if you think it should be considered one or not. 
# Then play around a bit with the values if needed, see TODO in the file
# Then if you are satisfied with the reported anomalies, you can remove them:

# If you want to remove anomalies, add the --remove flag (BE CAREFUL: this will remove the experiment folders)
# You can manually verify the files removed in Git source control extension in VSC for example to be sure
python3.10 detect_anomalies.py "ComputeToData" "baseline" --remove
# Or different archetype and prefix
python3.10 detect_anomalies.py "DataThroughTTP" "caching" --remove
```

### Test normality
```sh
python3.10 test_normality.py "ComputeToData" "baseline"
# Or with a different prefix or archetype:
python3.10 test_normality.py "DataThroughTTP" "caching"
```


### Executing mean calculations
```sh
python3.10 calculate_mean.py "ComputeToData"
# Or with a different archetype:
python3.10 calculate_mean.py "DataThroughTTP"
python3.10 calculate_mean.py "all"
```


### Generate box plots
```sh
python3.10 generate_box_plot.py "ComputeToData"
# Or with a different archetype:
python3.10 generate_box_plot.py "DataThroughTTP"
python3.10 generate_box_plot.py "all"
```

### Calculate statistics (statistical significance and effect size) for each optimization compared to baseline for its corresponding archetype
```sh
python3.10 calculate_significance_effect.py "ComputeToData"
# Or with a different archetype:
python3.10 calculate_significance_effect.py "DataThroughTTP"
python3.10 calculate_significance_effect.py "all"
```


### Calculate correlation between energy and time for all experiments
```sh
python3.10 calculate_correlation_ener_time.py "ComputeToData"
# Or with a different archetype:
python3.10 calculate_correlation_ener_time.py "DataThroughTTP"
python3.10 calculate_correlation_ener_time.py "all"
```