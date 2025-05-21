#!/bin/bash

kubectl apply -f ./services/metrics.yml
kubectl apply -f ./services/gitlab.yml -n gitlab-system --set runnerToken=glrt-dDoxCnU6MdF0Gby5xGI4zLkKxwhzbi4Q.0w1d05skm
kubectl wait gitlab gitlab --for=condition=available -n gitlab-system --timeout=600s
echo ""
echo "Gitlab root password: "
kubectl get secret gitlab-gitlab-initial-root-password -n gitlab-system -ojsonpath='{.data.password}' | base64 --decode
echo ""
