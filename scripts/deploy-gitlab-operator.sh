#!/bin/bash

# Install gitlab-operator
kubectl create ns gitlab-system
helm upgrade --install gitlab-operator ./helm/gitlab-operator --namespace gitlab-system
timeout 10
kubectl -n gitlab-system wait --for=condition=Ready -l 'control-plane=controller-manager' pods --timeout=600s
