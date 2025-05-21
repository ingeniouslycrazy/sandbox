kubectl apply -f .\services\metrics.yml
kubectl apply -f .\services\gitlab.yml -n gitlab-system
kubectl wait gitlab gitlab --for=condition=available -n gitlab-system --timeout=900s
kubectl get secret gitlab-gitlab-initial-root-password -n gitlab-system -ojsonpath="{.data.password}" > .\.temp_pw.b64
certutil -decode .\.temp_pw.b64 .\.temp_pw.txt >nul
echo.
echo Gitlab root password:
type .\.temp_pw.txt
del .\.temp_pw.*
echo[



