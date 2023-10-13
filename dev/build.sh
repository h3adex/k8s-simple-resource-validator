#!/bin/bash

if [ -n "$DEBUG" ]; then
	set -x
fi

set -o errexit
set -o nounset
set -o pipefail

export K8S_VERSION=${K8S_VERSION:-v1.26.3@sha256:61b92f38dff6ccc29969e7aa154d34e38b89443af1a2c14e6cfbd2df6419c66f}
export TAG=1.0.0-dev
DEV_IMAGE=k8s-simple-resource-validator:${TAG}
DEV_CLUSTER_NAME="k8s-dev"
DIR=$(cd $(dirname "${BASH_SOURCE}") && pwd -P)

if [ ! -f "bin/tls.crt" ]; then
  echo "The file 'tls.crt' does not exist. Please run 'make certs' to generate the certificates."
  exit 1
fi


if ! command -v kind &> /dev/null; then
  echo "kind is not installed"
  echo "Use a package manager (i.e 'brew install kind') or visit the official site https://kind.sigs.k8s.io"
  exit 1
fi

if ! command -v kubectl &> /dev/null; then
  echo "Please install kubectl 1.24.0 or higher"
  exit 1
fi

if ! command -v helm &> /dev/null; then
  echo "Please install helm"
  exit 1
fi

echo "[dev-env] building image ${DEV_IMAGE}"
echo "docker build -t ${DEV_IMAGE} ."
docker build -t "${DEV_IMAGE}" .

if ! kind get clusters -q | grep -q ${DEV_CLUSTER_NAME}; then
  echo "[dev-env] creating Kubernetes cluster with kind"
  kind create cluster --name ${DEV_CLUSTER_NAME} --image "kindest/node:${K8S_VERSION}" --config ${DIR}/kind.yaml
else
  echo "[dev-env] using existing Kubernetes kind cluster"
fi

if kubectl config get-contexts -o name | grep -q "${DEV_CLUSTER_NAME}"; then
    kubectl config use-context "kind-${DEV_CLUSTER_NAME}"
else
    echo "[dev-env] Unable to set kubectl config for the kind cluster"
    exit 1
fi

echo "[dev-env] copying docker images to cluster..."
kind load docker-image --name="${DEV_CLUSTER_NAME}" "${DEV_IMAGE}"

echo "[dev-env] Applying webhook secret"
if ! kubectl get secret k8s-simple-resource-validator-tls &> /dev/null; then
  kubectl create secret tls k8s-simple-resource-validator-tls \
      --cert "bin/tls.crt" \
      --key "bin/tls.key"
fi

echo "[dev-env] Applying svc"
if kubectl get svc k8s-simple-resource-validator &> /dev/null; then
    kubectl delete -f "dev/pod-service.yaml"
fi

kubectl create -f "dev/pod-service.yaml"

echo "[dev-env] Applying resource validator"
if ! kubectl get validatingwebhookconfigurations.admissionregistration.k8s.io k8s-simple-resource-validator &> /dev/null; then
    ENCODED_CA=$(cat bin/tls.crt | base64 | tr -d '\n')
    sed -e 's@${ENCODED_CA}@'"$ENCODED_CA"'@g' < "dev/resource-validator.yaml" | kubectl create -f -
fi


echo "Kubernetes cluster ready and ingress listening on localhost using ports 80 and 443"
echo "To delete the dev cluster, execute: 'kind delete cluster --name kind-k8s-dev'"