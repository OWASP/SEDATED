![SEDATED_logo_full](docs/images/SEDATED_logo_full.png)

The **SEDATED&#8480;** Project (Sensitive Enterprise Data Analyzer To Eliminate Disclosure) focuses on preventing sensitive data such as user credentials and tokens from being pushed to Git.

## Table of Contents
- [Purpose](#purpose)
- [Setup](#setup)
  - [Clone down **SEDATED&#8480;**](#setup1)
  - [Update `.example` files](#setup2)
  - [Customize `/config/custom_configs.sh` variables and functions (as desired)](#setup3)
  - [Push **SEDATED&#8480;** with Organization Specific Implementation](#setup4)
  - [Point pre-receive hook to **SEDATED&#8480;**'s `pre-recieve.sh` file](#setup5)
- [File Descriptions](#fileDescriptions)
  - [`pre-receive.sh`](#preReceive)
  - [`/config/custom_configs.sh`](#customConfigs)
  - [`/config/enforced_repos_list.txt`](#enforcedReposList)
  - [`/config/regexes.json`](#regexes)
  - [`/config/whitelists/commit_whitelist.txt`](#commitWhitelist)
  - [`/config/whitelists/repo_whitelist.txt`](#repoWhitelist)
  - [`/testing/regex_testing/regex_test_script.sh`](#regexTestScript)
  - [`/testing/regex_testing/test_cases.txt`](#testCases)
- [Customization](#customization)
  - [Custom Variables](#customVars)
  - [Custom Functions](#customFuncs)
- [Compatibility](#compatibility)
  - [GitHub](#github)
  - [GitLab](#gitlab)
  - [Git](#git)
  - [Any Other Git SCM Tool](#anyother)
- [Contribute](#contribute)
- [Authors](#authors)
- [License](#license)

## <a id="purpose">Purpose</a>
With the myriad of code changes required in today's CICD environment developers are constantly pushing code that could unintentionally contain sensitive information. This potential sensitive data exposure represents a huge risk to organizations ([2017 OWASP Top Ten #3 - Sensitive Data Exposure](https://www.owasp.org/index.php/Top_10-2017_A3-Sensitive_Data_Exposure)). **SEDATED&#8480;** addresses this issue by automatically reviewing all incoming code changes and providing instant feedback to the developer. If it identifies sensitive data it will prevent the commit(s) from being pushed to the Git server.

\*\**NOTE: **ONLY** lines being added or modified (beginning with `+` in the patch file) in commit pushes are scanned by **SEDATED&#8480;**. Lines that are being removed (beginning with `-` in the patch file) in commit pushes are **NOT** scanned by **SEDATED&#8480;**.*

## <a id="setup">Setup</a>
#### <a id="setup1">1. Clone down **SEDATED&#8480;**</a>
`git clone https://github.com/OWASP/SEDATED.git`

`cd SEDATED/`
#### <a id="setup2">2. Update `.example` files</a>
`cp /config/whitelists/commit_whitelist.txt.example /config/whitelists/commit_whitelist.txt`

`cp /config/whitelists/repo_whitelist.txt.example /config/whitelists/repo_whitelist.txt`

`cp /config/enforced_repos_list.txt.example /config/enforced_repos_list.txt`
#### <a id="setup3">3. Customize `/config/custom_configs.sh` Variables and Functions (as desired)</a>

#### <a id="setup4">4. Push **SEDATED&#8480;** with Organization Specific Implementation</a>
Push organization specific implementation of **SEDATED&#8480;** to organization's desired Git repository (GitHub, GitLab, Git, etc...).

#### <a id="setup5">5. Point pre-receive hook to **SEDATED&#8480;**'s `pre-recieve.sh` file</a>
Instructions for accomplishing this on a GitHub Enterprise instance can be found in [GitHub_Enterprise_Setup.md](docs/GitHub_Enterprise_Setup.md).

## <a id="fileDescriptions">File Descriptions</a>
##### <a id="preReceive">`pre-receive.sh`</a>
- The heart and soul of **SEDATED&#8480;**.
- The **SEDATED&#8480;** pre-receive Git hook script used in conjunction with **SEDATED&#8480;**'s regexes (config/regexes.json), identifies added or modified lines of code being pushed to a Git instance that contain hard-coded credentials/sensitive data (as identified in config/regexes.json) and prevents the push **IF** lines containing hard-coded credentials/sensitive data are found.
##### <a id="customConfigs">`/config/custom_configs.sh`</a>
- The **SEDATED&#8480;** custom configurations file used in conjunction with `pre-receive.sh` allows organizations to customize their **SEDATED&#8480;** implementation without having to modify any of the source code within **SEDATED&#8480;**'s `pre-receive.sh` file by providing built-in customizable variables and functions that are sourced from `pre-receive.sh`.
##### <a id="enforcedReposList">`/config/enforced_repos_list.txt`</a>
- Utilized when **SEDATED&#8480;** (pre-receive hook) `use_enforced_repo_check_custom` flag in `config/custom_configs.sh` is set to "True".
- Allows **SEDATED&#8480;** to be "enabled" globally within the enterprise, but "enforced" selectively only on repositories listed in this file.
- Enforcement for all repositories under a specific organization or username can be accomplished by appending the `/*` to the end of the organization or username where enforcement is desired.
- If **SEDATED&#8480;** is enabled globally within an organization and does not appear in the `/config/enforced_repos_list.txt` file the pusher (if pushing from the command line) will see a customizable message (customize via the `/config/custom_configs.sh` file) and **SEDATED&#8480;** will NOT scan any of the code included in the push.
- The flag to enable/disable this functionality can be found in `/config/custom_configs.sh` and set to "True" or "False".
  - "False"  - Every repository with **SEDATED&#8480;** "enabled" will also have **SEDATED&#8480;** "enforced" on it.
  - "True" - Only repositories with **SEDATED&#8480;** "enabled" AND listed in the `/config/enforced_repos_list.txt` will have **SEDATED&#8480;** "enforced" on them. All other repositories with **SEDATED&#8480;** "enabled" but not listed in the `/config/enforced_repos_list.txt` file will only see a custom message displayed, no code will be scanned for pushes from those repositories.
- This file can be blank, only needs to exist if `use_enforced_repo_check_custom` flag in `config/custom_configs.sh` is set to "True".
##### <a id="regexes">`/config/regexes.json`</a>
- Contains the regular expressions (regexes) used to flag sensitive data/hard-coded credentials.
- These regexes are consumed by GNU grep (in `pre-receive.sh`) with the `-P` flag making them Perl-compatible regular expressions (PCREs).
- Regexes may be added or removed from this file as-needed, however if utilizing the `/testing/regex_testing/regex_test_script.sh` script the `/testing/regex_testing/test_cases.txt` file will need to updated by adding or removing the test cases pertaining to the updated regexes so the results from the `/testing/regex_testing/regex_test_script.sh` will be accurate.
- If adding/modifying regexes in this file additional escape characters `\` may be needed depending on the desired regexes since this file is in JSON format.
##### <a id="commitWhitelist">`/config/whitelists/commit_whitelist.txt`</a>
- Utilized in the case of a false positive, one or more commits can be excluded in the scanning process if their commit ID's are included in this file.
- Commit ID's will need to be carriage return separated in this file as shown in the `/config/whitelists/commit_whitelist.txt.example` file.
- This file can be blank, but does need to exist.
##### *Optional: Request that developers submit pull requests to this (`commit_whitelist.txt`) file when they encounter false positives so they can be reviewed.*
##### <a id="repoWhitelist">`/config/whitelists/repo_whitelist.txt`</a>
- (organization/username)/repositories included in this file will be entirely excluded from scanning for sensitive data/hard-coded credentials until removed from this list.
- Utilized in the case of a massive push (repository migration for example) where **SEDATED&#8480;** cannot scan the new/modified code included in the push within the 5 second window (the 5 second window is GitHub specific and may be different on other Git instances).
- (organization/username)/repository names need to be carriage return separated in this file as shown in the `/config/whitelists/repo_whitelist.txt.example` file.
- This file can be blank, but does need to exist.
##### <a id="regexTestScript">`/testing/regex_testing/regex_test_script.sh`</a>
- The SEDATED regular expression testing script used in conjunction with `testing/regex_testing/test_cases.txt` is a simple, quick, offline way to test/validate that the regular expressions inside `config/regexes.json` are valid and matching the desired patterns as well as excluding/not matching as desired.
  - Tests regexes against a list of test cases (`/testing/regex_testing/test_cases.txt`) to verify regexes working as expected.
  - Includes testing for both positive and negative test cases (`/testing/regex_testing/test_cases.txt`).
  - **MUST use GNU grep** when running the script otherwise the script will fail (BSD grep does not have the `-P` flag).
  - Test cases pulled in for use in this script are pulled in from `/testing/regex_testing/test_cases.txt`.
##### <a id="testCases">`/testing/regex_testing/test_cases.txt`</a>
- List of test cases to be passed-in to `/testing/regex_testing/regex_test_script.sh` for consumption.
- Each test case has`>>pass` or `>>fail` appended to it these let the `/testing/regex_testing/regex_test_script.sh` script know the expectation for the regexes.
  - `>>pass` means a push containing the preceeding string will be accepted by **SEDATED&#8480;** (i.e. regexes will NOT flag the preceeding string).
  - `>>fail` means a push containing the preceeding string will be rejected by **SEDATED&#8480;** (i.e. regexes will flag the preceeding string).


## <a id="customization">Customization</a>
Custom variables and functions are designed to allow organizations to easily customize their own specific implementation of **SEDATED&#8480;** without altering the main pre-receive hook file that does all the heavy lifting. All custom variables and functions can be found in [`/config/custom_configs.sh`](#customConfigs) and the explanations of the variables contained in this file are listed below.
#### <a id="customVars">Custom Variables</a>
- `show_SEDATED_link_custom` - "True" to display link to OWASP/SEDATED GitHub repository (case-sensitive), otherwise set to "False".
- `documentation_link_custom` - Add link to organization specific documentation on how the organization would like developers to handle rejected pushes and/or general organization specific information regarding SEDATED.
  - Displayed back to the developer when a push is rejected.
  - Displayed back to the developer when enforced repo check is set to true and the repo is not included on the enforced_repos_list.txt file.
- `use_enforced_repo_check_custom` - "True" or "False" (case-sensitive).
  - See file description above for [`/config/enforced_repos_list.txt`](#enforcedReposList) for more details on the meaning of this flag.
- `enforced_repo_check_true_message_custom` with custom message (only necessary if `use_enforced_repo_check_custom` is set to "True").
#### <a id="customFuncs">Custom Functions</a>
- `SET_USER_REPO_NAME_CUSTOM`
  - Sets user/organization/group and repository name.
  - Sets user/organization/group and repository name using GITHUB_REPO_NAME variable if using GitHub.
  - If not using GitHub custom variables can be set to get these names.
  - The provided non-GitHub names are setup for just getting the names in vanilla Git, but may need to be adjusted based on different implementations (Git SCMs).
- `PRINT_ERROR_MESSAGE_CUSTOM`
  - Allows a custom error message to be printed when errors are encountered.
- `EXIT_SEDATED_CUSTOM`
  - Take additional custom action when exiting SEDATED (i.e. log, send metrics, etc...).
  - Defaults to `:` "do nothing" as an additional action, and is not required to be changed.
- `UNABLE_TO_ACCESS_REPO_WHITELIST_CUSTOM`
  - Take additional custom action when SEDATED is unable to access the repo whitelist file (i.e. print error message, log, send metric, etc...).
  - Defaults to `:` "do nothing" as an additional action, and is not required to be changed.
- `PUSH_ACCEPTED_CUSTOM`
  - Take additional custom action when a push is accepted (i.e. log, send metrics, etc...).
  - Defaults to `:` "do nothing" as an additional action, and is not required to be changed.
- `UNABLE_TO_ACCESS_REGEXES_CUSTOM`
  - Take additional custom action when SEDATED is unable to access the regexes.json file.
  - Defaults to `:` "do nothing" as an additional action, and is not required to be changed.
  - SEDATED will `exit 1` and print error message if unable to access regexes, however additional custom action may be performed in these cases if desired (i.e. print additional error message, log, send metric, etc...).
- `PUSH_REJECTED_WITH_VIOLATIONS_CUSTOM`
  - Take additional custom action when pushes are rejected for containing violations (i.e. log, send metrics, etc...).
  - Defaults to `:` "do nothing" as an additional action, and is not required to be changed.
- `UNABLE_TO_ACCESS_COMMIT_WHITELIST_CUSTOM`
  - Take additional custom action when SEDATED is unable to access the commit whitelist file (i.e. log, send metrics, etc...).
  - Defaults to `:` "do nothing" as an additional action, and is not required to be changed.

## <a id="compatibility">Compatibility</a>
*Only compatible with SCM tools that utilize the Git version control system.*
- <a id="github">**GitHub**</a>
  - Fully tested (Enterprise v2.15.3).
  - [**SEDATED&#8480;** GitHub Enterprise Setup](docs/GitHub_Enterprise_Setup.md).
- <a id="gitlab">**GitLab**</a>
  - Preliminarily tested.
  - Modifications to [`SET_USER_REPO_NAME_CUSTOM`](#customFuncs) will be required to set user/org and repo name.
- <a id="git">**Git**</a>
  - Preliminarily tested.
  - All **SEDATED&#8480;** files/folders will need to be placed into the `.git/hooks/` directory (except documentation folder/files).
  - Remove `.sample` from `pre-receive.sample` and copy the code from **SEDATED&#8480;**'s `pre-receive.sh` file into the `pre-receive` file we just made from the `.sample` file.
  - Depending on implementation may want to use [git-template](https://git-template.readthedocs.io/en/latest/) or something similar.
- <a id="anyother">**Any Other Git SCM Tool**</a>
  - Not tested.
  - Modifications to [`SET_USER_REPO_NAME_CUSTOM`](#customFuncs) will likely be required to set user/org and repo name.
  - May require additional modifications to work.

## <a id="contribute">Contribute</a>
### Contributions to this project welcome!
You can contribute in either of the following ways:
- Submit your ideas for improvement to us (or anyone in the community who may want to take on the challenge of turning your idea into reallity within **SEDATED&#8480;**'s code base) please [raise an issue](https://github.com/OWASP/SEDATED/issues) with a good explanation of what you think could improve **SEDATED&#8480;** and how you think that could practically happen within the code base. 
- Submit a pull request with your code changes for making **SEDATED&#8480;** better and we will review, test, and merge. :)

## <a id="authors">Authors</a>
- Dennis Kennedy
- Simeon Cloutier

## <a id="license">License</a>
**SEDATED&#8480;** is licensed under the [BSD 3-Clause "New" or "Revised" License](LICENSE.md).

<hr />

\*\****SEDATED&#8480;** is not guaranteed to flag every instance of hard-coded credential, key, secret, etc... it uses regex pattern matching and though it has gotten pretty good at catching most instances it is not perfect, but we are always open to ideas and/or pull requests to help make **SEDATED&#8480;** even better.* 
