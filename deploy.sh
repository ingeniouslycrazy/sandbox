#!/bin/bash

# Register helm charts
#helm repo add gitlab https://charts.gitlab.io
#helm repo update

# Create kind cluster
kind delete cluster --name=sandbox
kind create cluster --name=sandbox --config=./cluster/config.yml

# Patch kind cluster to forward the hostPorts to an NGINX ingress controller and schedule it to the control-plane custom labelled node
kubectl apply -f ./cluster/deploy.yaml
# Wait until dust has settled
kubectl wait --for=condition=Ready -l 'app.kubernetes.io/component=controller' pods -n ingress-nginx

# Install cert-manager
kubectl apply -f ./cluster/cert-manager.yaml
# Wait until dust has settled
kubectl wait --for=condition=Ready -l 'app.kubernetes.io/instance=cert-manager,app.kubernetes.io/component=controller' pods

# Install metrics server
kubectl apply -f ./cluster/metrics.yml

# Create self-signed cluster issuer
kubectl apply -f ./cluster/selfsigned-cluster-issuer.yml

# Install gitlab-operator
helm install gitlab-operator ./helm-charts/gitlab-operator --create-namespace --namespace gitlab-system
# Wait until dust has settled
kubectl wait --for=condition=Ready -l 'control-plane=controller-manager' pods -n gitlab-system

# Install GitLab
kubectl apply -f ./cluster/gitlab/gitlab.yml
# Wait until dust has settled
sleep 60 && kubectl wait pods --for=condition=Ready -n gitlab-system -l 'app.kubernetes.io/instance=gitlab-webservice,app.kubernetes.io/managed-by=gitlab-operator' --timeout=600s

# Get the password to configure GitLab
kubectl get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo
