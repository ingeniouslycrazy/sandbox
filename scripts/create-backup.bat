if not exist .\.tmp mkdir .\.tmp

kubectl get secrets --field-selector type=kubernetes.io/tls -n cert-manager -o yaml > .\.tmp\cert-manager.yml
kubectl get secrets --field-selector type=kubernetes.io/tls -n gitlab-system -o yaml > .\.tmp\gitlab-system.yml
