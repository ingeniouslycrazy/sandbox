kubectl create ns gitlab-system
helm upgrade --install gitlab-operator .\helm\gitlab-operator --namespace gitlab-system
timeout 10
kubectl -n gitlab-system wait pods --for="condition=Ready" -l "control-plane=controller-manager" --timeout=600s
