SHELL := /bin/bash
ROOT_DIR := $(shell pwd)

# Set default variables from .env file if exists
ifneq (,$(wildcard ./.env))
    include .env
    export
    ENV_FILE_PARAM = --env-file .env
endif

# Default variables
APP_VERSION := 5.4.3

ifeq ($(strip $(CLUSTER_CONTEXT)),)
  CLUSTER_CONTEXT := "kind"
endif

# Help
help: ## Show this helper.
	@echo "Available commands:"
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'


# Install ArgoCD CLI
## install-argocd-cli: Install ArgoCD CLI for Mac
install-argocd-cli:
	bash -c "curl -sSL -o argocd-darwin-arm64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-darwin-arm64 \
	&& sudo install -m 555 argocd-darwin-arm64 /usr/local/bin/argocd \
	&& rm argocd-darwin-arm64"

# Install ArgoCD in the cluster
## install-argocd: Install ArgoCD in the cluster
install-argocd:
	helm install argocd oci://registry-1.docker.io/bitnamicharts/argo-cd --version $(APP_VERSION) --namespace argocd --create-namespace
	@sleep 5
	kubectl -n argocd patch svc argocd-argo-cd-server -p '{"spec": {"type": "LoadBalancer"}}'

# Get ArgoCD admin credentials
## argocd-passwd: Get ArgoCD admin credentials
argocd-passwd:
	@echo "Argo CD URL: http://127.0.0.1:38080/"
	@echo "Username: admin Password: $(shell kubectl -n argocd get secret argocd-secret -o jsonpath="{.data.clearPassword}" | base64 -d)"
	@echo "Remember to copy the password."

# Port-forward ArgoCD UI
## argocd-portforward: Port-forward ArgoCD web UI and API
argocd-portforward: argocd-passwd
	@echo "---------------------------------------------------------------------------------------|"
	@kubectl port-forward --namespace argocd svc/argocd-argo-cd-server 38080:80 &
	@kubectl port-forward --namespace argocd svc/argocd-argo-cd-server 30443:443 &
	@echo "Your terminal will show port-forward logs. Press ENTER to recover control."

# Configure ArgoCD CLI
## argocd-cli: Configure ArgoCD CLI
argocd-cli:
	argocd login 127.0.0.1:30443 --username admin --password $(shell kubectl -n argocd get secret argocd-secret -o jsonpath="{.data.clearPassword}" | base64 -d)

# Deploy and forward app
## deploy-app: Deploy and forward an app using a provided .env file.
deploy-app:
	@ENV_FILE=$(ENV_FILE); \
	if [ -f $$ENV_FILE ]; then \
		echo "Using environment file: $$ENV_FILE"; \
		source $$ENV_FILE && \
		helm upgrade --install $$APP $$APP_REPO \
			--version $$APP_VERSION \
			--namespace $$NAMESPACE --create-namespace; \
		sleep 5; \
		kubectl -n $$NAMESPACE patch svc $$SERVICE_NAME -p '{"spec": {"type": "LoadBalancer"}}'; \
	else \
		echo "Environment file $$ENV_FILE not found!"; \
		exit 1; \
	fi

# Port-forward the application
## app-portforward: Port-forward application for local access
app-portforward:
	@[ -f $(ENV_FILE) ] || { echo "Environment file $(ENV_FILE) not found!"; exit 1; }
	@source $(ENV_FILE); \
	echo "---------------------------------------------------------------------------------------|"; \
	kubectl port-forward --namespace $${NAMESPACE} svc/$${SERVICE_NAME} $${APP_PORT}:80 &
	@kubectl port-forward --namespace $${NAMESPACE} svc/$${SERVICE_NAME} $${APP_S_PORT}:443 &
	@echo "Your terminal will show port-forward logs. Press ENTER to recover control."

# Add a repository to ArgoCD
## argocd-repo-add: Add a Git repository to ArgoCD
argocd-repo-add:
	@[ -f $(ENV_FILE) ] || { echo "Environment file $(ENV_FILE) not found!"; exit 1; }

# Kill all port-forward processes
## kill-portforward: Kill all port-forward processes
kill-portforward:
	@echo "Killing all kubectl port-forward processes..."
	@pkill -f 'kubectl port-forward' || echo "No port-forward processes found."
	@echo "All port-forward processes terminated."
