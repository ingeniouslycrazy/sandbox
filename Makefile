ifeq ($(OS),Windows_NT)
    SCRIPT_TYPE := bat
    DIRECTORY_SEPARATOR := \\
    SHOW_HELP := type .\\readme.txt
else
    SCRIPT_TYPE := sh
    DIRECTORY_SEPARATOR := /
    SHOW_HELP := cat ./readme.txt
endif
SCRIPT_DIR := .$(DIRECTORY_SEPARATOR)scripts$(DIRECTORY_SEPARATOR)
SERVICE_DIR := .$(DIRECTORY_SEPARATOR)services$(DIRECTORY_SEPARATOR)

all: help

## |Create and delete a cluster:

create: 		## Setup cluster
	@$(SCRIPT_DIR)create-cluster.$(SCRIPT_TYPE)
	@$(SCRIPT_DIR)deploy-gitlab-operator.$(SCRIPT_TYPE)

purge:		## Delete cluster
	@$(SCRIPT_DIR)purge-cluster.$(SCRIPT_TYPE)

## |Deploy services:

demo:		## Deploy demo
	@kubectl apply -f $(SERVICE_DIR)demo.yml

gitlab:		## Deploy Gitlab
	@$(SCRIPT_DIR)deploy-gitlab.$(SCRIPT_TYPE)

## |Backup/restore:

create-backup:		## Create backup
	@$(SCRIPT_DIR)create-backup.$(SCRIPT_TYPE)

restore-backup:		## Restore backup
	@$(SCRIPT_DIR)restore-backup.$(SCRIPT_TYPE)

## |Usage!
help:			## Show this help.
	@$(SHOW_HELP)
