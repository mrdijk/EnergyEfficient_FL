# Prometheus server URL (make sure you port forwarded Prometheus to localhost:9090)
PROMETHEUS = 'http://localhost:9090'

# Prometheus queries
PROMETHEUS_QUERIES = {
    # Kepler describes: The rate() of joules gives the power in Watts since the rate function returns the average per second. Therefore, for get the container energy consumption you can use the following query
    # Query to get the rate of joules (which gives power in Watts)
    "ENERGY_CONSUMPTION":'sum by (pod_name, container_name, container_namespace, node)(irate(kepler_container_joules_total{}[1m]))'
}

# Relevant Prometheus energy metrics 
RELEVANT_PROMETHEUS_CONTAINER_METRICS = [
    'container_blkio_device_usage_total',
    'container_cpu_usage_seconds_total',
    'container_fs_reads_bytes_total',
    'container_fs_reads_total',
    'container_fs_writes_bytes_total',
    'container_fs_writes_total',
    'container_last_seen',
    'container_memory_cache',
    'container_memory_failcnt',
    'container_memory_failures_total',
    'container_memory_kernel_usage',
    'container_memory_max_usage_bytes',
    'container_memory_rss',
    'container_memory_usage_bytes',
    'container_memory_working_set_bytes',
    'container_oom_events_total',
    'container_processes',
    'container_scrape_error',
    'container_sockets',
    'container_start_time_seconds',
    'container_threads',
]

# Relevant Kepler metrics (https://sustainable-computing.io/design/metrics/)
RELEVANT_KEPLER_CONTAINER_METRICS = [
    'kepler_container_joules_total',
    'kepler_container_core_joules_total',
    'kepler_container_dram_joules_total',
    'kepler_container_uncore_joules_total',
    'kepler_container_package_joules_total',
    'kepler_container_other_joules_total',
    'kepler_container_gpu_joules_total',
    'kepler_container_energy_stat',
    'kepler_container_bpf_cpu_time_us_total',
    'kepler_container_cpu_cycles_total',
    'kepler_container_cpu_instructions_total',
    'kepler_container_cache_miss_total',
    'kepler_container_cgroupfs_cpu_usage_us_total',
    'kepler_container_cgroupfs_memory_usage_bytes_total', 
    'kepler_container_cgroupfs_system_cpu_usage_us_total',
    'kepler_container_cgroupfs_user_cpu_usage_us_total',
    'kepler_container_bpf_net_tx_irq_total',
    'kepler_container_bpf_net_rx_irq_total',
    'kepler_container_bpf_block_irq_total',
    'kepler_node_info', 
    'kepler_node_core_joules_total',
    'kepler_node_uncore_joules_total',
    'kepler_node_dram_joules_total',
    'kepler_node_package_joules_total',
    'kepler_node_other_joules_total',
    'kepler_node_gpu_joules_total',
    'kepler_node_platform_joules_total',
    'kepler_node_energy_stat',
    'kepler_node_accelerator_intel_qat',
]