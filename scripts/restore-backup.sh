#!/bin/bash

if [ -f ./.tmp/cert-manager.yml ]; then
  kubectl create ns cert-manager
  kubectl apply -f ./.tmp/cert-manager.yml
fi

if [ -f ./.tmp/gitlab-system.yml ]; then
  kubectl create ns gitlab-system
  kubectl apply -f ./.tmp/gitlab-system.yml.yml
fi