#!/bin/bash

# Install gitlab-operator
helm upgrade --install gitlab-operator ./helm/gitlab-operator --namespace gitlab-system --create-namespace
# Wait until dust has settled
timeout 10
kubectl -n gitlab-system wait --for=condition=Ready -l 'control-plane=controller-manager' pods --timeout=600s
