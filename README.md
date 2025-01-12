# Argo CD Makefile

This project includes a Makefile to automate tasks related to installing, configuring, and using Argo CD in a Kubernetes cluster.

## Prerequisites

1. **Installed Tools:**

   - `kubectl`
   - `helm`
   - `bash`
   - Administrative access to the Kubernetes cluster.

2. **Initial Setup:**
   - Ensure you have a `.env` file in the root directory of the project. This file should contain the necessary environment variables (see **Example `.env`** below).

## `.env` File Configuration

Example `.env` file:

```dotenv
# Kubernetes cluster context
CLUSTER_CONTEXT=rancher-desktop

# Configuration for Argo CD repo-add
GIT_REPO=https://github.com/my-org/my-repo
GIT_USER=my-user
GIT_PAT_TOKEN=my-pat-token

# Additional options
NAMESPACE=argocd
```

## Available Commands

Run `make help` to list all available commands.

### Main Commands

#### 1. **`make install-argocd-cli`**

Installs the Argo CD CLI for macOS.

```bash
make install-argocd-cli
```

#### 2. **`make install-argocd`**

Installs Argo CD in the Kubernetes cluster using Helm.

```bash
make install-argocd
```

#### 3. **`make argocd-passwd`**

Displays the Argo CD URL, username, and password.

```bash
make argocd-passwd
```

#### 4. **`make argocd-portforward`**

Performs a port-forward to expose the Argo CD web UI and API locally.

```bash
make argocd-portforward
```

#### 5. **`make argocd-cli`**

Configures the Argo CD CLI to connect to the local server.

```bash
make argocd-cli
```

#### 6. **`make argocd-repo-add`**

Adds a Git repository to Argo CD. Requires `GIT_REPO`, `GIT_USER`, and `GIT_PAT_TOKEN` to be defined in the `.env` file.

```bash
make argocd-repo-add
```

#### 7. **`make kill-portforward`**

Terminates all port-forwarding processes.

```bash
make kill-portforward
```

## Full Usage Example

1. Install the Argo CD CLI:

   ```bash
   make install-argocd-cli
   ```

2. Install Argo CD in the cluster:

   ```bash
   make install-argocd
   ```

3. Retrieve the login credentials:

   ```bash
   make argocd-passwd
   ```

4. Start a port-forward to access the web UI:

   ```bash
   make argocd-portforward
   ```

5. Configure the Argo CD CLI:

   ```bash
   make argocd-cli
   ```

6. Add a Git repository to Argo CD:

   ```bash
   make argocd-repo-add
   ```

7. When finished, terminate the port-forwarding processes:
   ```bash
   make kill-portforward
   ```

## Additional Notes

- This Makefile is designed for macOS systems with ARM64 processors.
- You can extend or modify the `.env` file to customize the configuration according to your needs.
- Ensure you have the appropriate permissions in the Kubernetes cluster before running these commands.
