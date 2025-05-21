#!/bin/bash

# Create kind cluster
kind create cluster --name=sandbox --config=./cluster/kind-config.yml --image kindest/node:v1.31.2

# Patch kind cluster to forward the hostPorts to an NGINX ingress controller and schedule it to the control-plane custom labelled node
kubectl apply -f ./cluster/ingress.yml

# Wait until dust has settled
sleep 10
kubectl wait --namespace ingress-nginx --for=condition=Ready pod --selector=app.kubernetes.io/component=controller --timeout=300s

# Install cert-manager
helm upgrade --install cert-manager ./helm/cert-manager --namespace cert-manager --create-namespace --set crds.enabled=true

# Wait until dust has settled
kubectl wait -n cert-manager --for=condition=Ready -l "app.kubernetes.io/instance=cert-manager" pods

# configure issuers
kubectl apply -f ./cluster/issuers
