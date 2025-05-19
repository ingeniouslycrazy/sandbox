ifeq ($(OS),Windows_NT)
    SCRIPT_FT := "bat"
else
    SCRIPT_FT := "sh"
endif

all: help

## |Create and delete a cluster:

create: 		## Setup cluster
	@./scripts/create-cluster.$(SCRIPT_FT)
purge:		## Delete cluster
	@./scripts/purge-cluster.$(SCRIPT_FT)

## |Deploy services:

gitlab:		## Deploy Gitlab
	@./scripts/deploy-gitlab.$(SCRIPT_FT)

## |Usage!
help:			## Show this help.
	@cat readme.txt
