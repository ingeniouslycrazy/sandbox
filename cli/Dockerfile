# Multi Stage Build

# Stage git -> cloning resources with git
FROM alpine/git:v2.47.2 AS git

RUN git clone https://github.com/ahmetb/kubectx /srv/kubectx

# Final Stage 
FROM alpine:3.21.3

COPY --from=git /srv/kubectx/kubectx /usr/local/bin/kubectx
COPY --from=git /srv/kubectx/kubens /usr/local/bin/kubens

RUN apk add --no-cache \
    kubectl \
    zsh