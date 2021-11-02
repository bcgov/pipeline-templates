# Tekton Kustomize

- [Overview](#overview)
- [Installation](#installation)
- [Usage](#usage)
- [Pipeline Run Templates](#pipeline-run-templates)
  - [**buildah-build-push**](#buildah-build-push)
  - [**maven-build**](#maven-build)
- [How It Works](#how-it-works)

## Overview

This project aims to improve the management experience with tekton pipelines. The [pipeline](https://github.com/tektoncd/pipeline) and [triggers](https://github.com/tektoncd/triggers) projects are included as a single deployment. All pipelines and tasks are included in the deployment and can be incrementally updated by running `./tekton.sh apply`. All operations specific to manifest deployment are handled by [Kustomize](https://kustomize.io/). A `kustomization.yaml` file exists recursively in all directories under `./base`.

For Openshift environments. Tekton Pipelines is already deployed which means only the pipelines and tasks need to be deployed. Pipelines, tasks and triggers can be deployed using `kubectl apply -k ./base/pipelines && kubectl apply -k ./base/tasks && kubectl apply -k ./base/triggers`

```diff
  ./base
  ├── install
  │   ├── dashboards.yaml
  │   ├── interceptors.yaml
+ │   ├── kustomization.yaml
  │   ├── pipelines.yaml
  │   └── triggers.yaml
+ ├── kustomization.yaml
  ├── pipelines
  │   ├── buildah.yaml
+ │   ├── kustomization.yaml
  │   └── maven.yaml
  ├── tasks
  │   ├── buildah.yaml
  │   ├── git-clone.yaml
+ │   ├── kustomization.yaml
  │   └── maven-build.yaml
  └── triggers
      ├── ingress.yaml
+     ├── kustomization.yaml
      ├── rbac.yaml
      └── trigger-template.yaml
```

## Installation

The .env file is used to create secrets from the provided values. Variables referencing a path are added as files to the Kubernetes secrets.

1. Install [yq](https://mikefarah.gitbook.io/yq/)

   ```bash
   # MacOS
   brew install yq

   # Source binary
   wget https://github.com/mikefarah/yq/releases/download/v4.2.0/yq_linux_amd64 -O /usr/bin/yq &&\
     chmod +x /usr/bin/yq
   ```

2. Fork this repository and clone it locally.

   ```bash
   git clone https://github.com/<YOUR_USERNAME>/tekton-kustomize.git
   cd tekton-kustomize
   ```

3. Create a .env file and adjust the following variables to match your environment.

   ```bash
   cat <<EOF >>.env
   # Set the kustomize overlay environment. Options include dev and prod..
   ENV=dev

   # SSH Key used to authenticate to the target Git repositories.
   SSH_KEY_PATH=~/.ssh/id_rsa

   # The Docker config to be used for pushing and pulling images. 
   # Run 'docker login' to generate a config file.
   DOCKER_CONFIG_PATH=~/.docker/config.json

   # Github Webhook Secret Token. Refer to https://docs.github.com/en/developers/webhooks-and-events/webhooks/securing-your-webhooks
   GITHUB_SECRET=""
   EOF
   ```

4. Apply the manifests.

   ```bash
   ./tekton.sh apply
   ```

<!-- USAGE EXAMPLES -->
## Usage

The provided tekton.sh helper script has the following functions.

```bash
# - Creates the required secrets from .env
# - Installs tekton pipelines and triggers
# - Deploys all configured pipelines, triggers, and tasks  
./tekton.sh apply

# - Removes all Completed, Errored or DeadlineExceeded pipeline runs from the cluster
# - Ensures no plaintext secrets exist in the repository after `./tekton apply`
# - './tekton.sh apply' includes this function execution
./tekton.sh cleanup

# - Syncs the official tekton release to the local tekton manifests at ./base/install
# - './tekton.sh apply' includes this function execution
./tekton.sh sync
```

## Pipeline Run Templates

All `PipelineRun` templates listed below are tested and working.

### **buildah-build-push**

*Build and push a docker image using [buildah](https://buildah.io/).*

```yaml
cat <<EOF | kubectl create -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: docker-build-push-run-
spec:
  pipelineRef:
    name: p-buildah
  params:
  - name: appName
    value: flask-web
  - name: repoUrl
    value: git@github.com:bcgov/security-pipeline-templates.git
  - name: imageUrl
    value: gregnrobinson/tkn-flask-web:latest
  - name: branchName
    value: main
  - name: dockerfile
    value: ./Dockerfile
  - name: pathToContext
    value: ./tekton/demo/flask-web
  - name: buildahImage
    value: quay.io/buildah/stable:v1.23.1
  workspaces:
  - name: shared-data
    volumeClaimTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 500Mi
  - name: ssh-creds
    secret:
      secretName: tkn-ssh-credentials
  - name: docker-config
    secret:
      secretName: tkn-docker-credentials
EOF
```

### **maven-build**

*Builds and a java application with [maven](https://maven.apache.org/).*

```yaml
cat <<EOF | kubectl create -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: maven-run-
spec:
  pipelineRef:
    name: p-maven-build
  params:
  - name: appName
    value: maven-test
  - name: mavenImage
    value: index.docker.io/library/maven
  - name: repoUrl
    value: git@github.com:bcgov/security-pipeline-templates.git
  - name: branchName
    value: main
  - name: pathToContext
    value: ./tekton/demo/maven-test
  workspaces:
  - name: shared-data
    volumeClaimTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
  - name: ssh-creds
    secret:
      secretName: tkn-ssh-credentials
  - name: docker-config
    secret:
      secretName: tkn-docker-credentials
  - name: maven-settings
    emptyDir: {}
EOF
```

## How It Works

Much of the heavy lifting is performed by a tool called [Kustomize](https://kustomize.io/). Kustomize comes pre-bundled with **kubectl version >= 1.14** which means the only required prerequisite for developers to deploy this project is a target cluster and the latest version of kubectl.

All manifests that pertain to the installation of Tekton are located at the root of `./base/`.

All Tekton `Pipeline` and `Task` resource types are located respectively at `./base/pipelines` and `./base/tasks`.

```bash
tekton-kustomize
├── README.md
├── base
│   ├── install
│   │   ├── dashboards.yaml
│   │   ├── interceptors.yaml
│   │   ├── kustomization.yaml
│   │   ├── pipelines.yaml
│   │   └── triggers.yaml
│   ├── kustomization.yaml
│   ├── pipelines
│   │   ├── buildah.yaml
│   │   ├── kustomization.yaml
│   │   └── maven.yaml
│   ├── tasks
│   │   ├── buildah.yaml
│   │   ├── git-clone.yaml
│   │   ├── kustomization.yaml
│   │   └── maven-build.yaml
│   └── triggers
│       ├── ingress.yaml
│       ├── kustomization.yaml
│       ├── rbac.yaml
│       └── trigger-template.yaml
├── demo
├── overlays
│   ├── dev
│   │   ├── dashboards.yaml
│   │   └── kustomization.yaml
│   └── prod
│       ├── kustomization.yaml
│       └── dashboards.yaml
└── tekton.sh
```

When `./tekton.sh apply` is executed, the first operation to take place is a sync whereby the remote latest Tekton release is copied to `./base/install`.

Following the sync operation is the creation of the `./overlays/${ENV}/creds` folder in one of the overlay environments that is declared in `.env`. The `${SSH_KEY_PATH}` and `${DOCKER_CONFIG_PATH}` files are copied from the provided paths in `.env` to the temporary creds folder.

The last step is executing kustomize using `kubectl apply -k overlays/${ENV}`. This command will execute the following kustomize configuration in `./overlays/${ENV}`.

After the execution, a cleanup function deletes the creds folder and removes the `$GITHUB_SECRET` value from `./overlays/${ENV}/kustomization.yaml`.

```yaml
# ./overlays/dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base/
patchesStrategicMerge:
  - dashboards.yaml
generatorOptions:
  disableNameSuffixHash: true
secretGenerator:
  - name: tkn-ssh-credentials
    files:
      - creds/id_rsa
  - name: tkn-docker-credentials
    files:
      - creds/.dockerconfigjson
    type: kubernetes.io/dockerconfigjson
  - name: github-secret
    type: Opaque
    literals:
      - secretToken=
patchesJson6902:
  - target:
      version: v1
      kind: Secret
      name: github-secret
    patch: |-
      - op: add
        path: /metadata/annotations
        value:
          tekton.dev/git-0: github.com
```

When the base templates are applied using `./overlays/${ENV}/kustomization.yaml`, the kustomization.yaml file at the root of base deploys all the declared manifests in each folder using `./base/kustomization.yaml`.

```yaml
# ./base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ./install
  - ./pipelines
  - ./tasks
  - ./triggers
```

Declaring the folder as a resource will find and execute any kustomization.yaml files within the directories and execute accordingly. All manifests are explicitly declared which allows for resources currently under development to be excluded from the deployment. This eliminates the need for branching when creating new Tekton pipelines and tasks. Aslong as the resources are not declared in Kustomize, the changes will not be breaking.

```yaml
# ./base/install/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- pipelines.yaml
- triggers.yaml
- interceptors.yaml
- dashboards.yaml

# ./base/pipelines/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namePrefix: p-

resources:
- buildah.yaml
- maven.yaml

# ./base/tasks/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namePrefix: t-

resources:
- buildah.yaml
- git-clone.yaml
- maven-build.yaml

# ./base/triggers/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ingress.yaml
  - rbac.yaml
  - trigger-template.yaml
```
