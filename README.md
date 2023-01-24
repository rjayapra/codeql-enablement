# Code Scanning Bulk Enablement Tooling

## Purpose

The purpose of this tool is to help enable GitHub Advanced Security (GHAS) across multiple repositories in an automated way. There will be times when you need the ability to enable Code Scanning (CodeQL) across various repositories, and you don't want to click buttons manually or drop a GitHub Workflow for CodeQL into every repository. Doing this is manual and painstaking. The purpose of this utility is to help automate these manual tasks.

## Context

The primary motivator for this utility is CodeQL. It is incredibly time-consuming to enable CodeQL across multiple repositories. Additionally, no API allows write access to the `.github/workflow/` directory. So this means teams have to write various scripts with varying results. This tool provides a tried and proven way of doing that.

## What does this tooling do?

There are two main actions this tool does:

**Part One:**

Collect repositories that will have Code Scanning (CodeQL) Updates enabled by verifying the .github/worflows

Note: This tool uses the GitHub REST APIs and git tool to query and add the required resources to the Github repository. Ensure the token used to run this tool has Admin privilege on the repositories.

**Part Two:**

Loops over the repositories found, verifies the primary language of the repo and enables Code Scanning(CodeQL) with the respective template.

## Prerequisites

- [Git](https://git-scm.com/downloads) installed on the (user's) machine running this tool.
- A Personal Access Token (PAT) that has at least admin access over the repositories they want to enable Code Scanning on or GitHub App credentials which have access to the repositories you want to enable Code Scanning on.
- Some basic software development skills, e.g., can navigate their way around a terminal or command prompt.

## Set up Instructions

1.  Clone this repository onto your local machine.

    ```bash
    git clone https://github.com/rjayaprakash/codeql-enablement.git
    ```

2.  Change the directory to the repository you have just installed.

    ```bash
    cd ghas-enablement
    ```

3.  Generate your chosen authentication strategy. You are either able to use a [GitHub App](https://docs.github.com/en/developers/apps/getting-started-with-apps/about-apps) or a [Personal Access Token (PAT)](https://github.com/settings/tokens/new). The GitHub App needs to have permissions of `read and write` of `administration`, `Code scanning alerts`, `contents`, `issues`, `pull requests`, `workflows`. The GitHub PAT needs access to `repo`, `workflow` and `read:org` only. (if you are running `yarn run getOrgs` you will also need the `read:enterprise` scope).

4.  Update the script (enableCodeQL.sh) for the below mentioned variables
    ```
	org
	user
	pat
    ```
5. If you are enabling Code Scanning (CodeQL), check the `codeql-analysis-xxx.yml` files under bin/workflows directory. This is a sample file; please configure this file to suit your repositories needs.

6. If there are repositories that cannot be enabled with codeql for any reason, this is collected in repo_codeql_not_enabled.txt file

7. The tool will clone the repository where the codeql needs to be enabled to add the template file. Make sure you have enough space and permission to clone the repo locally.

## How to use?

Run : bash enableCodeQL.sh