# Homelab Setup Plan (Argo CD, Vault, PostgreSQL)

This document outlines the plan for setting up a local homelab environment on a MacBook using Docker Desktop Kubernetes, Argo CD for GitOps, HashiCorp Vault for secrets management, and Rancher Local Path Provisioner for storage. The first application to be deployed will be PostgreSQL.

**Phase 1: Foundational Setup**

1.  **Directory Structure:** Create the necessary directories within the `homelab` project.
    ```
    homelab/
    ├── .git/           # (Will be created in step 2)
    ├── infrastructure/
    │   ├── storage/    # Rancher Local Path Provisioner config
    │   ├── secrets/    # Vault & External Secrets Operator configs
    │   └── gitops/     # Argo CD config
    ├── applications/
    │   ├── base/       # Base Helm chart values/configs for apps
    │   └── argo-apps/  # Argo CD Application definitions (App-of-Apps)
    ├── monitoring/     # Future monitoring stack configs
    ├── scripts/        # Automation scripts
    └── docs/           # Documentation (like this file)
    ```

2.  **Git Initialization:** Initialize a Git repository in the `/Users/devrishidas/homelab` directory to track all configurations.

**Phase 2: Core Infrastructure Deployment (via GitOps)**

3.  **Local Storage:** Install Rancher's Local Path Provisioner using its manifest or Helm chart. Configuration will live in `infrastructure/storage/`.
4.  **Vault:** Deploy HashiCorp Vault (using Helm, into a `vault` namespace). Configuration (Helm values) will live in `infrastructure/secrets/vault/`.
    *   *Manual Steps Required:* Initializing, unsealing, and configuring Vault (Kubernetes auth, secrets engine) needs to be done manually outside the GitOps flow initially. Unseal keys/root token must be stored securely *outside* the repository.
5.  **External Secrets Operator (ESO):** Deploy ESO (using Helm, into `external-secrets` namespace). Configuration (Helm values, `ClusterSecretStore`) will live in `infrastructure/secrets/external-secrets-operator/`.
6.  **Argo CD:** Deploy Argo CD (using Helm, into `argocd` namespace). Configuration (Helm values) will live in `infrastructure/gitops/argocd/`.
    *   *Manual Steps Required:* Initial login, potentially configuring the repository connection.
7.  **App of Apps Setup:** Configure Argo CD to manage itself and other applications using the "App of Apps" pattern. A root `Application` manifest will point to the `applications/argo-apps/` directory.

**Phase 3: First Application Deployment (PostgreSQL)**

8.  **PostgreSQL Configuration:**
    *   Define PostgreSQL deployment using the Bitnami Helm chart. Configuration (Helm values) will live in `applications/base/postgres/`.
    *   *Manual Step Required:* Store the desired PostgreSQL admin password securely in Vault (e.g., at `secret/postgres/admin`).
    *   Create an `ExternalSecret` manifest in `applications/base/postgres/` to tell ESO how to fetch the password from Vault and create a corresponding Kubernetes `Secret`.
    *   Configure the PostgreSQL Helm values to use the `Secret` created by ESO and the `local-path` StorageClass for persistence.
9.  **Argo CD Application for PostgreSQL:** Create an Argo CD `Application` manifest in `applications/argo-apps/` that tells Argo CD to deploy PostgreSQL using the configurations defined in `applications/base/postgres/`.
10. **Commit & Sync:** Commit all configuration manifests to Git. Argo CD will detect the changes and automatically deploy/configure the components (Local Path Provisioner, Vault placeholders, ESO, Argo CD apps, PostgreSQL).

**Visual Overview:**

```mermaid
graph TD
    subgraph User Machine (MacBook)
        A[Git Repo: /Users/devrishidas/homelab]
    end

    subgraph Docker Desktop Kubernetes Cluster
        subgraph argocd ns
            B[Argo CD]
        end
        subgraph vault ns
            C[Vault Server]
        end
        subgraph external-secrets ns
            D[External Secrets Operator]
        end
        subgraph databases ns  // Example namespace for Postgres
            E[PostgreSQL Pod] --> F[PersistentVolumeClaim];
            G[Kubernetes Secret (from ESO)];
        end
        subgraph kube-system ns // Or where Local Path Provisioner runs
            H[Local Path Provisioner]
        end
        F --> H; // PVC uses storage provisioned by Local Path
        E --> G; // Postgres uses Secret managed by ESO
    end

    A -- Manages --> B; // Git repo is source for Argo CD
    B -- Syncs Manifests --> C; // Argo deploys Vault (via Helm chart defined in Git)
    B -- Syncs Manifests --> D; // Argo deploys ESO (via Helm chart defined in Git)
    B -- Syncs Manifests --> E; // Argo deploys Postgres (via Helm chart defined in Git)
    B -- Syncs Manifests --> H; // Argo deploys Local Path Provisioner (via manifests/chart in Git)
    B -- Reads --> A; // Argo monitors Git repo for changes
    D -- Reads ExternalSecret Def --> A; // ESO gets instructions from Git (via Argo)
    D -- Authenticates & Reads --> C; // ESO fetches secrets from Vault
    D -- Writes --> G; // ESO creates K8s Secret
    C -- Stores Secrets --> VaultStorage[(Vault Backend Storage)]; // Vault persistence