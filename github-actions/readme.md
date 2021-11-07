# GitHub Actions Templates

--------------------------------------------------------------------------------------------------------------------

## Perform a Static Application Security Test (SAST) using Code QL

[![CodeQL](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/codeql.yml/badge.svg)](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/codeql.yml)

[Click to view the CodeQL yaml template](./codeql.yml)

1. Ability to trigger off branch push or pull request

    ```bash
      push:
        branches:
          - master
      pull_request:
    ```

2. Broken out into a few functions

* Lines 5-11 have the ability to define the scope of the action by including or ignoring specific branches or tags.
* Ability to schedule scans to automate the scanning process to meet company policies or any security requirements.

3. Runs on Ubuntu-latest

5. Currently set to scan for Java code, other options are available

* CodeQL supports [ 'cpp', 'csharp', 'go', 'java', 'javascript', 'python' ]
     Learn more:
     <https://docs.github.com/en/free-pro-team@latest/github/finding-security-vulnerabilities-and-errors-in-your-code/configuring-code-scanning#changing-the-languages-that-are-analyzed>

6. Checkout Repo

7. Initilize Code QL

8. Autobuild builds the code

9. Analysis Performed

10. Updates sent to #Security Events

--------------------------------------------------------------------------------------------------------------------

## Perform a Static Application Security Test (SAST) using Sonarcloud

[![Sonarqube](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/sonarqube.yml/badge.svg)](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/sonarqube.yml)

[Click to edit Sonarqube Yaml](./sonarcloud.yml)

1. Ability to trigger off branch push or pull request

    ```bash
      push:
        branches:
          - master
      pull_request:
    ```

2. Broken out into a few functions

* Lines 5-11 have the ability to define the scope of the action by including or ignoring specific branches or tags.
* Ability to schedule scans to automate the scanning process to meet company policies or any security requirements.

3. Ability to create pre requisite action before launching this action is defined in line 29 (Currently commented out)

4. Add Sonarcloud token to your Github secrets titled #SONAR_TOKEN

5. Update line 62 with build parameters

--------------------------------------------------------------------------------------------------------------------

## Perform Dynamic Application Security Test (DAST) using OWASP

There are two options to perform DAST using OWASP:
* [OWASP Baseline yaml template](./owaspbase.yml)
  * Runs the ZAP spider against the specified target for (by default) 1 minute and then waits for the passive scanning to complete before reporting the results.
  * The script doesn't perform any actual ‘attacks’ and will run for a relatively short period of time (a few minutes at most).
  * By default it reports all alerts as WARNings but you can specify a config file which can change any rules to FAIL or IGNORE.
  * This script is intended to be ideal to run in a CI/CD environment, even against production sites.

* [OWASP Full Scan yaml template](./owaspfull.yml)
  * Runs the ZAP spider against the specified target (by default with no time limit) followed by an optional ajax spider scan and then a full active scan before reporting the results.
  * This means that the script does perform actual ‘attacks’ and can potentially run for a long period of time.
  * By default it reports all alerts as WARNings but you can specify a config file which can change any rules to FAIL or IGNORE. The configuration works in a very similar way as the Baseline Scan so see the Baseline page for more details.

[![OWASP Baseline Scan](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/owaspbase.yml/badge.svg)](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/owaspbase.yml)

[![OWASP Full Scan](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/owaspfull.yml/badge.svg)](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/owaspfull.yml)

Open source web application security scanner:

1. Update the variable with the target website

    ```bash
    env:
      TARGET_URL: 'https://itsecgames.com/`
    ```

   The above is an example of a vulnerable website that can be used to test the Github Actions Template. Please replace this URL with the targeted website you would like to scan.

2. Broken out into a few functions

  ~ Lines 5-11 have the ability to define the scope of the action by including or ignoring specific branches or tags.
  ~ Ability to schedule scans to automate the scanning process to meet company policies or any security requirements.

3. Update line 44 with the appropriate branch name

--------------------------------------------------------------------------------------------------------------------  

## Perform a container build based on a Dockerfile and scan using Aqua Trivy Vulnerability Scanner

[![Aqua Trivy Vulnerability Scanner](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/trivyscan.yml/badge.svg)](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/trivyscan.yml)
[Click to edit Trivy Yaml](./trivyscan.yml)

Scanner for vulnerabilities in container images, file systems, and Git repositories, as well as for configuration issues:

1. Ability to trigger off branch push or pull request

    ```bash
      push:
        branches:
          - master
      pull_request:
    ```

2. Adjust the severity outside of CRITICAL,HIGH:

    ```yaml
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'docker.io/my-organization/my-app:${{ github.sha }}'
          format: 'table'
          exit-code: '1'
          ignore-unfixed: true
          vuln-type: 'os,library'
          severity: 'CRITICAL,HIGH'
    ```

3. Update lines 42 and 48 with the appropriate image location and name

4. Results of scan set to GitHub Security Tab

--------------------------------------------------------------------------------------------------------------------

## Versioning

[![Version Bump Template](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/version.yml/badge.svg)](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/version.yml)

[Click to edit Versioning Yaml](./version.yml)

The following template enables a GitHub action to version the repository you are working on with either a Major, Minor or Patch level version.

* Broken out into a few functions
  * Lines 5-11 have the ability to define the scope of the action by including or ignoring specific branches or tags.

1. Ability to trigger off branch push or pull request

    ```bash
      push:
        branches:
          - master
      pull_request:
    ```

2. Define environment variable to define the bump

    ```bash
           env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          WITH_V: true
          DEFAULT_BUMP: patch, minor, major
    ```

--------------------------------------------------------------------------------------------------------------------

## Adding a badge to your readme.md file

In your project, under the Actions tab, select the appropriate action (codeQL in this example).  Next, click the ellipsis "..." and then click "Create status badge".

![clickhere](/GitHubActions/images/createABadge.png)

Click the "Copy status badge Markdown"

![copyMarkdown](/GitHubActions/images/copyStatusBadgeMarkdown.png)

Then paste the copied text into your readme.md file!
