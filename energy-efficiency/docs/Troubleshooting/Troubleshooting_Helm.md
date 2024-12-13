# Helm upgrade pending error
```
poetoec@LAPTOP-IA1OBTR5:/mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS$ helm upgrade -i prometheus prometheus-community/kube-prometheus-stack --namespace monitoring -f "$monitoringChartsPath/prometheus-config.yaml"
Error: UPGRADE FAILED: another operation (install/upgrade/rollback) is in progress
```
You can fix this by following these steps:
```sh
# Print status
helm status prometheus --namespace monitoring
# Might return something like:
NAME: prometheus
LAST DEPLOYED: Mon Aug 19 14:17:42 2024
NAMESPACE: monitoring
STATUS: pending-upgrade
REVISION: 11
TEST SUITE: None
NOTES:
kube-prometheus-stack has been installed. Check its status by running:
  kubectl --namespace monitoring get pods -l "release=prometheus"
Visit https://github.com/prometheus-operator/kube-prometheus for instructions on how to create & configure Alertmanager and Prometheus instances using the Operator.

# In the above output, you can see that the status is 'pending-upgrade'. It can occur that an upgrade is stuck. Rollback the upgrade by executing the following command:
helm rollback prometheus <REVISION> --namespace monitoring
# e.g. in the case of the above output: helm rollback prometheus 11 --namespace monitoring

# Then after the rollback is finished, you can try the upgrade command again.

# For additional information you can print the history of a namespace, such as:
helm history prometheus --namespace monitoring
```



# Helm issues
Example:
```sh
poetoec@LAPTOP-IA1OBTR5:/mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/energy-efficiency/scripts$ helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace --wait
Error: INSTALLATION FAILED: cannot re-use a name that is still in use
```
This is related to a release or namespace that may conflict. List the repo or all releases using these commands:
```sh
# List repost
helm repo list
# List releases
helm list
# List namespaces
kubectl get namespaces

# Uninstall release
helm uninstall <releaseName>
# Delete namespaces
kubectl delete namespace <namespaceName>
```
The example error above is because the namespace already existed, after removing it and rerunning the command it worked again.