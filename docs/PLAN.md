# Homelab Foundation Setup Plan

This document outlines the plan for establishing the initial foundation for the homelab environment running on a local k3d cluster.

**Core Technologies:**

*   **Cluster:** k3d (Kubernetes)
*   **Storage:** Rancher Local Path Provisioner
*   **Ingress:** Traefik Proxy
*   **GitOps:** Argo CD
*   **Monitoring:** Prometheus Stack (Prometheus, Grafana, Alertmanager)

**Plan Steps:**

1.  **Refine Base Infrastructure Configuration:**
    *   **k3d Cluster:** Pin the k3s image version in `infrastructure/k3d/cluster.yaml` to a specific stable release (e.g., `image: rancher/k3s:v1.28.5-k3s1`) for consistency.
    *   **Local Storage:** Keep the `local-path-provisioner` storage path within the project directory (`infrastructure/storage/local-path-provisioner/`) for now, as defined in `infrastructure/storage/local-path-provisioner/local-path-storage.yaml`. *(Optional future steps: update the provisioner image version, consider `reclaimPolicy: Retain`)*.
    *   **Ingress:** Install and configure **Traefik Proxy** as the Ingress controller. Manage its configuration via GitOps.

2.  **Configure GitOps Workflow (using existing ArgoCD):**
    *   Create ArgoCD `Application` manifests (suggested location: `infrastructure/argocd/apps/`) to manage:
        *   Core infrastructure (local-path-provisioner, Traefik).
        *   Monitoring stack (Prometheus, Grafana).
        *   Future applications.
    *   These manifests will instruct ArgoCD to monitor specific paths in the Git repository (`infrastructure/`, `monitoring/`, `applications/`) and apply the configurations to the cluster.

3.  **Deploy Core Services via GitOps:**
    *   Commit the refined `local-path-provisioner` manifests to Git.
    *   Add the manifests/Helm chart values for Traefik to the repository (suggested location: `infrastructure/networking/traefik/`).
    *   Add the manifests/Helm chart values for the Prometheus stack to the repository (`monitoring/prometheus-stack/`).
    *   Apply the ArgoCD `Application` manifests to the cluster (can be done manually once, or via a script). ArgoCD will then take over deploying and managing these components based on the Git repository state.

4.  **Structure Application Deployments:**
    *   Utilize `applications/base/` for common application manifests.
    *   Leverage Kustomize in `applications/overlays/` if environment-specific tweaks are needed later.
    *   Deploy applications by adding their manifests to the repository and potentially creating corresponding ArgoCD `Application` resources.

5.  **Documentation & Scripts:**
    *   Update `README.md` to reflect the architecture (k3d, local-path, Traefik, ArgoCD), setup steps, and access details (ArgoCD UI, Traefik Dashboard if exposed).
    *   Refine existing scripts (`scripts/`) to focus on initial cluster creation (`setup-cluster.sh`) and potentially the initial ArgoCD `Application` bootstrapping, leaving ongoing management to GitOps.

**Diagrammatic Overview:**

```mermaid
graph TD
    subgraph Host Machine (Macbook)
        PV_Data[homelab/infrastructure/storage/...]
    end

    subgraph k3d Cluster (Kubernetes)
        subgraph Namespace: kube-system
            CoreDNS
            MetricsServer
            KubeProxy
        end
        subgraph Namespace: local-path-storage
            LP_Provisioner[Local Path Provisioner] --> PV_Data
        end
        subgraph Namespace: traefik
            TraefikProxy[Traefik Proxy Ingress] --> ServiceA
            TraefikProxy --> ServiceB
        end
        subgraph Namespace: argocd
            ArgoCD[Argo CD Server]
        end
        subgraph Namespace: monitoring
            Prometheus[Prometheus]
            Grafana[Grafana]
            Alertmanager[Alertmanager]
        end
        subgraph Namespace: app-namespace
            AppPod[Application Pod] --> PVC
            ServiceA[App Service]
        end
        PVC -- Bound by LP_Provisioner --> PV[Persistent Volume]
    end

    subgraph Git Repository (GitHub/GitLab/etc.)
        Repo[/homelab]
        Repo -- Manages --> K8s_Infra[Infrastructure Manifests (Storage, Traefik)]
        Repo -- Manages --> K8s_Apps[Application Manifests]
        Repo -- Manages --> K8s_Monitor[Monitoring Manifests]
        Repo -- Manages --> Argo_Apps[ArgoCD Application Manifests]
    end

    ArgoCD -- Watches --> Repo
    ArgoCD -- Applies Config --> k3d_Cluster

    style PV_Data fill:#f9f,stroke:#333,stroke-width:2px