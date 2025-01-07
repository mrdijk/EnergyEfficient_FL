# Prometheus server URL (make sure you port forwarded Prometheus to localhost:9090)
PROMETHEUS_URL = 'http://localhost:9090'

# The steps used for the metrics (in seconds)
METRIC_STEP = 5
# Maximum resolution of Prometheus (i.e. the maximum number of data points that can be returned in a single query)
MAX_RESOLUTION = 11_000
# How far back in time Prometheus should look to calculate the rate of change
# Set to multiple minutes to get more data points for the rate calculation
DURATION = "2m"

# Labels used to identify the container name in the Prometheus metrics
KEPLER_CONTAINER_NAME_LABEL = "container_name"
CADVISOR_CONTAINER_NAME_LABEL = "container_label_io_kubernetes_container_name"
# CADVISOR_GROUP_BY = f"{CADVISOR_CONTAINER_NAME_LABEL}, name, container_label_io_kubernetes_pod_namespace, node"

# Prometheus queries to get relevant energy metrics
# Group by os custom so that the queries work optimally with the Prometheus metrics
# (see TroubleShooting.md for explanation of container label in cadvisor)
QUERIES = {
    "cpu": f"sum(rate(container_cpu_usage_seconds_total[{DURATION}])) by ({CADVISOR_CONTAINER_NAME_LABEL})",
    "memory": f"sum(rate(container_memory_usage_bytes[{DURATION}])) by ({CADVISOR_CONTAINER_NAME_LABEL})",
    "memory_rss": f"sum(rate(container_memory_rss[{DURATION}])) by ({CADVISOR_CONTAINER_NAME_LABEL})",
    "memory_cache": f"sum(rate(container_memory_cache[{DURATION}])) by ({CADVISOR_CONTAINER_NAME_LABEL})",
    # Total bytes read by the container
    "disk": f"sum(rate(container_fs_reads_bytes_total[{DURATION}])) by ({CADVISOR_CONTAINER_NAME_LABEL})",
    # Energy metric, as stated by Kepler documentation (https://sustainable-computing.io/design/metrics/#exploring-node-exporter-metrics-through-the-prometheus-expression)
    # This query gets the energy consumption. The query stated in the 
    # documentation is suited to fit with the other queries (cpu, memory, ...) from the study by Ivano and colleagues 
    "energy": f"sum(increase(kepler_container_joules_total[{DURATION}])) by ({KEPLER_CONTAINER_NAME_LABEL})"
}

# Relevant containers to monitor the energy consumption 
CONTAINERS = {
    # Use case specific containers
    "api-gateway",
    "vu",
    "uva",
    "surf",
    "sql-query",
    "sql-algorithm",
    "sql-anonymize",
    "sql-test",
    # Policy containers
    "policy",
    "policy-enforcer",
    "orchestrator",
    # Sidecar pattern container
    "sidecar",
    # General Kubernetes containers relevant to include
    "system_processes",
    "rabbitmq"
}