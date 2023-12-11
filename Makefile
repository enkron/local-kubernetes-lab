CLUSTER_ENV?=local
SERVICES=

ifeq (,$(filter $(CLUSTER_ENV),local cloud))
$(error Bad environment argument "$(CLUSTER_ENV)". Possible values: [local, cloud])
endif

all: cluster

.PHONY: cluster
cluster:
ifeq ($(CLUSTER_ENV),local)
	@./create-vm.sh $(SERVICES)
endif

clean:
	@./destroy-vm.sh

help:
	@echo 'To build local cluster with a few VMs use the default target.'
	@echo
	@echo 'make SERVICES="master01 worker01"'

usage:
	@echo 'build cluster:'
	@echo 'cluster CLUSTER_ENV=[local|cloud]	Create cluster'
	@echo 'clean	Cleanup workspace from build files and destroy cluster env'
	@echo
