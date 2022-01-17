# Github Actions Templates

This folder contains all Github Actions templates. To make use of the repository, fork this repository and modify the `env` and `trigger` sections of each template to meet the needs of your application or repository.

- [Layout](#layout)
- [How to Use](#how-to-use)
- [Workflow Templates](#workflow-templates)
  - [Owasp Scan](#owasp-scan)
  - [Trivy Scan](#trivy-scan)
  - [CodeQL Scan](#codeql-scan)
  - [Docker Build Push](#docker-build-push)
  - [Sonar Repo Scan](#sonar-repo-scan)
  - [Sonar Maven Scan](#sonar-maven-scan)
- [Secrets Management](#secrets-management)
- [Testing Pipeline](#testing-pipeline)
- [Full Workflow Example](#full-workflow-example)
- [Reference](#reference)

## Layout

All templates are stored in the .github folder. By default once you fork or copy the templates, they are ready to be used.

```diff
./github
|-- workflows
    |-- README.md
    |-- build-push.yaml
    |-- codeql.yml
    |-- full-workflow.yaml
    |-- helm-build-deploy.yaml
    |-- oc-build-deploy.yaml
    |-- owasp-scan.yml
    |-- pre-commit-check.yaml
    |-- release.yaml
    |-- sonar-scanner-mvn.yml
    |-- sonar-scanner.yml
    |-- trivy.yaml
    `-- version.yml
```

## How to Use

1. Fork this repository to make use of all the templates.

2. Modify the `triggers` and `env` section of each of the templates and provide values that match your environment.

```yaml
# These variables tell the worflow what and where steps should run against.
# For example, if I am building a Docker image, I can set the working directory to the directory where the Dockerfile exists.
env:
  NAME: nginx-web
  IMAGE: gregnrobinson/bcgov-nginx-demo
  WORKDIR: ./demo/nginx

# Set triggers to tell the workflow when it should run...
on:
  push:
    branches:
    - main
    paths-ignore:
    - 'README.md'
    - '.pre-commit-config.yaml'
    - './github/workflows/pre-commit-check.yaml'
  workflow_dispatch:

# A schedule can be defined using cron format.
  schedule:
    # * is a special character in YAML so you have to quote this string
    - cron:  '30 5,17 * * *'

    # Layout of cron schedule.  'minute hour day(month) month day(week)'
    # Schedule option to review code at rest for possible net-new threats/CVE's
    # List of Cron Schedule Examples can be found at https://crontab.guru/examples.html
    # Top of Every Hour ie: 17:00:00. '0 * * * *'
    # Midnight Daily ie: 00:00:00. '0 0 * * *'
    # 12AM UTC --> 8PM EST. '0 0 * * *'
    # Midnight Friday. '0 0 * * FRI'
    # Once a week at midnight Sunday. '0 0 * * 0'
    # First day of the month at midnight. '0 0 1 * *'
    # Every Quarter. '0 0 1 */3 *'
    # Every 6 months. '0 0 1 */6 *'
    # Every Year. '0 0 1 1 *'
    #- cron: '0 0 * * *'
  ...
```

## Workflow Templates

You can make use of the templates by calling the workflows from your own workflow. This simplifies workflow execution by only providing the neccesary inputs and secrets to the workflow run.

### Owasp Scan

```yaml
name: trivy-scan
on:
  workflow_dispatch:
jobs:
  zap-owasp:
    uses: bcgov/pipeline-templates/.github/workflows/owasp-scan.yaml@main
    with:
      ZAP_SCAN_TYPE: 'base' # Accepted values are base and full.
      ZAP_TARGET_URL: http://www.itsecgames.com
      ZAP_DURATION: '2'
      ZAP_MAX_DURATION: '5'
      ZAP_GCP_PUBLISH: true
      ZAP_GCP_PROJECT: phronesis-310405  # Only required if ZAP_GCP_PUBLISH is TRUE
      ZAP_GCP_BUCKET: 'zap-scan-results' # Only required if ZAP_GCP_PUBLISH is TRUE
    secrets:
      GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }} # Only required if ZAP_GCP_PUBLISH is TRUE
```

### Trivy Scan

```yaml
name: trivy-scan
on:
  workflow_dispatch:
jobs:
  trivy-scan:
    uses: bcgov/pipeline-templates/.github/workflows/trivy-container.yaml@main
    with:
      IMAGE: gregnrobinson/bcgov-nginx-demo
      TAG: latest
```

### CodeQL Scan

```yaml
name: codeql-scan
on:
  workflow_dispatch:
jobs:
  codeql-scan:
    uses: bcgov/pipeline-templates/.github/workflows/codeql.yaml@main
```

### Docker Build Push

```yaml
name: docker-build-push
on:
  workflow_dispatch:
  schedule:
    - cron:  '0 0 * * 0'
jobs:
  build-push:
    uses: bcgov/pipeline-templates/.github/workflows/build-push.yaml@main
    with:
      NAME: nginx-web
      IMAGE: gregnrobinson/bcgov-nginx-demo
      WORKDIR: ./demo/nginx
    secrets:
      IMAGE_REGISTRY_USER: ${{ secrets.IMAGE_REGISTRY_USER }}
      IMAGE_REGISTRY_PASSWORD: ${{ secrets.IMAGE_REGISTRY_PASSWORD }}
```

### Sonar Repo Scan

```yaml
name: docker-build-push
on:
  workflow_dispatch:
  schedule:
    - cron:  '0 0 * * 0'
jobs:
  sonar-repo-scan:
    uses: bcgov/pipeline-templates/.github/workflows/sonar-scanner.yaml@main
    with:
      ORG: ci-testing
      PROJECT_KEY: bcgov-pipeline-templates
      URL: https://sonarcloud.io
    secrets:
      SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

### Sonar Maven Scan

```yaml
name: docker-build-push
on:
  workflow_dispatch:
  schedule:
    - cron:  '0 0 * * 0'
jobs:
  sonar-scan-mvn:
    uses: bcgov/pipeline-templates/.github/workflows/sonar-scanner-mvn.yaml@main
    with:
      WORKDIR: ./tekton/demo/maven-test
      PROJECT_KEY: pipeline-templates
    secrets:
      SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

## Secrets Management

The following repository secrets are required depending on which template is being used. [Learn more](https://docs.github.com/en/actions/security-guides/encrypted-secrets).

| Secret Name             | Description |
| :---------------------- | :------------|
| IMAGE_REGISTRY          | The registry prefix with username. (ie. docker.io/bcgov)       |
| IMAGE_REGISTRY_USER     | Registry username. Used for interacting with private image repositories.           |
| IMAGE_REGISTRY_PASSWORD | Registry password. Used for interacting with private image repositories.       |
| OPENSHIFT_SERVER        | The API endpoint of your Openshfit cluster. By default, this needs to be a publically accessible endpoint.       |
| OPENSHIFT_TOKEN         | A token that has the correct permissions to perform create deployment in OpenShift.       |
| SONAR_TOKEN             | Used when using the Sonar scanning templates.  

## Testing Pipeline

Every Sunday all worlflows are testing a `workflow_call` to each workflow from the testing workflow.

[View Pipeline Run](https://github.com/bcgov/pipeline-templates/runs/4837867353?check_suite_focus=true)

## Full Workflow Example

Use the following workflow as a reference to understand how each template functions. This workflow incorporates all the templates.

[View Pipeline Run](https://github.com/bcgov/security-pipeline-templates/actions/runs/1496960480)

![full-workflow](https://user-images.githubusercontent.com/26353407/143089191-f23b59a7-185d-4173-b395-0903aab8bc83.png)

## Reference

[Workflow Syntax](https://docs.github.com/en/actions/learn-github-actions/workflow-syntax-for-github-actions)

[Workflow Triggers](https://docs.github.com/en/actions/learn-github-actions/events-that-trigger-workflows)
