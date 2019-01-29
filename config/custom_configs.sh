#!/usr/bin/env bash

######### Custom variables #########

# Show link to OWASP/SEDATED℠ GitHub repository in message output
# If not set to "True" the link to OWASP/SEDATED will not be displayed
show_SEDATED_link_custom="True" # Set to "True" to display link to OWASP/SEDATED GitHub repository ! case-sensitive !

# This link will be displayed back to the developer when a push is rejected or when
# enforced repo check is set to true and the repo is not included on the enforced_repos_list.txt file
documentation_link_custom=""

# This (use_enforced_repo_check_custom) variable is required to be set to "True" or "False"
# When this (use_enforced_repo_check_custom) variable is set to "True":
### all repos not included in the config/enforced_repos_list.txt file will merely
### see the enforced_repo_check_true_message_custom and documentation_link_custom messages ouput
### SEDATED℠ will only scan the code of the repos included in that list (config/enforced_repos_list.txt)
# If this (use_enforced_repo_check_custom) variable is set to "False":
### SEDATED℠ will scan the code of every repo it is enabled on
use_enforced_repo_check_custom="" # Set to "True" or "False" ! case-sensitive !
enforced_repo_check_true_message_custom="SEDATED will soon be enforced on this repository..."

######### Custom functions #########

# Sets user/org/group name variable as well as the repo name variable
# If using GitHub set variable names from GITHUB variable
# This function may need to adjusted based on implementation
function SET_USER_REPO_NAME_CUSTOM() {
  if [[ "$GITHUB_REPO_NAME" ]]; then
    user_group_name="${GITHUB_REPO_NAME%/*}"
    repo_name="${GITHUB_REPO_NAME#*/}"
  else
    path=$(pwd)
    user_group_name=$(whoami)
    repo_name=$(basename $path | sed 's/.git//')
  fi
}

# $1 String error message to be printed
function PRINT_ERROR_MESSAGE_CUSTOM() {
  echo "XXXXXXXXXXXXXXXXXXXXXXX ERROR XXXXXXXXXXXXXXXXXXXXXXX"
  echo ""
  echo ">>>>>>>> ERROR: $1"
  echo ""
  echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
}

# Take custom action when exiting
function EXIT_SEDATED_CUSTOM() {
  : # enter custom action to be taken
}

# Take custom action when repo_whitelist file cannot be accessed
function UNABLE_TO_ACCESS_REPO_WHITELIST_CUSTOM() {
  : # enter custom action to be taken
}

# Take custom action when a push is accepted
function PUSH_ACCEPTED_CUSTOM() {
  : # enter custom action to be taken
}

function UNABLE_TO_ACCESS_REGEXES_CUSTOM() {
  : # enter custom action to be taken
}

function PUSH_REJECTED_WITH_VIOLATIONS_CUSTOM() {
  : # enter custom action to be taken
}

function UNABLE_TO_ACCESS_COMMIT_WHITELIST_CUSTOM() {
  : # enter custom action to be taken
}
