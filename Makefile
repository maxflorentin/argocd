SHELL := /bin/bash
ROOT_DIR := $(shell pwd)

# Default variables from .env if it exists
ifneq (,$(wildcard ./.env))
    include .env
    export
    ENV_FILE_PARAM = --env-file .env
endif

# Default cluster context
ifeq ($(strip $(CLUSTER_CONTEXT)),)
  CLUSTER_CONTEXT := "rancher-desktop"
endif

# Tool versions
ARGOC_D_VERSION := 5.4.3
ARGOC_D_CLI_URL := "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-darwin-arm64"

# Check if required tools are installed
check-tools:
	@command -v kubectl >/dev/null 2>&1 || { echo "kubectl is not installed"; exit 1; }
	@command -v helm >/dev/null 2>&1 || { echo "helm is not installed"; exit 1; }
	@command -v argocd >/dev/null 2>&1 || { echo "argocd CLI is not installed"; exit 1; }

help: ## Show this helper.
	@echo "Available commands:"
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

## install-argocd-cli: Install Argo CD CLI for macOS.
install-argocd-cli:
	bash -c "curl -sSL -o argocd-darwin-arm64 $(ARGOC_D_CLI_URL) \
	&& sudo install -m 555 argocd-darwin-arm64 /usr/local/bin/argocd \
	&& rm argocd-darwin-arm64"

## install-argocd: Install Argo CD in Kubernetes cluster.
install-argocd: check-tools
	helm install argocd oci://registry-1.docker.io/bitnamicharts/argo-cd \
		--version $(ARGOC_D_VERSION) --namespace $(NAMESPACE) --create-namespace
	@sleep 5
	kubectl -n $(NAMESPACE) patch svc argocd-argo-cd-server -p '{"spec": {"type": "LoadBalancer"}}'

## argocd-passwd: Get Argo CD admin credentials.
argocd-passwd: check-tools
	@kubectl -n argocd get secret argocd-secret >/dev/null 2>&1 || { echo "Argo CD is not installed"; exit 1; }
	@echo "Argo CD URL: http://127.0.0.1:$(ARGOCD_PORT)/"
	@echo "Username: admin"
	@echo "Password: $(shell kubectl -n \$(NAMESPACE) get secret argocd-secret -o jsonpath="{.data.clearPassword}" | base64 -d)"

## argocd-portforward: Port-forward Argo CD server for local access.
argocd-portforward: check-tools argocd-passwd
	@echo "---------------------------------------------------------------------------------------|"
	@kubectl port-forward --namespace $(NAMESPACE) svc/argocd-argo-cd-server $(ARGCD_PORT):80 &
	@kubectl port-forward --namespace $(NAMESPACE) svc/argocd-argo-cd-server $(ARGOCD_S_PORT):443 &
	@echo "Your terminal will show port-forward logs. Press ENTER to recover control."

## argocd-cli: Login to Argo CD CLI.
argocd-cli: check-tools
	@argocd login 127.0.0.1:$(ARGOCD_S_PORT) --username admin --password $(shell kubectl -n \$(NAMESPACE) get secret argocd-secret -o jsonpath="{.data.clearPassword}" | base64 -d)

## argocd-repo-add: Add a Git repository to Argo CD.
argocd-repo-add: check-tools
	@argocd account get-user-info >/dev/null 2>&1 || { echo "Not logged in to Argo CD, run 'make argocd-cli' first!"; exit 1; }
	@[[ -n "$(GIT_REPO)" && -n "$(GIT_USER)" && -n "$(GIT_PAT_TOKEN)" ]] || { echo "Missing variables: GIT_REPO, GIT_USER, or GIT_PAT_TOKEN"; exit 1; }
	argocd repo add $(GIT_REPO) --username $(GIT_USER) --password $(GIT_PAT_TOKEN)

## kill-portforward: Kill all port-forward processes.
kill-portforward:
	@echo "Killing all kubectl port-forward processes..."
	@pkill -f 'kubectl port-forward' || echo "No port-forward processes found."
	@echo "All port-forward processes terminated."
