# Install gitlab-operator
kubectl create namespace gitlab-system
helm upgrade --install gitlab-operator gitlab/gitlab-operator --namespace gitlab-system

# Wait until dust has settled
kubectl -n gitlab-system wait --for=condition=Ready -l 'control-plane=controller-manager' pods --timeout=300s

# Install GitLab
kubectl -n gitlab-system apply -f .\old\gitlab\gitlab.yml

# Wait until dust has settled
kubectl -n gitlab-system wait gitlab gitlab --for=condition=available --timeout 600s

# Get the password to configure GitLab
kubectl -n gitlab-system get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo
