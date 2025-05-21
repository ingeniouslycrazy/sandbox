# Sandbox

A dockerized k8s sandbox. Features:

- Nginx-Ingress
- Cert-Manager
- Gitlab

## Usage

Run `make create` to create the cluster. Afterwards you can run `make demo` to deploy a demo or `make gitlab` to deploy Gitlab into the sandbox.

Once you deployed the demo or Gitlab, you should create backups of the TLS certificates. When you purge and re-create the server, you can restore these TLS certificates and won't have to generate new certificates.
Run `make backup` to create the backup.

If you purge and re-create the sandbox and wish to use the backup, first run `make create` and then run `make restore` 
## Operations

### Deploy

1. Run `make create` to create the cluster.
2. Run `make gitlab` to deploy a Gitlab installation.

### Backup & Restore

To reuse TLS resources, we need a way for them to persist between purging and creating clusters.

To backup TLS certicates, run `make create-backup`.

To restore backups of these TLS certicates, run `make restore-backup`.

### Purge

Run `make purge` to delete the cluster. This removes EVERYTHING!
