# Prometheus server URL (make sure you port forwarded Prometheus to localhost:9090)
PROMETHEUS_URL = 'http://localhost:9090'

# The steps used for the metrics (in seconds)
METRIC_STEP = 5
# Maximum resolution of Prometheus (i.e. the maximum number of data points that can be returned in a single query)
MAX_RESOLUTION = 11_000
# How far back in time Prometheus should look to calculate the rate of change
# Set to two minutes to get more data points for the rate calculation (1m sometimes gives no data)
DURATION = "10m"

# Labels used to identify the container name in the Prometheus metrics
KEPLER_CONTAINER_NAME_LABEL = "container_name"
CADVISOR_CONTAINER_NAME_LABEL = "container_label_io_kubernetes_container_name"
# CADVISOR_GROUP_BY = f"{CADVISOR_CONTAINER_NAME_LABEL}, name, container_label_io_kubernetes_pod_namespace, node"

# Prometheus queries to get relevant energy metrics
# Group by os custom so that the queries work optimally with the Prometheus metrics
# (see TroubleShooting.md for explanation of container label in cadvisor)
QUERIES = {
    "cpu": f"sum(rate(container_cpu_usage_seconds_total[{DURATION}])) by ({CADVISOR_CONTAINER_NAME_LABEL})",
    # "memory": f"sum(rate(container_memory_usage_bytes[{DURATION}])) by ({CADVISOR_CONTAINER_NAME_LABEL})",
    # "memory_rss": f"sum(rate(container_memory_rss[{DURATION}])) by ({CADVISOR_CONTAINER_NAME_LABEL})",
    # "memory_cache": f"sum(rate(container_memory_cache[{DURATION}])) by ({CADVISOR_CONTAINER_NAME_LABEL})",
    # # Total bytes read by the container
    # "disk": f"sum(rate(container_fs_reads_bytes_total[{DURATION}])) by ({CADVISOR_CONTAINER_NAME_LABEL})",
    # # Power consumption using Kepler (https://sustainable-computing.io/design/metrics/)
    # "power": f"sum by (pod_name, {KEPLER_CONTAINER_NAME_LABEL}, container_namespace, node)(irate(kepler_container_joules_total[{DURATION}]))"
}

# Relevant containers to monitor the energy consumption 
# (use scripts/describeContainers.sh to print containers in the Kubernetes cluster)
# TODO: use containers used by DYNAMOS later (containers from orchestrator, vu, uva, etc.)
CONTAINERS = {
    "etcd",
    "rabbitmq",
    "nginx-ingress",
    "policy",
    "linkerd-proxy",
    "kube-state-metrics",
    "proxy-injector",
    "node-exporter",
    "identity",
    "ot-collector",
    "kube-proxy",
    "destination",
    "jaeger",
    "prometheus-server"
}


# TODO: remove later, not necessary anymore (now uses queries/metrics from study from Ivano and colleagues)
# # Relevant Prometheus energy metrics
# RELEVANT_PROMETHEUS_CONTAINER_METRICS = [
#     'container_blkio_device_usage_total',
#     'container_cpu_usage_seconds_total',
#     'container_fs_reads_bytes_total',
#     'container_fs_reads_total',
#     'container_fs_writes_bytes_total',
#     'container_fs_writes_total',
#     'container_last_seen',
#     'container_memory_cache',
#     'container_memory_failcnt',
#     'container_memory_failures_total',
#     'container_memory_kernel_usage',
#     'container_memory_max_usage_bytes',
#     'container_memory_rss',
#     'container_memory_usage_bytes',
#     'container_memory_working_set_bytes',
#     'container_oom_events_total',
#     'container_processes',
#     'container_scrape_error',
#     'container_sockets',
#     'container_start_time_seconds',
#     'container_threads',
# ]

# # Relevant Kepler metrics (https://sustainable-computing.io/design/metrics/)
# RELEVANT_KEPLER_CONTAINER_METRICS = [
#     'kepler_container_joules_total',
#     'kepler_container_core_joules_total',
#     'kepler_container_dram_joules_total',
#     'kepler_container_uncore_joules_total',
#     'kepler_container_package_joules_total',
#     'kepler_container_other_joules_total',
#     'kepler_container_gpu_joules_total',
#     'kepler_container_energy_stat',
#     'kepler_container_bpf_cpu_time_us_total',
#     'kepler_container_cpu_cycles_total',
#     'kepler_container_cpu_instructions_total',
#     'kepler_container_cache_miss_total',
#     'kepler_container_cgroupfs_cpu_usage_us_total',
#     'kepler_container_cgroupfs_memory_usage_bytes_total',
#     'kepler_container_cgroupfs_system_cpu_usage_us_total',
#     'kepler_container_cgroupfs_user_cpu_usage_us_total',
#     'kepler_container_bpf_net_tx_irq_total',
#     'kepler_container_bpf_net_rx_irq_total',
#     'kepler_container_bpf_block_irq_total',
#     'kepler_node_info',
#     'kepler_node_core_joules_total',
#     'kepler_node_uncore_joules_total',
#     'kepler_node_dram_joules_total',
#     'kepler_node_package_joules_total',
#     'kepler_node_other_joules_total',
#     'kepler_node_gpu_joules_total',
#     'kepler_node_platform_joules_total',
#     'kepler_node_energy_stat',
#     'kepler_node_accelerator_intel_qat',
# ]
