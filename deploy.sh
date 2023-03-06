#!/usr/bin/env bash

set -euo pipefail
cd $(dirname $0)

set +o nounset
if [[ -z "${HCLOUD_TOKEN}" ]]; then
    echo "Hetzner credentials are empty. Please export HCLOUD_TOKEN environment variable before running the script.."
fi
set -o nounset

echo "creating infrastructure ..."
cd terraform
terraform init
terraform apply -auto-approve
terraform output -json > ../output.json
cd ..

lb_ip="$(jq -r '.kubeone_api.value.endpoint' output.json)"

echo -e "Before continuing, setup DNS records for the created LoadBalancer. Otherwise, KubeOne will fail to setup the controlplane.
LoadBalancer IP: ${lb_ip}

Once the DNS record is created, Press any key to continue..."

#read only 1 char (-n1) and don't print it (-s)
read -n1 -s

echo "creating kubernetes cluster with kubeone"
# (--force-upgrade is required whenever KubeOne features are changed)
kubeone apply --manifest kubeone.yaml --tfjson output.json --force-upgrade

 KubeOne automatically created a kubeconfig named after the cluster name.
export KUBECONFIG=$(realpath example-kubeconfig)

echo "get Helm charts from Kubermatic"
KKP_VERSION=v2.22.0
wget "https://github.com/kubermatic/kubermatic/releases/download/${KKP_VERSION}/kubermatic-ce-${KKP_VERSION}-linux-amd64.tar.gz"
tar xzf "kubermatic-ce-${KKP_VERSION}-linux-amd64.tar.gz" charts && rm "kubermatic-ce-${KKP_VERSION}-linux-amd64.tar.gz"

echo "setup nginx-ingress-controller (needs Helm 3.x)"
helm dependency build ./charts/nginx-ingress-controller
helm --namespace nginx-ingress-controller upgrade --create-namespace --install --values values.yaml nginx-ingress-controller ./charts/nginx-ingress-controller/

echo "Hetzner-specific (change the location to your datacenter, or remove this altogether if you're not using Hetzner)"
kubectl --namespace nginx-ingress-controller annotate --overwrite service nginx-ingress-controller "load-balancer.hetzner.cloud/location=nbg1"


echo -e "Before continuing, setup the DNS record for the nginx-ingress-controller's LoadBalancer.
This is the LB that will handle (among others, possibly) the traffic for Dex.

Once the DNS record is created, Press any key to continue..."

#read only 1 char (-n1) and don't print it (-s)
read -n1 -s


echo "install cert-manager"
kubectl apply --filename charts/cert-manager/crd/
helm dependency build ./charts/cert-manager/
helm --namespace cert-manager upgrade --create-namespace --install --values values.yaml --wait cert-manager ./charts/cert-manager/

echo "install clusterIssuer"
kubectl apply -f manifests/clusterIusser.yaml

echo "install Dex"
helm --namespace kube-system upgrade --create-namespace --install --values values.yaml --wait dex ./charts/oauth/

echo "setup permissions"
kubectl apply --filename manifests/rbac.yaml

