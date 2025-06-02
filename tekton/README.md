# Tekton Pipelines

- [Tekton Pipelines](#tekton-pipelines)
  - [Overview](#overview)
    - [Layout](#layout)
  - [Common Workflow](#common-workflow)
  - [Prerequisites - Personal access token](#prerequisites---personal-access-token)
  - [Option 1: Install in Docker Container](#install-in-docker-container)
    - [Prerequisites (Docker)](#prerequisites-docker)
    - [Installation (Docker)](#installation-docker)
    - [Usage (Docker)](#usage-docker)
  - [Option 2: Install on your computer](#install-on-your-computer)
    - [Prerequisites](#prerequisites)
    - [Installation](#installation)
    - [Usage](#usage)
  - [Pipeline Run Templates](#pipeline-run-templates)
    - [Using Vault for PipelineRun:](#using-vault-for-pipelinerun)
    - [**buildah-build-push**](#buildah-build-push)
    - [**build-deploy-helm**](#build-deploy-helm)
    - [**maven-build**](#maven-build)
    - [**codeql-scan**](#codeql-scan)
    - [**sonar-scan**](#sonar-scan)
    - [**trivy-scan**](#trivy-scan)
    - [**owasp-scan**](#owasp-scan)
    - [**react-build**](#react-build)
  - [How It Works](#how-it-works)

## Overview

This project aims to improve the management experience with Tekton pipelines. The [pipeline](https://github.com/tektoncd/pipeline) and [triggers](https://github.com/tektoncd/triggers) projects are included as a single deployment. All pipelines and tasks are included in the deployment and can be incrementally updated by running `./tekton.sh -a`. All operations specific to manifest deployment are handled by [Kustomize](https://kustomize.io/). A `kustomization.yaml` file exists recursively in all directories under `./base.`

The project creates secrets for your docker and ssh credentials using the Kustomize [secretGenerator](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kustomize/). This allows for the git-clone and buildah Tekton tasks to interact with private repositories. I would consider setting up git and container registry credentials a foundational prerequisite for operating CICD tooling. Once Kustomize creates the secrets, they are referenced directly by name in the [Pipeline Run Templates](#pipeline-run-templates) section.

The project is intended to improve development agility by providing one configuration file that holds kubernetes secrets in the form of simple key pairs. for all the secrets that are needed. from the installation manifests to the custom Tekton CRDs that manage the creation and execution of pipelines. Whenever changes are made to `./base` or `./overlays,` run `./tekton.sh -a` to apply the changes against the current Kubernetes context. Behind the scenes, the following functions are executed.

### Layout

```diff
   ├── base
   │   ├── pipelines
   │   │   ├── buildah.yaml
   │   │   ├── codeql.yaml
   │   │   ├── helm-build-deploy.yaml
+  │   │   ├── kustomization.yaml
   │   │   ├── maven.yaml
   │   │   ├── owasp.yaml
   │   │   ├── react.yaml
   │   │   ├── sonar.yaml
   │   │   └── trivy.yaml
   │   ├── tasks
   │   │   ├── buildah.yaml
   │   │   ├── codeql
   │   │   │   ├── Dockerfile
   │   │   │   ├── codeql.yaml
+  │   │   │   └── kustomization.yaml
   │   │   ├── create-pr.yaml
   │   │   ├── deploy.yaml
   │   │   ├── generate-id.yaml
   │   │   ├── git-clone.yaml
   │   │   ├── helm-deploy.yaml
+  │   │   ├── kustomization.yaml
   │   │   ├── mvn-build.yaml
   │   │   ├── mvn-sonar-scan.yaml
   │   │   ├── npm-sonar-scan.yaml
   │   │   ├── npm.yaml
   │   │   ├── owasp-scanner.yaml
   │   │   ├── react-deploy.yaml
   │   │   ├── react-workspace.yaml
   │   │   ├── sonar-scanner.yaml
   │   │   ├── trivy-scanner.yaml
   │   │   └── yq.yaml
   │   └── triggers
   │       ├── ingress.yaml
+  │       ├── kustomization.yaml
   │       ├── rbac.yaml
   │       ├── trigger-flask-web.yaml
   │       └── trigger-maven-build.yaml
   ├── demo
   ├── overlays
   │   ├── apply
+  │   │   └── kustomization.yaml
   │   └── secrets
   │       ├── main.py
   │       ├── requirements.txt
   │       └── secrets.ini
   └── tekton.sh
```

## Common Workflow

Having all the overrides defined within the `PipelineRun` allows for the configuration to be dynamically modified at runtime. The `PipelineRun` should contain all parameters that are dynamic values. The diagram represents common values that will always need to be modified based on the specific project this template is used for.

A shared workspace defined in the `PipelineRun` determines at runtime which data source all tasks will share. This means when the `git-clone` task clones the repository locally, the buildah will have access to these files to complete the build process. `git-clone` is the most used task as many pipelines need a copy of the source code before the following tasks can execute.

`Pipelines` are for orchestrating the execution of tasks and this involves assigning parameter overrides that each task needs. `git-clone` requires SSH credentials, and the `buildah` tasks require a Docker config that will be used to authenticate to private Docker registries.

![workflow](https://user-images.githubusercontent.com/26353407/142748076-1a261753-1c73-474b-83fd-dd6d69e89299.png)

## Install in Docker Container

Setting up with docker is available with this pipeline template.

### Prerequisites (Docker)

1. You will need to have [docker](https://docs.docker.com/get-docker/) installed and make sure that Docker Desktop is running.(_Note_: Download docker from website that fit for your OS. Don's use brew install)
2. You will need to [set up your GitHub Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#personal-access-tokens-classic). After creating your personal access token, be sure to click 'Configure SSO'. You must authorize the token to for use in the `bcgov` or `bcgov-c` organisations. 

### Installation (Docker)

1. Clone the repository. (If you want to make changes, fork the repository)

   ```bash
   git clone https://github.com/bcgov/pipeline-templates
   cd ./pipeline-templates/tekton
   ```

2. Create a file named `secrets.ini` using the snippet below.

   **secrets.ini**
   Creates secrets for all secret types. The `key` refers to the secret name, and the `value` is the secret contents.

   - `github-secret` is used for triggers. Can be left as is if triggers are not used.
   - `image-registry-username` and `image-registry-password` are the account credentials for your image registry. This could be **docker.io**, **quay.io**, **gcr.io** or any other docker compatible docker registry.
   - `github-pat-token` is used to fetch your GitHub SSH credentials for Tekton git-clone task. Look at this git instruction to see how to obtain your own token: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
  
   ```bash
   cat <<EOF >./overlays/secrets/secrets.ini
   [literals]
   image-registry-username=
   image-registry-password=
   github-webhook-secret=
   github-pat-token=
   sonar-token=
   EOF
   ```

> Note if you are on Windows: You may need to transfer install.sh file from CRLF to LF, read this [answer](https://stackoverflow.com/a/54245311) for instruction with different editor.

### Usage (Docker)

3. Use Docker to build the image:

```
docker build -t tekton-install . --platform linux/amd64
```

Run the image in docker container:

```
docker run -i -t  tekton-install
```

5. Following the promote line to provide:

- Namespace name
- OC login command(with token)
- Choose an option you want to run.

## Install on your computer

### Prerequisites

Note: This project has been tested on _linux/arm64_, _linux/amd64_, _linux/aarch64_, and _darwin/arm64_.

> We also have a [Video walkthrough](https://youtu.be/WfR6rKGzi7Q) of the pipeline setup and installation.

1. [kubectl](https://kubernetes.io/docs/tasks/tools/) >= 1.21.0
2. [python3](https://www.python.org/)
3. [pip](https://pip.pypa.io/en/stable/installation/) (or pip3 if you have different version of python and pip)

These instructions assume the use of a bash-based shell such as `zsh` (included on OS X) or [WSL](https://www.howtogeek.com/249966/how-to-install-and-use-the-linux-bash-shell-on-windows-10/) for Windows. Please use one of these shells, or make the appropriate modifications to the commands shown in these instructions.

### Prerequisites - Personal access token
Before you begin, you will need to [create your Fine-grained GitHub Personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-fine-grained-personal-access-token).
Please give your fine-grained token a meaningful name and reasonable expiration date. Make sure to  select `All repositories` in Repository access. And click `Generate Token` to obtain your token that can be used in this pipeline template.Please note that the `bcgov` GitHub organization is requiring IDIR SSO authentication now, and this applies to new and existing PAT. So after the PAT is created, please follow [these steps](https://docs.github.com/en/enterprise-cloud@latest/authentication/authenticating-with-saml-single-sign-on/authorizing-a-personal-access-token-for-use-with-saml-single-sign-on) to authorize it with SSO.

### Installation

1. Clone the repository. (If you want to make changes, fork the repository)

   ```bash
   git clone https://github.com/bcgov/pipeline-templates
   cd ./pipeline-templates/tekton
   ```

2. Create a file named `secrets.ini` using the snippet below.

   **secrets.ini**
   Creates secrets for all secret types. The `key` refers to the secret name, and the `value` is the secret contents.

   - `github-webhook-secret` is used for triggers. Can be left as is if triggers are not used.
   - `image-registry-username` and `image-registry-password` are the account credentials for your image registry. This could be **docker.io**, **quay.io**, **gcr.io** or any other docker compatible docker registry.
   - `github-pat-token` is used to fetch your GitHub SSH credentials for Tekton git-clone task. Look at [this git instruction](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) to see how to obtain your own token **NOTE**  Because we are using PAT for git pull, the repoUrl **has to** use HTTPS protocol for **git-clone** TaskRun.

   ```bash
   cat <<EOF >./overlays/secrets/secrets.ini
   [literals]
   image-registry-username=
   image-registry-password=
   github-webhook-secret=
   github-pat-token=
   sonar-token=
   EOF
   ```

3. Set the context and namespace you wish to deploy the resources in. Set the variables in your active shell.

   ```bash
   # check your current OpenShift login context.
   oc config current-context

   # If CONTEXT is not set or null, the current context is used.
   export CONTEXT="<YOUR_CONTEXT>"

   # Make sure to set NAMESPACE variable to point to the tools namespace, otherwise it will use the default namespace which you don't have access to!
   export NAMESPACE="<TARGET_NAMESPACE>"
   ```

4. Apply the Tekton resources. Use this command to also update the cluster with the latest changes to the Tekton resources.

   ```bash
   ./tekton.sh -a
   ```

### Usage

Run `./tekton.sh -h` to display the help menu.

```bash
Usage: tekton.sh [option...]

   -a, --apply         Apply Secrets, Pipelines, Tasks and Triggers.
   -p, --prune         Delete all PipelineRuns.
   -d, --delete        Delete all Tekton resources.
   -h, --help          Display argument options.
```

## Pipeline Run Templates

All pipeline run templates listed below are tested and working. The `PipelineRun` templates reference pipelines and tasks that were deployed using `./tekton.sh`. All the dependencies to operate this repository are within the repository. Developers can focus on consuming the pipelines for their needs with minimal changes. Additional to adhoc use, developers can create a yaml file with the following templates and store them in a Git repository where they can incorporate the pipeline runs into their own automation workflows. As long as the runner has access a Kubernetes cluster, a pipeline run will execute with just `kubectl apply -f <YOUR_PIPELINE_RUN>.yaml`.

### Using Vault for PipelineRun:

If you would like to use Vault encrypted secrets for tasks in the pipeline, take a look [at the tekton doc](https://tekton.dev/docs/pipelines/pipelineruns/#specifying-taskrunspecs) on how to specify the `ServiceAccount` and `annotation` in the `PipelineRun.spec.TaskRunSpecs` section. Here is an example:

```yaml
...
spec:
  ...
  taskRunSpecs:
    - pipelineTaskName: buildah
      taskServiceAccountName: <NAMESPACE_LICENSEPLATE>-vault
      metadata: 
        annotations:
          vault.hashicorp.com/agent-inject: 'true'
          vault.hashicorp.com/agent-inject-token: 'true'
          vault.hashicorp.com/agent-pre-populate-only: 'true'
          vault.hashicorp.com/auth-path: auth/k8s-silver
          vault.hashicorp.com/namespace: platform-services
          vault.hashicorp.com/role: <NAMESPACE_LICENSEPLATE>-nonprod
          vault.hashicorp.com/agent-inject-secret-buildah-cred: <NAMESPACE_LICENSEPLATE>-nonprod/buildah-cred
          vault.hashicorp.com/agent-inject-template-buildah-cred: |
            {{- with secret "<NAMESPACE_LICENSEPLATE>-nonprod/buildah-cred" }}
            export IMAGE_REGISTRY_USER="{{ .image_registry.user }}"
            export IMAGE_REGISTRY_PASS="{{ .image_registry.pass }}"
            {{- end `}} }}
          ...
# refer to Vault doc for more details: https://docs.developer.gov.bc.ca/vault-getting-started-guide/#kubernetes-service-account-access-for-application-secret-usage
...
```

> Note: Also make sure to add the secret file source command `source /vault/secrets/buildah-cred` into the actual step `Task.spec.steps.script`. This way you don't have to use secrets as parameters from the Task template. 


### **buildah-build-push**

_Build and push a docker image using [buildah](https://buildah.io/)._

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
  - name: imageRegistry
    value: docker.io
  - name: imageRegistryUser
    value: image-registry-username # Secret name containing secret
  - name: imageRegistryPass
    value: image-registry-password # Secret name containing secret
  - name: imageUrl
    value: gregnrobinson/flask-web
  - name: imageTag
    value: latest
  - name: repoUrl
    value: https://github.com/bcgov/pipeline-templates.git
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
EOF
```

[Back to top](#tekton-pipelines)

### **build-deploy-helm**

_Builds a Dockerfile and deploys the resulting image to Openshift as a deployment using [helm](https://helm.sh/docs/). By default, this configuration will use the helm chart located at`demo/flask-web/helm`._

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
  - name: imageRegistry
    value: quay.io
  - name: imageRegistryUser
  # Secret name containing secret
    value: image-registry-username
  - name: imageRegistryPass
  # Secret name containing secret
    value: image-registry-password
  - name: imageUrl
    value: gregnrobinson/tkn-flask-web
  - name: imageTag
    value: latest
  - name: repoUrl
    value: https://github.com/bcgov/pipeline-templates.git
  - name: branchName
    value: main
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
EOF
```

[Back to top](#tekton-pipelines)

### **maven-build**

_Builds and a java application with [maven](https://maven.apache.org/)._

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
    value: https://github.com/bcgov/pipeline-templates.git
  - name: branchName
    value: main
  - name: pathToContext
    value: ./tekton/demo/maven-test
  - name: runSonarScan
    value: 'true'
  - name: sonarProject
    value: bcgov_pipeline-templates
  workspaces:
  - name: shared-data
    volumeClaimTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
  - name: maven-settings
    emptyDir: {}
EOF
```

[Back to top](#tekton-pipelines)

### **codeql-scan**

_Scans a given repository for explicit languages. [CodeQL](https://codeql.github.com/)_

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
    value: https://github.com/bcgov/pipeline-templates.git
  - name: repo
    value: bcgov/security-pipeline-templates
  - name: branchName
    value: main
  - name: pathToContext
    value: .
  - name: githubToken
    value: github-pat-token
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
  - name: docker-config
    secret:
      secretName: docker-config-path
EOF
```

[Back to top](#tekton-pipelines)

### **sonar-scan**

_Scans a given repository against a provided SonarCloud project. [SonarCloud](https://sonarcloud.io/)_

Requires a secret within the task named `tkn-sonar-token`. This is used to authenticate to SonarCloud or SonarQube.

For scans with SonarCloud, create a `sonar-project.properties` file at the root of the repository that is referenced in the `repoUrl` parameter.

```conf
# sonar-project.properties
sonar.organization=bcgov-sonarcloud
sonar.projectKey=bcgov_pipeline-templates
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
    value: https://github.com/bcgov/pipeline-templates.git
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
  - name: sonar-settings
    emptyDir: {}
EOF
```

[Back to top](#tekton-pipelines)

### **trivy-scan**

_Scans for vulnerabilities and file systems. [SonarCloud](https://github.com/aquasecurity/trivy)_

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
  - name: imageRegistryUser
    value: image-registry-username # Secret name containing secret
  - name: imageRegistryPass
    value: image-registry-password # Secret name containing secret
  workspaces:
  - name: shared-data
    volumeClaimTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
EOF
```

[Back to top](#tekton-pipelines)

### **owasp-scan**

_Scans public web apps for vulnerabilities. [ZAP Scanner](https://www.zaproxy.org/docs/docker/about/)_

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
    # value: https://example.com
    value: http://scanme.nmap.org
    #scanType is either quick or full
  - name: scanType
    value: quick
  - name: scanDuration
    value: '2'
  - name: repo
    value: bcgov/pipeline-templates
  - name: repoUrl
    value: https://github.com/bcgov/pipeline-templates.git
  - name: branchName
    value: main
  - name: githubToken
    value: github-pat-token
  - name: title
    value: 'Tekton Zap Scan Result'
  - name: body
    value: 'test'
  - name: github-secret
    value: 'github'
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
    volumeClaimTemplate:
      spec:
        accessModes:
        - ReadWriteOnce # access mode may affect how you can use this volume in parallel tasks
        resources:
          requests:
            storage: 1Gi
  #  emptyDir: {}
EOF
```

[Back to top](#tekton-pipelines)

### **react-build**

_Builds and deploys a simple [react](https://react.dev/) application using s2i.

- **imageTag**: The tag for the imagestream. This tag will need to be different if the imagestream is already in the namespace

This pipeline utilizes the s2i [Task](https://docs.redhat.com/en/documentation/red_hat_openshift_pipelines/1.18/html-single/creating_cicd_pipelines/index#resolver-cluster-tasks-ref_remote-pipelines-tasks-resolvers) on Openshift to build an image from the the source folder. This task pushes the image with the given tag to an imagestream and gives it the same name to the app. To open the application webpage, proper [network policies](https://github.com/bcgov/how-to-workshops/tree/master/labs/netpol-quickstart) have to be configured.

```yaml
cat <<EOF | kubectl create -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: react-build-run-
spec:
  pipelineRef:
    name: p-react-build
  params:
  - name: appName
    value: simple-react-1
  - name: repoUrl
    value: https://github.com/bcgov/pipeline-templates.git
  - name: branchName
    value: react-demo
  - name: pathToContext
    value: ./tekton/demo/simple-react
  - name: imageTag
    value: v1
  workspaces:
  - name: shared-data
    volumeClaimTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 100Mi
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

Declaring the folder as a resource will find and execute any kustomization.yaml files within the directories accordingly. All manifests are explicitly declared which allows for resources currently under development to be excluded from the deployment. This eliminates the need for branching when creating new Tekton resources. As long as the resources are not declared in Kustomize, the changes will not be breaking.

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
