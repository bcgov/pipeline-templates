# Tekton Pipelines

- [Overview](#overview)
  - [Layout](#layout)
  - [Common Workflow](#common-workflow)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Pipeline Run Templates](#pipeline-run-templates)
  - [**buildah-build-push**](#buildah-build-push)
  - [**helm-build-deploy**](#helm-build-deploy)
  - [**maven-build**](#maven-build)
  - [**codeql-scan**](#codeql-scan)
  - [**sonar-scan**](#sonar-scan)
  - [**trivy-scan**](#trivy-scan)
  - [**owasp-scan**](#owasp-scan)
- [How It Works](#how-it-works)

## Overview

This project aims to improve the management experience with tekton pipelines. The [pipeline](https://github.com/tektoncd/pipeline) and [triggers](https://github.com/tektoncd/triggers) projects are included as a single deployment. All pipelines and tasks are included in the deployment and can be incrementally updated by running `./tekton.sh -i`. All operations specific to manifest deployment are handled by [Kustomize](https://kustomize.io/). A `kustomization.yaml` file exists recursively in all directories under `./base.`

The project creates secrets for your docker and ssh credentials using the Kustomize [secretGenerator](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kustomize/). This allows for the git-clone and buildah Tekton tasks to interact with private repositories. I would consider setting up git and container registry credentials a foundational prerequisite for operating cicd tooling. Once Kustomize creates the secrets, they are referenced directly by name in the [Pipeline Run Templates](#pipeline-run-templates) section.

The project is intended to improve developement agility by providung one configuration file that holds kubernetes secrets in the form of simple key pairs. for all the secrets that are needed.  from the installation manifests to the custom Tekton CRDs that manage the creation and execution of pipelines. Whenever changes are made to `./base` or `./overlays,` run `./tekton.sh -u` to apply the changes against the current Kubernetes context. Behind the scenes, the following functions are executed.

1. **setup**: Installs [yq](https://mikefarah.gitbook.io/yq/) for parsing YAML files.
2. **sync**: Pulls the following Tekton release manifests to `./base/install`
    - pipeline
    - triggers
    - interceptors
    - dashboard
3. **credentials**: copies ssh, docker, and webhook credentials to Kustomize and creates secrets.
4. **apply**: Runs `kubectl apply -k overlays/${ENV}` to install/update Tekton and deploy Tekton CRDs.
5. **cleanup**: Cleans up Completed pipeline runs and deletes all creds.

The `./tekton.sh -i` argument sources the `.env` file at the root of the repository. Variables referenced by path are added as files to Kubernetes secrets.

### Layout

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
  ├── overlays
  │   ├── apply
  │   │   └── kustomization.yaml
+ │   └── secrets ()
  │       ├── file.secrets
  │       ├── main.py
  │       ├── opaque.secrets
  │       └── requirements.txt
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

## Common Workflow

Having all the overrides defined within the `PipelineRun` allows for the configuration to be dynamically modified at runtime. The `PipelineRun` should contain all parameters that are dynamic values. The diagram represents common values that will always need to be modified based on the specific project this template is used for.

A shared workspace defined in the `PipelineRun` determines at runtime which data source all tasks will share. This means when the `git-clone` task clones the repository locally, the buildah will have access to these files to complete the build process. `git-clone` is the most used task as many pipelines need a copy of the source code before the following tasks can execute.

`Pipelines` are for orchestrating the execution of tasks and this involves assigning parameter overrides that each task needs. `git-clone` requires SSH credentials, and the `buildah` tasks require a Docker config that will be used to authenticate to private Docker registries.

![workflow](https://user-images.githubusercontent.com/26353407/142748076-1a261753-1c73-474b-83fd-dd6d69e89299.png)

## Prerequisites

Note: This project has been tested on *linux/arm64*, *linux/amd64*, *linux/aarch64*, and *darwin/arm64*.

1. [kubectl](https://kubernetes.io/docs/tasks/tools/) >= 1.21.0
2. [python3](https://www.python.org/)
3. [pip](https://pip.pypa.io/en/stable/installation/)

## Installation

1. Clone the repository. (If you want to make changes, fork the repository)

   ```bash
   git clone https://github.com/bcgov/pipeline-templates
   cd ./pipeline-templates/tekton
   ```

2. Create a file named `secrets.ini` using the snippet below.

    **secrets.ini**
    Creates secrets for all secret types. The `key` refers to the secret name, and the `value` is the secret contents.

    `github-secret` is used for triggers. Can be left as is if triggers are not used.

   ```bash
   cat <<EOF >./overlays/secrets/secrets.ini
   [literals]
   trivy-username=<IMAGE_REGISTRY_USERNAME>
   trivy-password=<IMAGE_REGISTRY_PASSWORD>
   github-secret=<GITHUB_WEBOOK_SECRET>
   github-token=<GITHUB_PAT_TOKEN>
   sonar-token=<SONAR_PROJECT_TOKEN>

   [docker]
   docker-config-path=/Users/<USER>/.docker/config.json

   [ssh]
   ssh-key-path=/Users/<USER>/.ssh/config.json
   EOF
   ```

3. Set the context and namespace you wish to deploy the resources in. Set the variables in your active shell.

   ```bash
   # If CONTEXT is not set or null, the current context is used.
   export CONTEXT="<YOUR_CONTEXT>"

   # If NAMESPACE is not set or null, the default namespace is used.
   export NAMESPACE="<TARGET_NAMESPACE>"
   ```

4. Apply the Tekton resources. Use this command to also update the cluster with the latest changes to the Tekton resources.

   ```bash
   ./tekton.sh -a
   ```

## Usage

Run `./tekton.sh -h` to display the help menu.

```bash
Usage: tekton.sh [option...]

   -a, --apply         Apply Secrets, Pipelines, Tasks and Triggers.
   -p, --prune         Delete all PipelineRuns.
   -h, --help          Display argument options.
```

## Pipeline Run Templates

All pipeline run templates listed below are tested and working. The `PipelineRun` templates refernece pipelines and tasks that were deployed using `./tekton.sh`. All the dependancies to operate this repository are within the repository. Developers can focus on consuming the pipelines for their needs with minimal changes. Additional to adhoc use, developers can create a yaml file with the following templates and store them in a Git repositoy where they can incorporate the pipeline runs into their own automation workflows. Aslong as the runner has access a Kibernetes cluster, a pipeline run will execute with just `kubectl apply -f <YOUR_PIPELINE_RUN>.yaml`.

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
    value: gregnrobinson/tkn-flask-web
  - name: imageTag
    value: latest
  - name: branchName
    value: main
  - name: dockerfile
    value: ./Dockerfile
  - name: pathToContext
    value: ./tekton/demo/flask-web
  - name: buildahImage
    value: quay.io/buildah/stable
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
      secretName: ssh-key-path
  - name: docker-config
    secret:
      secretName: docker-config-path
EOF
```

[Back to top](#tekton-pipelines)

### **helm-build-deploy**

*Builds a Dockerfile and deploys the resulting image to Openshift as a deployment using [helm](https://helm.sh/docs/). By default, this configuration will use the helm chart located at`demo/flask-web/helm`.*

```yaml
cat <<EOF | kubectl create -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: build-deploy-helm-
spec:
  pipelineRef:
    name: p-helm-build-deploy
  params:
  - name: repoUrl
    value: git@github.com:bcgov/security-pipeline-templates.git
  - name: branchName
    value: main
  - name: imageUrl
    value: gregnrobinson/tkn-flask-web
  - name: helmRelease
    value: flask-web
  - name: helmDir
    value: ./tekton/demo/flask-web/helm
  - name: helmValues
    value: values.yaml
  - name: dockerfile
    value: ./Dockerfile
  - name: pathToContext
    value: ./tekton/demo/flask-web
  - name: buildahImage
    value: quay.io/buildah/stable
  - name: helmImage
    value: docker.io/lachlanevenson/k8s-helm:v3.7.0
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
      secretName: ssh-key-path
  - name: docker-config
    secret:
      secretName: docker-config-path
EOF
```

### **maven-build**

*Builds and a java application with [maven](https://maven.apache.org/).*

```yaml
cat <<EOF | kubectl create -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: mvn-build-run-
spec:
  pipelineRef:
    name: p-mvn-build
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
  - name: runSonarScan
    value: 'true'
  - name: sonarProject
    value: tekton
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
      secretName: ssh-key-path
  - name: docker-config
    secret:
      secretName: docker-config-path
  - name: maven-settings
    emptyDir: {}
EOF
```

[Back to top](#tekton-pipelines)

### **codeql-scan**

*Scans a given repository for explicit languages. [CodeQL](https://codeql.github.com/)*

- **language**: Language for codeql to analyze.
- **githubToken**: Github token for uploading scan results to Github.

```yaml
cat <<EOF | kubectl create -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: codeql-scan-run-
spec:
  pipelineRef:
    name: p-codeql
  params:
  - name: buildImageUrl
    value: docker.io/gregnrobinson/codeql-cli:latest
  - name: repoUrl
    value: git@github.com:bcgov/security-pipeline-templates.git
  - name: repo
    value: bcgov/security-pipeline-templates
  - name: branchName
    value: main
  - name: pathToContext
    value: .
  - name: githubToken
    value: tkn-github-token
  - name: language
    value: python
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
      secretName: ssh-key-path
  - name: docker-config
    secret:
      secretName: docker-config-path
EOF
```

[Back to top](#tekton-pipelines)

### **sonar-scan**

*Scans a given repository against a provided SonarCloud project. [SonarCloud](https://sonarcloud.io/)*

Requires a secret within the task named `tkn-sonar-token`. This is used to authenticate to SonarCloud or SonarQube.

For scans with SonarCloud, create a `sonar-project.properties` file at the root of the repository that is referenced in the `repoUrl` parameter.

```conf
# sonar-project.properties
sonar.organization=ci-testing
sonar.projectKey=tekton
sonar.host.url=https://sonarcloud.io
```

- **sonarHostUrl**: The SonarQube/SonarCloud instance.
- **sonarProject**: The project to run the scan against.
- **sonarTokenSecret**: The authentication token for SonarQube/SonarCloud.

```yaml
cat <<EOF | kubectl create -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: sonar-scanner-run-
spec:
  pipelineRef:
    name: p-sonar
  params:
  - name: sonarHostUrl
    value: https://sonarcloud.io
  - name: sonarProject
    value: tekton
  - name: sonarTokenSecret
    value: sonar-token
  - name: repoUrl
    value: git@github.com:gregnrobinson/gregrobinson-ca-k8s.git
  - name: branchName
    value: main
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
      secretName: ssh-key-path
  - name: sonar-settings
    emptyDir: {}
EOF
```

[Back to top](#tekton-pipelines)

### **trivy-scan**

*Scans for vulnerbilities and file systems. [SonarCloud](https://github.com/aquasecurity/trivy)*

```yaml
cat <<EOF | kubectl create -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: trivy-scanner-run-
spec:
  pipelineRef:
    name: p-trivy
  params:
  - name: targetImage
    value: python:3.4-alpine
  - name: repoUrl
    value: git@github.com:bcgov/security-pipeline-templates.git
  - name: branchName
    value: main
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
      secretName: ssh-key-path
  - name: docker-config
    secret:
      secretName: docker-config-path
EOF
```

[Back to top](#tekton-pipelines)

### **owasp-scan**

*Scans public web apps for vulnerbilities. [ZAP Scanner](https://www.zaproxy.org/docs/docker/about/)*

- **targetUrl**: The URL to run the scan against.
- **scanType**: Accepted values are `quick` or `full`.
- **scanDuration**: The duration of the scan in minutes.

The pipeline performs either a quick or full scan based on the `scanType` parameter. The duration can be modified in minutes using the `scanDuration` parameter.

```yaml
cat <<EOF | kubectl create -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: owasp-scanner-run-
spec:
  pipelineRef:
    name: p-owasp
  params:
  - name: targetUrl
    value: https://example.com
  - name: scanType
    value: quick
  - name: scanDuration
    value: '2'
  workspaces:
  - name: shared-data
    volumeClaimTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
  - name: owasp-settings
    emptyDir: {}
EOF
```

[Back to top](#tekton-pipelines)

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
└── ktek.sh
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
  - name: ssh-key-path
    files:
      - creds/id_rsa
  - name: docker-config-path
    files:
      - creds/.dockerconfigjson
    type: kubernetes.io/dockerconfigjson
  - name: github-secret
    type: Opaque
    literals:
      - secretToken=
  - name: sonar-token
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

Declaring the folder as a resource will find and execute any kustomization.yaml files within the directories accordingly. All manifests are explicitly declared which allows for resources currently under development to be excluded from the deployment. This eliminates the need for branching when creating new Tekton resources. Aslong as the resources are not declared in Kustomize, the changes will not be breaking.

```yaml
## ./base/install/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - pipelines.yaml
  - triggers.yaml
  - interceptors.yaml
  - dashboards.yaml

## ./base/pipelines/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namePrefix: p-

resources:
  - buildah.yaml
  - maven.yaml

## ./base/tasks/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namePrefix: t-

resources:
  - buildah.yaml
  - git-clone.yaml
  - maven-build.yaml

## ./base/triggers/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ingress.yaml
  - rbac.yaml
  - trigger-template.yaml
```

[Back to top](#tekton-pipelines)
