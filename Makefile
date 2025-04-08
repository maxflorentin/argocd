## ArgoCD local

This project will run argocd locally in a kubernetes cluster of your choice,
remember to set the correct kubernetes context before run the commands.

If you have any doubts open Makefile or type on shell `make help`.


Create a .env with

```
GIT_USER=yourgithubuser
GIT_PAT_TOKEN=ghp_yourgithubpattoken
CLUSTER_CONTEXT=kind
```

**Makefile options**
```
help: Show this helper
install-argocd-cli: Install argocd cli in your machine it will require sudo privilegies.
install-argocd: Install argocd in your cluster.
argocd-passwd: Get argocd service user and password:
argocd-portforward: Does a portforward in kind k8s cluster to expose argocd webui and api.
argocd-cli: Configure the argocd cli make login etc it depends of the port-forward.
argocd-repo-add: Add a datahub repo passed as a variable.
kill-portforward: kill all existing portforward from your k8s app to your machine
```

## Using it

After install the cli and install argocd on your cluster, see make options to do it.

Configure argocd cli using `make argocd-cli`.

To add the repository of our charts: `make argocd-repo-add GIT_REPO=https://github.com/my-awesome-repo/my-awesome-app.git `

To install an app:

**datahub**: `argocd app create -f dev/my-awesome-app.yaml`

Remember to create a branch or a repo to have your chart because locally AWS image cache won't work and other stuff like storageClass as `GP3` not work too.
