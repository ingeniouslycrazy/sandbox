all: help

## |Create and delete a cluster:

create: 		## Setup cluster
	@./bin/create-cluster.sh
purge:		## Delete cluster
	@./bin/purge-cluster.sh

## |Build:

gitlab:		## Deploy Gitlab
	@./bin/deploy-gitlab.sh

## |Usage!
help:			## Show this help.
	@echo "Usage: make OPTION\n"
	@echo "Options:"
	@sed -ne '/@sed/!s/## //p' $(MAKEFILE_LIST) | awk '{sub(":","");print}' | tr '|' '\n' | tr '!' ':'
	@echo
