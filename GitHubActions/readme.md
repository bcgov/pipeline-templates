# GitHub Actions Templates
--------------------------------------------------------------------------------------------------------------------
[![CodeQL](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/codeql.yml/badge.svg)](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/codeql.yml)

##Code QL
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
  *  CodeQL supports [ 'cpp', 'csharp', 'go', 'java', 'javascript', 'python' ]
     Learn more:
     https://docs.github.com/en/free-pro-team@latest/github/finding-security-vulnerabilities-and-errors-in-your-code/configuring-code-scanning#changing-the-languages-that-are-analyzed
     
6. Checkout Repo

7. Initilize Code QL

8. Autobuild builds the code

9. Analysis Performed

10. Updates sent to #Security Events

--------------------------------------------------------------------------------------------------------------------
[![OWASP Baseline Scan](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/owaspbase.yml/badge.svg)](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/owaspbase.yml)

[![OWASP Full Scan](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/owaspfull.yml/badge.svg)](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/owaspfull.yml)

## OWASP

Open source web application security scanner:

1. Update the variable with the target website

    ```bash
    env:
      TARGET_URL: 'https://itsecgames.com/`
    ```

   The above is an example of a vulnerable website that can be used to test the Github Actions Template. Please replace this URL with the targeted website you would like to scan.

2. Broken out into a few functions
  * Lines 5-11 have the ability to define the scope of the action by including or ignoring specific branches or tags.
  * Ability to schedule scans to automate the scanning process to meet company policies or any security requirements.

3. Both the baseline and full scan are included within this action, lines 44-53 are for baseline and lines 55-64 for full scan

--------------------------------------------------------------------------------------------------------------------  
[![Aqua Trivy Vulnerability Scanner](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/trivyscan.yml/badge.svg)](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/trivyscan.yml)
## Trivy Scan

Scanner for vulnerabilities in container images, file systems, and Git repositories, as well as for configuration issues:

1. Ability to trigger off branch push or pull request

    ```bash
      push:
        branches:
          - master
      pull_request:
    ```

2. Adjust the severity outside of CRITICAL,HIGH:

    ```
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

3. Results of scan set to GitHub Security Tab
   

--------------------------------------------------------------------------------------------------------------------    
[![Aqua Trivy with GH Scanning](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/trivyghscan.yml/badge.svg)](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/trivyghscan.yml)
## Trivy with GitHub

Scanner for vulnerabilities in container images, file systems, and Git repositories, as well as for configuration issues which will create a result in the Security Tab:

1. Ability to trigger off branch push or pull request

    ```bash
      push:
        branches:
          - master
      pull_request:
    ```
2. Run vulnerability Scanner in repo mode (Defined by scan type)

3. Results of scan set to GitHub Security Tab

--------------------------------------------------------------------------------------------------------------------
[![Sonarqube](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/sonarqube.yml/badge.svg)](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/sonarqube.yml)

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

--------------------------------------------------------------------------------------------------------------------
[![Version Bump Template](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/version.yml/badge.svg)](https://github.com/bcgov/Security-pipeline-templates/actions/workflows/version.yml)
## Versioning

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
   ```
          env:
         GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
         WITH_V: true
         DEFAULT_BUMP: patch, minor, major
    ```
