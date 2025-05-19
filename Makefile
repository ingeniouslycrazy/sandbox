ifeq ($(OS),Windows_NT)
    SCRIPT_TYPE := "bat"
    DIRECTORY_SEPARATOR := "\\"
    SHOW_HELP :=type .$(DIRECTORY_SEPARATOR)readme.txt
else
    SCRIPT_TYPE := "sh"
    DIRECTORY_SEPARATOR := "/"
    SHOW_HELP :=cat .$(DIRECTORY_SEPARATOR)readme.txt
endif
SCRIPT_DIR := .$(DIRECTORY_SEPARATOR)scripts$(DIRECTORY_SEPARATOR)

all: help

## |Create and delete a cluster:

create: 		## Setup cluster
	@$(SCRIPT_DIR)create-cluster.$(SCRIPT_TYPE)
purge:		## Delete cluster
	@$(SCRIPT_DIR)purge-cluster.$(SCRIPT_TYPE)

## |Deploy services:

gitlab:		## Deploy Gitlab
	@.$(SCRIPT_DIR)deploy-gitlab.$(SCRIPT_TYPE)

## |Usage!
help:			## Show this help.
	@$(SHOW_HELP)
