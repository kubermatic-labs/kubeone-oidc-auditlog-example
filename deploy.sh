#!/usr/bin/env bash

set -euo pipefail
cd $(dirname $0)

# set Hetzner Cloud API token
export HCLOUD_TOKEN=....

# create infrastructure
cd terraform
terraform apply -auto-approve
terraform output -json > ../output.json
cd ..

# Before continuing, setup DNS records for the created LoadBalancer.
# Otherwise, KubeOne will fail to setup the controlplane.

# setup cluster
# (--force-upgrade is required whenever KubeOne features are changed)
kubeone apply --manifest kubeone.yaml --tfjson output.json --force-upgrade

# KubeOne automatically created a kubeconfig named after the cluster name.
export KUBECONFIG=$(realpath example-kubeconfig)

# get Helm charts from Kubermatic
KKP_VERSION=v2.15.5
wget "https://github.com/kubermatic/kubermatic/releases/download/${KKP_VERSION}/kubermatic-ce-${KKP_VERSION}-linux-amd64.tar.gz"
tar xzf "kubermatic-ce-${KKP_VERSION}-linux-amd64.tar.gz" && rm "kubermatic-ce-${KKP_VERSION}-linux-amd64.tar.gz"

# setup nginx-ingress-controller (needs Helm 3.x)
helm --namespace nginx-ingress-controller upgrade --create-namespace --install --values values.yaml nginx-ingress-controller ./charts/nginx-ingress-controller/

# Hetzner-specific (change the location to your datacenter, or remove this alltogether if you're not using Hetzner)
kubectl --namespace nginx-ingress-controller annotate --overwrite service nginx-ingress-controller "load-balancer.hetzner.cloud/location=nbg1"

# Before continuing, setup the DNS record for the nginx-ingress-controller's LoadBalancer.
# This is the LB that will handle (among others, possibly) the traffic for Dex.

# setup cert-manager
kubectl apply --filename charts/cert-manager/crd/
helm --namespace cert-manager upgrade --create-namespace --install --values values.yaml cert-manager ./charts/cert-manager/

# finally install Dex
helm --namespace kube-system upgrade --create-namespace --install --values values.yaml dex ./charts/oauth/

# setup permissions
kubectl apply --filename manifests/rbac.yaml
