# KubeOne + OIDC Authentication + AuditLog Example

This repository contains example configuration and scripts to setup a
Kubernetes cluster using KubeOne, with OIDC for the cluster authentication
(backed by GitHub) and Audit Logging enabled.

The `deploy.sh` script will deploy infrastructure with terraform and install and configure the Kubernetes cluster with Kubeone.
Before running the script, please adapt the content of the following files according to your needs:

* terraform/terraform.tfvars
* kubeone.yaml
* values.yaml
* manifests/clusterIusser.yaml
* manifests/rbac.yaml

To run the script, you must set your Hetzner:

```bash
$ export HCLOUD_TOKEN='your Hetzner Cloud token'
$ ./deploy.sh
```

