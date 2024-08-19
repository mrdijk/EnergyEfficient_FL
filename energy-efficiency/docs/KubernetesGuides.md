# Kubernetes guides
This file contains documentation about Kubernetes related topics that I found very useful during my first time working with Kubernetes. It probably does not contain detailed information about general topics, like how Kubernetes works, because this is all available in the Kubernetes documentation for example. However, things that are not generally available in documentation and things I found very helpful during my time working with Kubernetes are explained here. So, use the documentation for general things, such as Kubernetes, Helm, etc., but for more understanding or useful steps, use this document.

Do NOT add unnecessary extra information here, because that will only consume time, while it is available in the general documentation of Kubernetes for example. Only add information that you find very helpful and only when you have time, because this is just extra information!

# Table of contents
<!-- TOC -->
- [Helm charts](#helm-charts)
  - [Helm Chart Structure](#helm-chart-structure)
  - [Example of Chart Structure](#example-of-chart-structure)
  - [How Helm uses this](#how-helm-uses-this)
- [Prometheus (using prometheus-stack over standalone prometheus)](#prometheus-using-prometheus-stack-over-standalone-prometheus)
- [Configuring Prometheus stack](#configuring-prometheus-stack)
- [Configuring config map in Prometheus (standalone, so NOT stack, this is an old guide and prometheus-stack is better to use, but may be useful sometime)](#configuring-config-map-in-prometheus-standalone-so-not-stack-this-is-an-old-guide-and-prometheus-stack-is-better-to-use-but-may-be-useful-sometime)
- [Minimal cadvisor setup for Prometheus (standalone, so NOT stack, this is an old guide and prometheus-stack is better to use, but may be useful sometime)](#minimal-cadvisor-setup-for-prometheus-standalone-so-not-stack-this-is-an-old-guide-and-prometheus-stack-is-better-to-use-but-may-be-useful-sometime)
<!-- /TOC -->


# Helm charts
The presence of multiple folders, each containing a Chart.yaml and a templates directory, suggests that you have a Helm chart repository or a collection of Helm charts. Each folder represents a separate Helm chart. Here's an explanation of how Helm uses these components:

## Helm Chart Structure
Each Helm chart has a specific structure, which includes:

- Chart.yaml: Contains metadata about the chart, such as its name, version, description, and dependencies.
- values.yaml: Default configuration values for the chart.
- templates: A directory containing Kubernetes resource templates that Helm will render using the values from values.yaml and other sources.
- charts: A directory containing any dependencies the chart has, in the form of other charts.
- README.md (optional): A markdown file containing information about the chart.

## Example of Chart Structure
charts/
├── mychart/
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── templates/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── ... other template files ...
│   └── charts/
│       └── ... dependency charts ...
├── anotherchart/
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── templates/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── ... other template files ...
│   └── charts/
│       └── ... dependency charts ...
└── ... other charts ...

## How Helm uses this

When you run helm install, Helm looks for the specified chart in your local directory or a remote repository. It reads the Chart.yaml for metadata and renders the templates in the templates directory using the default values from values.yaml and any overrides you provide with --values or --set.
```sh
helm install myrelease ./charts/mychart -f custom-values.yaml
```
This command installs the mychart chart from the charts directory, using overrides from custom-values.yaml.

Similar to install, helm upgrade updates an existing release with the new configuration or chart version.

# Prometheus (using prometheus-stack over standalone prometheus)

Using the `kube-prometheus-stack` over a standalone Prometheus setup offers several advantages, particularly in terms of ease of deployment, integration, and feature set. Here are some key benefits:

## 1. Comprehensive Monitoring Solution
- **Integrated Components**: The `kube-prometheus-stack` includes Prometheus, Alertmanager, Grafana, Node Exporter, Kube State Metrics, and more. This provides a complete monitoring stack out-of-the-box.
- **Pre-configured Dashboards**: Grafana dashboards are pre-configured for Kubernetes monitoring, saving time on setting up visualizations.

## 2. Ease of Deployment and Management
- **Prometheus Operator**: Simplifies the deployment and management of Prometheus instances. The operator automates tasks like configuration updates, scaling, and maintaining the lifecycle of Prometheus and Alertmanager instances.
- **Automatic Discovery**: The stack uses Kubernetes CRDs (Custom Resource Definitions) such as `ServiceMonitor` and `PodMonitor` to automatically discover and scrape metrics from services and pods.

## 3. Scalability and Flexibility
- **Cluster Monitoring**: Designed specifically for Kubernetes, it scales with your cluster and can monitor multiple namespaces and clusters.
- **Custom Resource Definitions (CRDs)**: Easily extend monitoring to new services by defining `ServiceMonitor`, `PodMonitor`, `PrometheusRule`, and other custom resources.

## 4. Alerting and Notification Management
- **Alertmanager Integration**: Alertmanager is included and integrated, allowing for sophisticated alerting and notification management. It supports routing, deduplication, grouping, and sending alerts via various notification channels.
- **Predefined Alerts**: Comes with a set of predefined Prometheus alerting rules for Kubernetes components.

## 5. Security and RBAC
- **Role-Based Access Control (RBAC)**: Properly configured RBAC rules ensure secure access and operation within the Kubernetes cluster.
- **TLS Support**: Supports TLS for secure communication between Prometheus, Alertmanager, and other components.

## 6. Community and Ecosystem Support
- **Active Development**: The `kube-prometheus-stack` is actively maintained and developed by the Prometheus and Kubernetes communities, ensuring it stays up-to-date with the latest features and best practices.
- **Extensive Documentation**: Comprehensive documentation and community support make it easier to troubleshoot and extend the stack.

## 7. Best Practices Implementation
- **Configuration Management**: Implements best practices for configuring and managing Prometheus and related components in a Kubernetes environment.
- **Resource Efficiency**: Optimized for resource usage in a Kubernetes environment, ensuring efficient operation without excessive resource consumption.

## Example: Simplified Configuration with ServiceMonitors

Using the `kube-prometheus-stack`, you can leverage `ServiceMonitor` and `PodMonitor` resources to automatically configure Prometheus to scrape metrics from your applications. For example:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-service-monitor
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: my-app
  endpoints:
  - port: metrics
    interval: 30s
```
Save the above configuration to a file, for example my-service-monitor.yaml, and apply it using kubectl:
```sh
kubectl apply -f my-service-monitor.yaml
```
This command will create the ServiceMonitor resource, and the Prometheus Operator will automatically configure Prometheus to scrape metrics from services labeled app: my-app on the metrics port at 30-second intervals.

Of course, this is just an example and you should change this to your specific use case/app you are currently configuring.


# Configuring Prometheus stack
You can configure everything using a .yaml file. For example, this file:
```yaml
# Keep this format for this part, because this works for adding additional scrape configs!
prometheus:
  prometheusSpec:
    # Set global scrape interval and scrape timeout
    evaluationInterval: "30s"
    scrapeInterval: "30s"
    # Set this to higher to avoid cadvisor sometimes timing out
    scrapeTimeout: "25s"

    # Additional scrape configs (on top of already present/default ones)
    additionalScrapeConfigs:
      # Job to gather metrics like CPU and memory using cadvisor daemonset
      - job_name: 'cadvisor'
        # Configures Kubernetes service discovery to find pods
        kubernetes_sd_configs:
          - role: pod
        # Configures relabeling rules
        relabel_configs:
          # Keep only pods with the label app=cadvisor (otherwise all other metrics will be included, but you only want cadvisor metrics)
          # Make sure that the name label is present in the pod (or in this case daemonset) you are creating! Otherwise, Prometheus cannot see it
          - source_labels: [__meta_kubernetes_pod_label_name]
            action: keep
            regex: cadvisor
          # Replace target with pod IP and port 8080 (where cadvisor runs)
          - source_labels: [__meta_kubernetes_pod_ip]
            action: replace
            target_label: __address__
            regex: (.+)
            replacement: ${1}:8080
          # No custom labels/replacements are set here (do NOT change this, because now it works!), so that the defaults of 
          # cadvisor are used! For example, you can group by name of the container with: container_label_io_kubernetes_container_name

# Disable grafana from prometheus stack (not needed anyway)
grafana:
  enabled: false
```
This can be used to install and/or upgrade Prometheus stack by appending additional scrape configs and adding scrape intervals globally for example. You can upgrade Prometheus by following these steps:
```sh
# Set variables for the paths (example with the monitoring chart path)
monitoringChartsPath="/mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/charts/monitoring"
monitoringValues="$monitoringChartsPath/values.yaml"

# Rerun/upgrade Prometheus stack with the file
helm upgrade -i prometheus prometheus-community/kube-prometheus-stack --namespace monitoring -f "$monitoringChartsPath/prometheus-config.yaml"

# Upgrade/apply the helm chart for the monitoring release:
helm upgrade -i -f "$monitoringValues" monitoring $monitoringChartsPath

# Then delete the prometheus operator pod (recreates it automatically == restart pod)
kubectl delete pod prometheus-kube-prometheus-operator-<stringInPodName> -n monitoring
# e.g.: kubectl delete pod prometheus-kube-prometheus-operator-6554f4464f-x2dw9 -n monitoring

# Then port forward promtheus and see if it is working
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090
# You can view configurations by going to Status > Configuration in Prometheus
```
If a configuration is not being added in the configuration, then it is probably because the syntax is not correct. If the syntax is not correct, then the configuration will not be applied! For example, if you replace the "scrape_interval: '1m'" with 1m, instead of '1m' (as a string), it will not be applied, because the syntax is wrong for the number type: 1m.



# Configuring config map in Prometheus (standalone, so NOT stack, this is an old guide and prometheus-stack is better to use, but may be useful sometime)
```sh
# Create or update the configmap for prometheus-server
kubectl create configmap prometheus-server --from-file=prometheus.yml="<pathToconfigFile>prometheus-config.yaml" -n monitoring --dry-run=client -o yaml | kubectl apply -f-

# Restart the promtheus-server pod (delete will automatically cretae a new one)
# e.g. prometheus-server-5787759b8c-h2qj6 (but view exact pod name in kubennetes dashboard)
kubectl delete pod prometheus-server-<stringid> -n monitoring

# Then port forward promtheus and see if it is working (assuming you are using standalone prometheus)
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring
```
## Minimal cadvisor setup for Prometheus (standalone, so NOT stack, this is an old guide and prometheus-stack is better to use, but may be useful sometime)
```yaml
global:
  scrape_interval: 1m
  evaluation_interval: 1m
  # Avoids cadvisor to exceed the timeout range for example (increase when jobs are exceeding this time)
  scrape_timeout: 25s

scrape_configs:
  # Job to gather metrics like CPU and memory using cadvisor daemonset
  - job_name: 'cadvisor'
    # Configures Kubernetes service discovery to find pods
    kubernetes_sd_configs:
      - role: pod
    # Configures relabeling rules
    relabel_configs:
      # Keep only pods with the label app=cadvisor (otherwise all other metrics will be included, but you only want cadvisor metrics)
      - source_labels: [__meta_kubernetes_pod_label_name]
        action: keep
        regex: cadvisor
      # Replace target with pod IP and port 8080 (where cadvisor runs)
      - source_labels: [__meta_kubernetes_pod_ip]
        action: replace
        target_label: __address__
        regex: (.+)
        replacement: ${1}:8080
      # No custom labels/replacements are set here (do NOT change this, because now it works!), so that the defaults of 
      # cadvisor are used! For example, you can group by name of the container with: container_label_io_kubernetes_container_name
```