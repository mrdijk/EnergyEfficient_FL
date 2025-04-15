#!/bin/bash

# Helper script to quickly uninstall all from the dynamos-configuration (can upload and execute the same way as dynamos-configuration.sh)

helm uninstall namespaces
helm uninstall nginx -n ingress
helm uninstall core
helm uninstall orchestrator
helm uninstall agents
helm uninstall surf
helm uninstall api-gateway