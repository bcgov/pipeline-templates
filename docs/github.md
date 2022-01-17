# Github Actions Templates

This project contains all Github Actions templates. To make use of the repository, fork this repository and modify the `env` and `trigger` sections of each template to meet the needs of your application or repository.

- [Workflow Templates](#workflow-templates)
  - [Helm Build Deploy](#helm-build-deploy)
  - [Owasp Scan](#owasp-scan)
  - [Trivy Scan](#trivy-scan)
  - [CodeQL Scan](#codeql-scan)
  - [Docker Build Push](#docker-build-push)
  - [Sonar Repo Scan](#sonar-repo-scan)
  - [Sonar Maven Scan](#sonar-maven-scan)
- [Secrets Management](#secrets-management)
- [Workflow Triggers](#workflow-triggers)
- [Testing Pipeline](#testing-pipeline)
- [Reference](#reference)

## Workflow Templates

You can make use of the templates by calling the workflows from your own workflow. This simplifies workflow execution by only providing the neccesary inputs and secrets to the workflow run.

### Helm Build Deploy

```yaml
name: helm-build-deploy
on:
  workflow_dispatch:
  push:
jobs:
  helm-build-deploy:
    uses: bcgov/pipeline-templates/.github/workflows/helm-build-deploy.yaml@main
    with:
      ## DOCKER BUILD PARAMS
      NAME: flask-web
      BUILD_WORKDIR: ./demo/flask-web

      ## TARGET IMAGE
      IMAGE_REGISTRY: docker.io
      IMAGE: gregnrobinson/flask-demo-app

      ## HELM VARIABLES
      HELM_DIR: ./demo/flask-web/helm
      VALUES_FILE: ./demo/flask-web/helm/values.yaml

      ## OPENSHIFT PARAMS
      OPENSHIFT_NAMESPACE: "default"

      # Port number of your application should be accessible on.
      # If the container image exposes *exactly one* port, this can be left blank.
      # Refer to the 'port' input of https://github.com/redhat-actions/oc-new-app
      APP_PORT: "80"

      # Used to access Redhat Openshift on an internal IP address from a Github Runner.
      TAILSCALE: true
    secrets:
      IMAGE_REGISTRY_USER: ${{ secrets.IMAGE_REGISTRY_USER }}
      IMAGE_REGISTRY_PASSWORD: ${{ secrets.IMAGE_REGISTRY_PASSWORD }}
      OPENSHIFT_SERVER: ${{ secrets.OPENSHIFT_SERVER }}
      OPENSHIFT_TOKEN: ${{ secrets.OPENSHIFT_TOKEN }}
      TAILSCALE_API_KEY: ${{ secrets.TAILSCALE_API_KEY }} # Only required if TAILSCALE is set to true.
```

[Back to top](#github-actions-templates)

### Owasp Scan

```yaml
name: owasp-scan
on:
  workflow_dispatch:
  push:
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

[Back to top](#github-actions-templates)

### Trivy Scan

```yaml
name: trivy-scan
on:
  workflow_dispatch:
  push:
jobs:
  trivy-scan:
    uses: bcgov/pipeline-templates/.github/workflows/trivy-container.yaml@main
    with:
      IMAGE: gregnrobinson/bcgov-nginx-demo
      TAG: latest
```

[Back to top](#github-actions-templates)

### CodeQL Scan

```yaml
name: codeql-scan
on:
  workflow_dispatch:
  push:
jobs:
  codeql-scan:
    uses: bcgov/pipeline-templates/.github/workflows/codeql.yaml@main
```

[Back to top](#github-actions-templates)

### Docker Build Push

```yaml
name: docker-build-push
on:
  workflow_dispatch:
  push:
jobs:
  build-push:
    uses: bcgov/pipeline-templates/.github/workflows/build-push.yaml@main
    with:
      IMAGE_REGISTRY: docker.io
      IMAGE: gregnrobinson/bcgov-nginx-demo
      WORKDIR: ./demo/nginx
    secrets:
      IMAGE_REGISTRY_USER: ${{ secrets.IMAGE_REGISTRY_USER }}
      IMAGE_REGISTRY_PASSWORD: ${{ secrets.IMAGE_REGISTRY_PASSWORD }}
```

[Back to top](#github-actions-templates)

### Sonar Repo Scan

```yaml
name: sonar-repo-scan
on:
  workflow_dispatch:
  push:
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

[Back to top](#github-actions-templates)

### Sonar Maven Scan

```yaml
name: sonar-maven-scan
on:
  workflow_dispatch:
  push:
jobs:
  sonar-scan-mvn:
    uses: bcgov/pipeline-templates/.github/workflows/sonar-scanner-mvn.yaml@main
    with:
      WORKDIR: ./tekton/demo/maven-test
      PROJECT_KEY: pipeline-templates
    secrets:
      SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

[Back to top](#github-actions-templates)

## Workflow Triggers

```yaml
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

[Back to top](#github-actions-templates)

## Secrets Management

The following repository secrets are required depending on which template is being used. [Learn more](https://docs.github.com/en/actions/security-guides/encrypted-secrets).

| Secret Name             | Description |
| :---------------------- | :------------|
| IMAGE_REGISTRY_USER     | Registry username. Used for interacting with private image repositories.           |
| IMAGE_REGISTRY_PASSWORD | Registry password. Used for interacting with private image repositories.       |
| OPENSHIFT_SERVER        | The API endpoint of your Openshfit cluster. By default, this needs to be a publically accessible endpoint.       |
| OPENSHIFT_TOKEN         | A token that has the correct permissions to perform create deployment in OpenShift.       |
| SONAR_TOKEN             | Used when using the Sonar scanning templates.

## Testing Framework

Every Sunday, all worlflows are tested using a `workflow_call` to each workflow from the testing workflow.

[View Pipeline Run](https://github.com/bcgov/pipeline-templates/actions/runs/1707326261)

![image](https://user-images.githubusercontent.com/26353407/149749137-427a0384-cf79-4b2c-ac6d-c3c736db4714.png)

## Reference

[Workflow Syntax](https://docs.github.com/en/actions/learn-github-actions/workflow-syntax-for-github-actions)

[Workflow Triggers](https://docs.github.com/en/actions/learn-github-actions/events-that-trigger-workflows)

[Back to top](#github-actions-templates)
