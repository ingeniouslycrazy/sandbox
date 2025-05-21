if exist .\.tmp\cert-manager.yml kubectl create ns cert-manager
if exist .\.tmp\cert-manager.yml kubectl apply -f .\.tmp\cert-manager.yml

if exist .\.tmp\gitlab-system.yml kubectl create ns gitlab-system
if exist .\.tmp\gitlab-system.yml kubectl apply -f .\.tmp\gitlab-system.yml
