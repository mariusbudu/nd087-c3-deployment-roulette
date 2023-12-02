#!/bin/bash

set -e

echo "Deploying green application with 3 pods"
kubectl apply -f green.yml 