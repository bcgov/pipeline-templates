#!/bin/bash

set -o errexit
set -o pipefail
set -o allexport; source .env; set +o allexport

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function sync(){
    wget https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml -O ${DIR}/base/install/pipelines.yaml
    wget https://storage.googleapis.com/tekton-releases/triggers/previous/v0.16.1/release.yaml -O ${DIR}/base/install/triggers.yaml
    wget https://storage.googleapis.com/tekton-releases/triggers/previous/v0.16.1/interceptors.yaml -O ${DIR}/base/install/interceptors.yaml
    wget https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml -O ${DIR}/base/install/dashboards.yaml
}

function credentials(){
    mkdir -p ${DIR}/overlays/${ENV}/creds
    cp ${SSH_KEY_PATH} ${DIR}/overlays/${ENV}/creds/id_rsa
    cp ${DOCKER_CONFIG_PATH} ${DIR}/overlays/${ENV}/creds/.dockerconfigjson
    yq eval -i '.secretGenerator[2].literals.[0] = "'secretToken=$GITHUB_SECRET'"' overlays/${ENV}/kustomization.yaml
}

function cleanup(){
    kubectl delete pod $(kubectl get pods | grep Completed        | awk '{print $1}') 2> /dev/null || echo "Cleaned up Completed jobs"
    kubectl delete pod $(kubectl get pods | grep Error            | awk '{print $1}') 2> /dev/null || echo "Cleaned up Errored jobs" 
    kubectl delete pod $(kubectl get pods | grep DeadlineExceeded | awk '{print $1}') 2> /dev/null || echo "Cleaned up DeadlineExceeded jobs"
    yq eval -i '.secretGenerator[2].literals.[0] = "secretToken="' overlays/${ENV}/kustomization.yaml
    rm -rf ${DIR}/overlays/${ENV}/creds
}

function apply(){
    sync
    credentials
    kubectl apply -k overlays/${ENV}
    cleanup
}

$1
