# Preparing rabbitMQ
## Running first script
First, replace the corePath variable with the correct path of your project (an example is present in the script). Then run the first file to prepare RabbitMQ:
```sh
# Go to the scripts path
cd energy-efficiency/scripts/
# Make the script executable
chmod +x 1_prepareRabbitMQ.sh
# Execute the script with the core path, such as:
./1_prepareRabbitMQ.sh /mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/charts/core
```

## Prepare definitions.json file
1. Copy the returned hashed password from script 1.

2. Rename the file configuration/k8s_service_files/definitions_example.json to definitions.json

3. Add hashed password to RabbitMQ definitions.json (above file) for normal_user password_hash

## Running the second script
Then run the next script to prepare RabbitMQ:
```sh
# Make the script executable
chmod +x 2_prepareRabbitMQ.sh
# Execute the script with the charts path, such as:
./2_prepareRabbitMQ.sh /mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/charts
```
It may take a while before all the pods are running, sometimes even up to more than 20 minutes.