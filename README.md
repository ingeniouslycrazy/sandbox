# Sandbox

A dockerized k8s sandbox. Features:

- Nginx-Ingress
- Cert-Manager
- Metrics server
- Gitlab Operator

## Deploy

1. Run 'make create' to create the cluster.
2. Run 'make gitlab' to deploy a Gitlab installation.

## Purge

Run 'make purge' to delete the cluster.

## Working offline

docker pull kindest/node:v1.31.2
