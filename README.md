# Sandbox

A dockerized k8s sandbox. Features:

- Nginx-Ingress
- Cert-Manager
- Metrics server
- Gitlab Operator

## Deploy

1. Run './bin/create-cluster.sh' to create the cluster.
2. Run './bin/deploy-gitlab.sh' to deploy a Gitlab installation.

## Purge

Run './bin/purge-cluster.sh' to purge the cluster.

## Working offline

docker pull kindest/node:v1.31.2
