# GitOps Strategy for Homelab

This document outlines the GitOps strategy adopted for managing the homelab Kubernetes cluster and its applications.

## Goal

The primary goal is to use Git as the single source of truth for the desired state of the entire homelab infrastructure and applications running on Kubernetes. This approach aims to improve:

*   **Maintainability:** Configuration is version-controlled, auditable, and easily reproducible.
*   **Modularity:** Components are defined independently and managed declaratively.
*   **Upgradability:** Updates are applied by changing configurations in Git, triggering automated deployments.
*   **Consistency:** Ensures the running state matches the declared state in Git.

## Chosen Tool: Argo CD

Argo CD will be used as the GitOps controller. It continuously monitors the Git repository and the live state of the Kubernetes cluster, reconciling any differences.

## Implementation Approach

1.  **Repository Structure:** The existing repository structure is well-suited for GitOps:
    *   `infrastructure/`: Contains manifests for core infrastructure components (Argo CD itself, storage, networking, etc.).
    *   `applications/`: Contains application definitions, potentially using Kustomize overlays or Helm charts.
    *   `monitoring/`: Contains configurations for the monitoring stack.

2.  **Bootstrapping Argo CD:**
    *   Argo CD itself needs an initial manual installation onto the cluster using its official Helm chart.
    *   The configuration for the Helm chart will be stored in `infrastructure/argocd/values.yaml`.
    *   The Helm chart will be installed once manually using `helm upgrade --install` commands, specifying the release name, namespace, and values file.

3.  **Declarative Management:**
    *   Once bootstrapped, Argo CD will manage all subsequent deployments.
    *   Argo CD `Application` resources (stored in Git, likely within the `infrastructure/argocd/` directory or a dedicated `argocd-apps/` directory) will define:
        *   The source Git repository and path containing the manifests/charts.
        *   The target Kubernetes cluster and namespace.
        *   Deployment parameters (e.g., Helm values).

4.  **App-of-Apps Pattern:**
    *   An "App-of-Apps" pattern will likely be implemented. A root Argo CD `Application` will manage other `Application` resources, which in turn manage specific components (e.g., monitoring, ingress, individual user applications). This provides centralized control over all managed components.

5.  **Refactoring Existing Setups:**
    *   The imperative setup scripts (`setup-argocd.sh`, `setup-monitoring.sh`) will be replaced by declarative Argo CD `Application` definitions.
    *   Components like the `local-path-provisioner` and the monitoring stack (`kube-prometheus-stack`) will be managed via Argo CD Applications pointing to their respective manifests/charts in the repository.
    *   The `setup-cluster.sh` script might be kept *only* for the initial `k3d cluster create` command, or this step will be documented separately.

## Next Steps

*   Create the Helm `values.yaml` in `infrastructure/argocd/` for bootstrapping Argo CD.
*   Manually install Argo CD onto the cluster using `helm upgrade --install`.
*   Configure Argo CD (e.g., access, potentially setting up the App-of-Apps).
*   Define Argo CD `Application` resources for existing components (local-path-provisioner, monitoring).
*   Choose and configure an Ingress controller via an Argo CD `Application`.
