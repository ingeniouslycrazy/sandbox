#!/bin/bash

# Register helm charts
#helm repo add gitlab https://charts.gitlab.io
#helm repo update

# Create kind cluster
kind create cluster --name=sandbox --config=./cluster/config.yml --image kindest/node:v1.31.2

# Patch kind cluster to forward the hostPorts to an NGINX ingress controller and schedule it to the control-plane custom labelled node
kubectl apply -f $(pwd)/cluster/deploy.yml
# Wait until dust has settled
kubectl wait -n ingress-nginx --for=condition=Ready -l 'app.kubernetes.io/component=controller' pods

# Install cert-manager
kubectl apply -f $(pwd)/cluster/cert-manager.yml
# Wait until dust has settled
kubectl wait -n cert-manager --for=condition=Ready -l "app.kubernetes.io/instance=cert-manager" pods

# Install metrics server
kubectl apply -f $(pwd)/cluster/metrics.yml

# Create self-signed cluster issuer
kubectl apply -f $(pwd)/cluster/selfsigned-cluster-issuer.yml
