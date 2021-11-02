#!/bin/bash

set -o errexit
set -o pipefail
set -o allexport; source .env; set +o allexport

export PATH=$PATH:${PWD}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

export cyan=$(tput setaf 6)
export green=$(tput setaf 2)
export warn=$(tput setaf 3)
export bold=$(tput bold)
export normal=$(tput sgr0)

function sync(){
    wget -q https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml                   -O ${DIR}/base/install/pipelines.yaml    && echo "${green}Synced Tekton pipelines${normal}"
    wget -q https://storage.googleapis.com/tekton-releases/triggers/previous/v0.16.1/release.yaml         -O ${DIR}/base/install/triggers.yaml     && echo "${green}Synced Tekton triggers${normal}"
    wget -q https://storage.googleapis.com/tekton-releases/triggers/previous/v0.16.1/interceptors.yaml    -O ${DIR}/base/install/interceptors.yaml && echo "${green}Synced Tekton interceptors${normal}"
    wget -q https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml -O ${DIR}/base/install/dashboards.yaml   && echo "${green}Synced Tekton dashboard${normal}"
    echo "${green}Sync completed successfully...${normal}"
}

function credentials(){
    setup
    mkdir -p ${DIR}/overlays/${ENV}/creds
    cp ${SSH_KEY_PATH} ${DIR}/overlays/${ENV}/creds/id_rsa
    cp ${DOCKER_CONFIG_PATH} ${DIR}/overlays/${ENV}/creds/.dockerconfigjson
    yq eval -i '.secretGenerator[2].literals.[0] = "'secretToken=$GITHUB_SECRET'"' overlays/${ENV}/kustomization.yaml
    yq eval -i '.secretGenerator[3].literals.[0] = "'secretToken=$GITHUB_TOKEN'"' overlays/${ENV}/kustomization.yaml
    echo "${green}Generated secret declerations...${normal}"
}

function cleanup(){
    setup
    kubectl delete pod $(kubectl get pods | grep Completed        | awk '{print $1}') 2> /dev/null || echo "${green}Cleaning up Completed jobs${normal}"
    kubectl delete pod $(kubectl get pods | grep Error            | awk '{print $1}') 2> /dev/null || echo "${green}Cleaning up Errored jobs${normal}" 
    kubectl delete pod $(kubectl get pods | grep DeadlineExceeded | awk '{print $1}') 2> /dev/null || echo "${green}Cleaning up DeadlineExceeded jobs${normal}"
    yq eval -i '.secretGenerator[2].literals.[0] = "secretToken="' overlays/${ENV}/kustomization.yaml
    yq eval -i '.secretGenerator[3].literals.[0] = "secretToken="' overlays/${ENV}/kustomization.yaml
    rm -rf ${DIR}/overlays/${ENV}/creds
    echo "${green}Cleanup completed successfully...${normal}"
}

function setup(){
    OS=$(uname)
    MACHINE_TYPE=$(uname -m)
    VERSION="v4.14.1"
    if [ ! -f yq ]; then
        if [ ${OS} == 'Darwin' ]; then
            if [[ ${MACHINE_TYPE} =~ 'x86_64' ]]; then
                wget -q https://github.com/mikefarah/yq/releases/download/${VERSION}/yq_darwin_amd64 -O yq &&\
                    chmod +x yq
                    echo "${green}yq_darwin_amd64 was installed...${normal}" 
            elif [[ ${MACHINE_TYPE} =~ 'arm64' ]]; then
                wget -q https://github.com/mikefarah/yq/releases/download/${VERSION}/yq_darwin_arm64 -O yq &&\
                    chmod +x yq
                    echo "${green}yq_darwin_arm64 was installed...${normal}" 
            fi
        fi
        if [ ${OS} == 'Linux' ]; then
            if [[ ${MACHINE_TYPE} =~ 'x86_64' ]]; then
                wget -q https://github.com/mikefarah/yq/releases/download/${VERSION}/yq_linux_amd64 -O yq &&\
                    chmod +x yq
                    echo "${green}yq_linux_amd64 was installed...${normal}" 
            elif [[ ${MACHINE_TYPE} =~ 'arm64' ]] || [[ ${MACHINE_TYPE} =~ 'aarch64' ]]; then
                wget -q https://github.com/mikefarah/yq/releases/download/${VERSION}/yq_linux_arm64 -O yq &&\
                    chmod +x yq
                    echo "${green}yq_linux_arm64 was installed...${normal}" 
            fi
        fi
    fi
}

function apply(){
    setup
    sync
    credentials
    if [ -z "${CONTEXT}" ]; then
        kubectl apply -k overlays/${ENV} || cleanup
    else
        kubectl config use-context ${CONTEXT}
        kubectl apply -k overlays/${ENV} || cleanup
    fi
    cleanup
        echo "${green}Apply completed successfully...${normal}"
}

function display_help() {    
    SHORT_SHA="$(git rev-parse --short HEAD)"
    BRANCH="$(git rev-parse --abbrev-ref HEAD)"
    echo ""
    echo "${cyan}Tekton Kustomize CLI${normal}"
    echo "${cyan}Version: ${BRANCH}-${SHORT_SHA}${normal}"
    echo ""
    echo "Usage: tekton.sh [option...]" >&2
    echo
    echo "   ${bold}-a, --apply${normal}         Install and deploy Tekton resources. "
    echo "   ${bold}-s, --sync${normal}          Pull the latest pipeline and trigger releases. "
    echo "   ${bold}-p, --prune${normal}         Delete all ${bold}Completed${normal}, $(tput bold)Errored${normal} or $(tput bold)DeadLineExceeded${normal} pod runs. "
    echo "   ${bold}-c, --creds${normal}         Create secret declerations from the provided values in ${bold}.env${normal}. "
    echo "   ${bold}-h, --help${normal}          Display argument options. "
    echo 
    exit 1
}

while :
do
    case "$1" in
      -h | --help)
          display_help  # Call your function
          exit 0
          ;;
      -s | --sync)
          sync
          shift 2
          ;;
      -c | --creds)
          credentials
          shift 2
          ;;
      -p | --prune)
          cleanup
          shift 2
          ;;
      -a | --apply)
          # do something here call function
          # and write it in your help function display_help()
          apply
          shift 2
          ;;

      --) # End of all options
          shift
          break
          ;;
      -*)
          echo "Error: Unknown option: $1" >&2
          ## or call function display_help
          exit 1 
          ;;
      *)  # No more options
          break
          ;;
    esac
done

case "$1" in
  *)
     display_help

     exit 1
     ;;
esac

