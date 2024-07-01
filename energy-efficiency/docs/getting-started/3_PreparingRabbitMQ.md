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

## Example Prometheus yaml file
```yaml
extraScrapeConfigs: |
  - job_name: 'kubelet'
    scheme: https
    tls_config:
      insecure_skip_verify: true
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    scrape_interval: 5s
    kubernetes_sd_configs:
    - role: node
    relabel_configs:
    - action: labelmap
      regex: __meta_kubernetes_node_label_(.+)
    - target_label: __address__
      replacement: kubernetes.default.svc:443
    - source_labels: [__address__]
      target_label: __metrics_path__
      replacement: /metrics

  - job_name: 'rabbitmq'
    tls_config:
      insecure_skip_verify: true
    metrics_path: '/metrics'
    scrape_interval: 5s
    static_configs:
      - targets: ['rabbitmq.core.svc.cluster.local:15692']
    basic_auth:
      username: 'guest'
      password: 'guest'

serverFiles:
  prometheus.yml:
    global:
      evaluation_interval: 1m
      scrape_interval: 1m
      scrape_timeout: 10s
    scrape_configs:
      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:9090']

# Disable grafana (not used currently)
grafana:
  enabled: false
```