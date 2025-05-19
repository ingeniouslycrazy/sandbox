kind create cluster --name=sandbox --config=.\cluster\kind-config.yml --image kindest/node:v1.31.2
kubectl apply -f .\cluster\ingress.yml
timeout 10
kubectl wait --namespace ingress-nginx --for=condition=Ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
helm repo add jetstack https://charts.jetstack.io --force-update
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set crds.enabled=true
kubectl wait -n cert-manager --for=condition=Ready -l "app.kubernetes.io/instance=cert-manager" pods
kubectl apply -f .\cluster\issuers
