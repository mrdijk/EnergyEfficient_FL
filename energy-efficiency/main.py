# Import scripts
from get_metrics import main as export_metrics

# Running Prometheus: kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090

def main():
    """
    Main function of the energy measurements gathering. 
    Run this file to gather the energy measurements that can be used for the algorithms.
    """
    # Export metrics to file
    export_metrics()

    # TODO: AD algorithm (output to file also)

    # TODO: RCA algorithm (output to file also)

if __name__ == '__main__':
    main()