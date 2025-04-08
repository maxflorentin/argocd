SHELL := /bin/bash
ROOT_DIR:=$(shell pwd)

# set default variables from .env file if exist.
ifneq (,$(wildcard ./.env))
    include .env
    export
    ENV_FILE_PARAM = --env-file .env
endif

ifeq ($(strip $(CLUSTER_CONTEXT)),)
  CLUSTER_CONTEXT := "rancher-desktop"
endif

help: ## Show this helper.
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

## install-argocd-cli: Install argocd cli for Mac
install-argocd-cli:
	bash -c  "curl -sSL -o argocd-darwin-arm64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-darwin-arm64 \
	&& sudo install -m 555 argocd-darwin-arm64 /usr/local/bin/argocd \
	&& rm argocd-darwin-arm64"


## install-argocd: Install argocd in kind cluster.
install-argocd:
	helm install argocd oci://registry-1.docker.io/bitnamicharts/argo-cd --version 5.4.3 --namespace argocd --create-namespace
	@sleep 5
	kubectl -n argocd patch svc argocd-argo-cd-server  -p '{"spec": {"type": "LoadBalancer"}}'

## argocd-passwd: Get argocd service user and password:
argocd-passwd:
	@echo "Argo CD URL: http://127.0.0.1:38080/"
	@echo "Username: admin Password: $(shell kubectl -n argocd get secret argocd-secret -o jsonpath="{.data.clearPassword}" | base64 -d)"
	@echo "Remember to copy the password."

## argocd-portforward: Does a portforward in kind k8s cluster to expose argocd webui and api.
argocd-portforward:: argocd-passwd
	@echo "---------------------------------------------------------------------------------------|"
	@kubectl port-forward --namespace argocd svc/argocd-argo-cd-server 38080:80 &
	@kubectl port-forward --namespace argocd svc/argocd-argo-cd-server -n argocd 30443:443 &
	@echo "Your terminal will show logs from portforward press ENTER to recover it everytime you need."

## argocd-cli: Configure the argocd cli make login etc it depends of the port-forward.
argocd-cli:
	argocd login 127.0.0.1:30443 --username admin --password $(shell kubectl -n argocd get secret argocd-secret -o jsonpath="{.data.clearPassword}" | base64 -d)

## argocd-repo-add: Add a datahub repo passed as a variable.
argocd-repo-add:
	argocd repo add $(GIT_REPO) --username $(GIT_USER) --password $(GIT_PAT_TOKEN)

## kill-portforward: kill all port forward
kill-portforward:
	@echo "Killing all kubectl port-forward processes..."
	$(shell pkill -f 'kubectl port-forward')
	@echo "All port-forward processes terminated."
