#!/bin/bash

# Helper script to quickly uninstall all from the dynamos-configuration (can upload and execute the same way as dynamos-configuration.sh)

# DYNAMOS configuration
helm uninstall namespaces
helm uninstall nginx -n ingress
helm uninstall core
helm uninstall orchestrator
helm uninstall agents
helm uninstall surf
helm uninstall api-gateway

# Monitoring
helm uninstall prometheus --namespace monitoring
helm uninstall kepler -n monitoring
helm uninstall monitoring --namespace monitoring