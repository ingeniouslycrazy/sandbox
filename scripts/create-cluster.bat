kind create cluster --name=sandbox --config=.\cluster\kind-config.yml --image kindest/node:v1.31.2
kubectl apply -f .\cluster\ingress.yml
timeout 10
kubectl wait --namespace ingress-nginx --for=condition=Ready pod --selector=app.kubernetes.io/component=controller --timeout=300s
kubectl create ns cert-manager
helm upgrade --install cert-manager .\helm\cert-manager --namespace cert-manager --set crds.enabled=true
kubectl wait -n cert-manager --for=condition=Ready -l "app.kubernetes.io/instance=cert-manager" pods
kubectl apply -f .\cluster\issuers
