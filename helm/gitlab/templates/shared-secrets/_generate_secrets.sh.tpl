# vim: set filetype=sh:

namespace={{ .Release.Namespace }}
release={{ .Release.Name }}
env={{ index .Values "shared-secrets" "env" }}

pushd $(mktemp -d)

# Args pattern, length
function gen_random(){
  head -c 4096 /dev/urandom | LC_CTYPE=C tr -cd $1 | head -c $2
}

# Args: length
function gen_random_base64(){
  local len="$1"
  head -c "$len" /dev/urandom | base64 -w0
}

# Args: yaml file, search path
function fetch_rails_value(){
  local value=$(yq --prettyPrint --no-colors ".${2}" $1)

  # Don't return null values
  if [ "${value}" != "null" ]; then echo "${value}"; fi
}

# Args: secretname
function label_secret(){
  local secret_name=$1
{{ if not .Values.global.application.create -}}
  # Remove application labels if they exist
  kubectl --namespace=$namespace label \
    secret $secret_name $(echo '{{ include "gitlab.application.labels" . | replace ": " "=" | replace "\r\n" " " | replace "\n" " " }}' | sed -E 's/=[^ ]*/-/g')
{{ end }}
  kubectl --namespace=$namespace label \
    --overwrite \
    secret $secret_name {{ include "gitlab.standardLabels" . | replace ": " "=" | replace "\r\n" " " | replace "\n" " " }} {{ include "gitlab.commonLabels" . | replace ": " "=" | replace "\r\n" " " | replace "\n" " " }}
}

# Args: secretname, args
function generate_secret_if_needed(){
  local secret_args=( "${@:2}")
  local secret_name=$1

  if ! $(kubectl --namespace=$namespace get secret $secret_name > /dev/null 2>&1); then
    kubectl --namespace=$namespace create secret generic $secret_name ${secret_args[@]}
  else
    echo "secret \"$secret_name\" already exists."

    for arg in "${secret_args[@]}"; do
      local from=$(echo -n ${arg} | cut -d '=' -f1)

      if [ -z "${from##*literal*}" ]; then
        local key=$(echo -n ${arg} | cut -d '=' -f2)
        local desiredValue=$(echo -n ${arg} | cut -d '=' -f3-)
        local flags="--namespace=$namespace --allow-missing-template-keys=false"

        if ! $(kubectl $flags get secret $secret_name -ojsonpath="{.data.${key}}" > /dev/null 2>&1); then
          echo "key \"${key}\" does not exist. patching it in."

          if [ "${desiredValue}" != "" ]; then
            desiredValue=$(echo -n "${desiredValue}" | base64 -w 0)
          fi

          kubectl --namespace=$namespace patch secret ${secret_name} -p "{\"data\":{\"$key\":\"${desiredValue}\"}}"
        fi
      fi
    done
  fi

  label_secret $secret_name
}

# Initial root password
generate_secret_if_needed {{ template "gitlab.migrations.initialRootPassword.secret" . }} --from-literal={{ template "gitlab.migrations.initialRootPassword.key" . }}=$(gen_random 'a-zA-Z0-9' 64)

{{/*
The include in this if returns a value that makes use of
"gitlab.redis.configMerge" to return global.redis.password.enabled
with a fallback to global.redis.auth.enabled - it is evaluated for truthiness, based
on emptiness of the returned string.

This should be read as:

"if there's not a defined global.redis.host and we've enabled redis password
auth, then generate secrets if needed"
*/}}
{{ if and (not .Values.global.redis.host) (eq (include "gitlab.redis.password.enabled" $) "true" ) -}}
# Redis password
generate_secret_if_needed {{ template "gitlab.redis.password.secret" . }} --from-literal={{ template "gitlab.redis.password.key" . }}=$(gen_random 'a-zA-Z0-9' 64)
{{ end }}

{{ if not .Values.global.psql.host -}}
# Postgres password
generate_secret_if_needed {{ template "gitlab.psql.password.secret" . }} --from-literal={{ include "gitlab.psql.password.key" . }}=$(gen_random 'a-zA-Z0-9' 64) --from-literal=postgresql-postgres-password=$(gen_random 'a-zA-Z0-9' 64)
{{ end }}

# Gitlab shell
generate_secret_if_needed {{ template "gitlab.gitlab-shell.authToken.secret" . }} --from-literal={{ template "gitlab.gitlab-shell.authToken.key" . }}=$(gen_random 'a-zA-Z0-9' 64)

# Gitaly secret
generate_secret_if_needed {{ template "gitlab.gitaly.authToken.secret" . }} --from-literal={{ template "gitlab.gitaly.authToken.key" . }}=$(gen_random 'a-zA-Z0-9' 64)

{{ if .Values.global.minio.enabled -}}
# Minio secret
generate_secret_if_needed {{ template "gitlab.minio.credentials.secret" . }} --from-literal=accesskey=$(gen_random 'a-zA-Z0-9' 64) --from-literal=secretkey=$(gen_random 'a-zA-Z0-9' 64)
{{ end }}

# Gitlab runner secret
generate_secret_if_needed {{ template "gitlab.gitlab-runner.registrationToken.secret" . }} --from-literal=runner-registration-token=$(gen_random 'a-zA-Z0-9' 64) --from-literal=runner-token=""

# GitLab Pages API secret
{{ if or (eq $.Values.global.pages.enabled true) (not (empty $.Values.global.pages.host)) }}
generate_secret_if_needed {{ template "gitlab.pages.apiSecret.secret" . }} --from-literal={{ template "gitlab.pages.apiSecret.key" . }}=$(gen_random 'a-zA-Z0-9' 32 | base64)
{{ end }}

# GitLab Pages auth secret for hashing cookie store when using access control
{{ if and (eq $.Values.global.pages.enabled true) (eq $.Values.global.pages.accessControl true) }}
generate_secret_if_needed {{ template "gitlab.pages.authSecret.secret" . }} --from-literal={{ template "gitlab.pages.authSecret.key" . }}=$(gen_random 'a-zA-Z0-9' 64 | base64 -w 0)
{{ end }}

# GitLab Pages OAuth secret
{{ if and (eq $.Values.global.pages.enabled true) (eq $.Values.global.pages.accessControl true) }}
generate_secret_if_needed {{ template "oauth.gitlab-pages.secret" . }} --from-literal={{ template "oauth.gitlab-pages.appIdKey" . }}=$(gen_random 'a-zA-Z0-9' 64) --from-literal={{ template "oauth.gitlab-pages.appSecretKey" . }}=$(gen_random 'a-zA-Z0-9' 64)
{{ end }}

{{ if .Values.global.kas.enabled -}}
# Gitlab-kas secret
generate_secret_if_needed {{ template "gitlab.kas.secret" . }} --from-literal={{ template "gitlab.kas.key" . }}=$(gen_random 'a-zA-Z0-9' 32 | base64)

# Gitlab-kas private API secret
generate_secret_if_needed {{ template "gitlab.kas.privateApi.secret" . }} --from-literal={{ template "gitlab.kas.privateApi.key" . }}=$(gen_random 'a-zA-Z0-9' 32 | base64)

# Gitlab-kas WebSocket Token secret
generate_secret_if_needed {{ template "gitlab.kas.websocketToken.secret" . }} --from-literal={{ template "gitlab.kas.websocketToken.key" . }}=$(gen_random_base64 72)

{{ if (.Values.gitlab.kas.autoflow).enabled -}}
# Gitlab-kas AutoFlow Temporal Workflow Data Encryption Secret
trap 'shred --remove autoflow-temporal-workflow-data-encryption-secret.bin' EXIT
openssl rand 32 > autoflow-temporal-workflow-data-encryption-secret.bin
generate_secret_if_needed {{ template "gitlab.kas.autoflow.temporal.workflowDataEncryption.secret" . }} --from-file={{ template "gitlab.kas.autoflow.temporal.workflowDataEncryption.key" . }}=autoflow-temporal-workflow-data-encryption-secret.bin
{{ end }}
{{ end }}

# Gitlab-suggested-reviewers secret
generate_secret_if_needed {{ template "gitlab.suggested-reviewers.secret" . }} --from-literal={{ template "gitlab.suggested-reviewers.key" . }}=$(gen_random 'a-zA-Z0-9' 32 | base64)

{{ if .Values.global.appConfig.incomingEmail.enabled -}}
# Gitlab-mailroom incomingEmail webhook secret
generate_secret_if_needed {{ template "gitlab.appConfig.incomingEmail.authToken.secret" . }} --from-literal={{ template "gitlab.appConfig.incomingEmail.authToken.key" . }}=$(gen_random 'a-zA-Z0-9' 32 | base64)
{{ end }}

{{ if .Values.global.appConfig.serviceDeskEmail.enabled -}}
# Gitlab-mailroom serviceDeskEmail webhook secret
generate_secret_if_needed {{ template "gitlab.appConfig.serviceDeskEmail.authToken.secret" . }} --from-literal={{ template "gitlab.appConfig.serviceDeskEmail.authToken.key" . }}=$(gen_random 'a-zA-Z0-9' 32 | base64)
{{ end }}

# Registry certificates
mkdir -p certs
openssl req -new -newkey rsa:4096 -subj "/CN={{ coalesce .Values.registry.tokenIssuer  (dig "registry" "tokenIssuer" "gitlab-issuer" .Values.global ) }}" -nodes -x509 -keyout certs/registry-example-com.key -out certs/registry-example-com.crt -days 3650
generate_secret_if_needed {{ template "gitlab.registry.certificate.secret" . }} --from-file=registry-auth.key=certs/registry-example-com.key --from-file=registry-auth.crt=certs/registry-example-com.crt

# config/secrets.yaml
if [ -n "$env" ]; then
  rails_secret={{ template "gitlab.rails-secrets.secret" . }}

  # Fetch the values from the existing secret if it exists
  if $(kubectl --namespace=$namespace get secret $rails_secret > /dev/null 2>&1); then
    kubectl --namespace=$namespace get secret $rails_secret -o jsonpath="{.data.secrets\.yml}" | base64 --decode > secrets.yml
    secret_key_base=$(fetch_rails_value secrets.yml "${env}.secret_key_base")
    otp_key_base=$(fetch_rails_value secrets.yml "${env}.otp_key_base")
    db_key_base=$(fetch_rails_value secrets.yml "${env}.db_key_base")
    openid_connect_signing_key=$(fetch_rails_value secrets.yml "${env}.openid_connect_signing_key")
    encrypted_settings_key_base=$(fetch_rails_value secrets.yml "${env}.encrypted_settings_key_base")

    active_record_encryption_primary_keys=$(fetch_rails_value secrets.yml "${env}.active_record_encryption_primary_key")
    active_record_encryption_deterministic_keys=$(fetch_rails_value secrets.yml "${env}.active_record_encryption_deterministic_key")
    active_record_encryption_key_derivation_salt=$(fetch_rails_value secrets.yml "${env}.active_record_encryption_key_derivation_salt")
  fi;

  # Generate defaults for any unset secrets
  secret_key_base="${secret_key_base:-$(gen_random 'a-f0-9' 128)}" # equivalent to secureRandom.hex(64)
  otp_key_base="${otp_key_base:-$(gen_random 'a-f0-9' 128)}" # equivalent to secureRandom.hex(64)
  db_key_base="${db_key_base:-$(gen_random 'a-f0-9' 128)}" # equivalent to secureRandom.hex(64)
  openid_connect_signing_key="${openid_connect_signing_key:-$(openssl genrsa 2048)}"
  encrypted_settings_key_base="${encrypted_settings_key_base:-$(gen_random 'a-f0-9' 128)}" # equivalent to secureRandom.hex(64)

  # 1. We set the following two keys as an array to support keys rotation.
  #    The last key in the array is always used to encrypt data:
  #    https://github.com/rails/rails/blob/v7.0.8.4/activerecord/lib/active_record/encryption/key_provider.rb#L21
  #    while all the keys are used (in the order they're defined) to decrypt data:
  #    https://github.com/rails/rails/blob/v7.0.8.4/activerecord/lib/active_record/encryption/cipher.rb#L26.
  #    This allows to rotate keys by adding a new key as the last key, and start a re-encryption process that
  #    runs in the background: https://gitlab.com/gitlab-org/gitlab/-/issues/494976
  # 2. We use the same method and length as Rails' defaults:
  #    https://github.com/rails/rails/blob/v7.0.8.4/activerecord/lib/active_record/railties/databases.rake#L537-L540
  active_record_encryption_primary_keys=${active_record_encryption_primary_keys:-"- $(gen_random 'a-zA-Z0-9' 32)"}
  active_record_encryption_deterministic_keys=${active_record_encryption_deterministic_keys:-"- $(gen_random 'a-zA-Z0-9' 32)"}
  active_record_encryption_key_derivation_salt=${active_record_encryption_key_derivation_salt:-$(gen_random 'a-zA-Z0-9' 32)}

  # Update the existing secret
  cat << EOF > rails-secrets.yml
apiVersion: v1
kind: Secret
metadata:
  name: $rails_secret
type: Opaque
stringData:
  secrets.yml: |-
    $env:
      secret_key_base: $secret_key_base
      otp_key_base: $otp_key_base
      db_key_base: $db_key_base
      encrypted_settings_key_base: $encrypted_settings_key_base
      openid_connect_signing_key: |
$(echo "${openid_connect_signing_key}" | awk '{print "        " $0}')
      active_record_encryption_primary_key:
        $active_record_encryption_primary_keys
      active_record_encryption_deterministic_key:
        $active_record_encryption_deterministic_keys
      active_record_encryption_key_derivation_salt: $active_record_encryption_key_derivation_salt
EOF
  kubectl --validate=false --namespace=$namespace apply -f rails-secrets.yml
  label_secret $rails_secret
fi

# Shell ssh host keys
ssh-keygen -A
mkdir -p host_keys
cp /etc/ssh/ssh_host_* host_keys/
generate_secret_if_needed {{ template "gitlab.gitlab-shell.hostKeys.secret" . }} --from-file host_keys

# Gitlab-workhorse secret
generate_secret_if_needed {{ template "gitlab.workhorse.secret" . }} --from-literal={{ template "gitlab.workhorse.key" . }}=$(gen_random 'a-zA-Z0-9' 32 | base64)

# Registry http.secret secret
generate_secret_if_needed {{ template "gitlab.registry.httpSecret.secret" . }} --from-literal={{ template "gitlab.registry.httpSecret.key" . }}=$(gen_random 'a-z0-9' 128 | base64 -w 0)

# Container Registry notification_secret
generate_secret_if_needed {{ template "gitlab.registry.notificationSecret.secret" . }} --from-literal={{ template "gitlab.registry.notificationSecret.key" . }}=[\"$(gen_random 'a-zA-Z0-9' 32)\"]

{{ if .Values.global.praefect.enabled -}}
{{   if not .Values.global.praefect.psql.host -}}
# Praefect DB password
generate_secret_if_needed {{ template "gitlab.praefect.dbSecret.secret" . }} --from-literal={{ template "gitlab.praefect.dbSecret.key" . }}=$(gen_random 'a-zA-Z0-9', 32)
{{   end }}

# Praefect auth token
generate_secret_if_needed {{ template "gitlab.praefect.authToken.secret" . }} --from-literal={{ template "gitlab.praefect.authToken.key" . }}=$(gen_random 'a-zA-Z0-9' 64)
{{ end }}

{{ if (index .Values "gitlab-zoekt" "gateway" "basicAuth" "enabled") -}}
# Zoekt basic auth credentials
generate_secret_if_needed {{ template "gitlab.zoekt.gateway.basicAuth.secretName" . }}  --from-literal=gitlab_username=gitlab --from-literal=gitlab_password=$(gen_random 'a-zA-Z0-9' 64)
{{ end }}
