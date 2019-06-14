#!/usr/bin/env bash
#
#########################################################
## BSD 3-Clause License
##
## Copyright (c) 2019, Dennis Kennedy and Simeon Cloutier
##
## Redistribution and use in source and binary forms, with or without modification,
## are permitted provided that the following conditions are met:
##
##  1. Redistributions of source code must retain the above copyright notice, this
##  list of conditions and the following disclaimer.
##
##  2. Redistributions in binary form must reproduce the above copyright notice,
##  this list of conditions and the following disclaimer in the documentation and/or
##  other materials provided with the distribution.
##
##  3. Neither the name of the copyright holder nor the names of its contributors
##  may be used to endorse or promote products derived from this software without
##  specific prior written permission.
##
## THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
## ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
## WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
## IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
## INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
## BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
## DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
## LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
## OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
## OF THE POSSIBILITY OF SUCH DAMAGE.
#########################################################
####
#### Script name: pre-receive.sh
#### Authored by: Dennis Kennedy and Simeon Cloutier
#### Description: The SEDATED pre-receive Git hook script used in conjunction with  
####              SEDATED's regexes (config/regexes.json), identifies added or modified     
####              lines of code being pushed to a Git instance that contain hard-coded  
####              credentials/sensitive data (as identified in config/regexes.json) and 
####              prevents the push IF lines containing hard-coded credentials/sensitive
####              data are found.
####


start_time=$(date +%s%N)
execution_time_ms=0
my_path=${0%/*}
regexes=${my_path}/config/regexes.json
commit_whitelist=${my_path}/config/whitelists/commit_whitelist.txt
repo_whitelist=${my_path}/config/whitelists/repo_whitelist.txt
enforced_repos_list=${my_path}/config/enforced_repos_list.txt
custom_configs=${my_path}/config/custom_configs.sh
commit_whitelisted_push=false
repo_whitelisted_push=false
zero_commit="0000000000000000000000000000000000000000"
total_violations=0
file_violations=0
num_of_branches=0
branch_violations=0
branch=""

echo "  ___ ___ ___   _ _____ ___ ___  "
echo " / __| __|   \ / \_   _| __|   \ SM"
echo " \__ \ _|| |) / A \| | | _|| |) |"
echo " |___/___|___/_/ \_\_| |___|___/ "

# Check if custom_configs.sh exists in config/
if [[ -f "$custom_configs" ]]; then
  source "$custom_configs"
else
  # Action is required to create custom_configs.sh from custom_configs.sh.example
  echo ">>>>>>>>>> ACTION REQUIRED <<<<<<<<<<"
  echo ">>>>> Cannot find config/custom_configs.sh please use the template at..."
  echo ">>>>> https://github.com/owasp/sedated and populate the desired variables/functions."
  echo ">>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<"
  exit 1
fi

if [[ "$show_SEDATED_link_custom" == "True" ]]; then
  echo " https://github.com/owasp/sedated"
fi

echo "" # Blank line for formatting

function PRINT_SCRIPT_EXECUTION_TIME() {
  local execution_time_ms=$((($(date +%s%N) - $start_time)/1000000))
  echo "$execution_time_ms ms"
}

function PRINT_HAPPY_CREDENTIAL_PANDA() {
  echo "      .--._____.--.      "
  echo "      ( /_.) (._\ )      "
  echo "  __   |  / o \  |   __  "
  echo " (oo\   \ \_-_/ /   /oo) "
  echo "  \  \__/       \__/  /  "
  echo "   \   /         \   /   "
}

function PRINT_PUSH_ACCEPTED_MESSAGE() {
  echo "Push ACCEPTED"
  echo "========================================"
}

function PRINT_ERROR_PANDA() {
  echo "      .--._____.--.      "
  echo "      ( /_+) (x_\ )      "
  echo "  __   |  / o \  |   __  "
  echo " (oo\   \ \_~_/ /   /oo) "
  echo "  \  \__/       \__/  /  "
  echo "   \   /  ERROR  \   /   "
  echo "========================================"
}

# Check for regex grep error in previous command
function REGEX_GREP_ERROR_CHECK() {
    local return_val="$?"
    if [[ "$return_val" != "0" && "$return_val" != "1" ]]; then
        PRINT_ERROR_PANDA
        echo "Please try again. SEDATED was unable to complete its scan."
        echo "----------------------------------------"
        echo "$documentation_link_custom"
        echo "========================================"
        exit 1
    fi
}

# Checks if the current repo SEDATED is running on is supposed to have
# the SEDATED scan performed and enforced or just exit 0 and print message.
function ENFORCED_REPO_CHECK() {
  local enforced=$(cat "$enforced_repos_list" | grep -E "^[[:blank:]]*($user_group_name\/\*)[[:blank:]]*$|^[[:blank:]]*($user_group_name\/$repo_name)[[:blank:]]*$")

  if [[ ! "$enforced" ]]; then
    echo "================================================"
    echo "$enforced_repo_check_true_message_custom"
    echo "$documentation_link_custom"
    echo "================================================"
    PRINT_SCRIPT_EXECUTION_TIME
    exit 0
  fi
}

# Append branch name and commit ids to commits_and_branches variable
# $1 is the list of commit ids
# $2 is current commits_and_branches value
function APPEND_TO_COMMITS_AND_BRANCHES() {
  # Check if list_of_commits is empty
  if [[ "$1" ]]; then
    # Check if commits_and_branches exists so newline is not added as the first line
    if [[ "$2" ]]; then
      # newline prevents two commit ids from being added to the same line
      commits_and_branches+=$'\n'
    fi
    commits_and_branches+="$branch_name"
    commits_and_branches+=$'\n'
    commits_and_branches+="$1"
    ((num_of_branches++))
  fi
}

# Collects all of the commits and branches included in the push and stores in commits_and_branches variable
function GET_PUSHED_COMMIT_IDS_AND_BRANCHES() {
  local pull_request_from_org="${GITHUB_PULL_REQUEST_HEAD%:*}"
  local pull_request_to_org="${GITHUB_PULL_REQUEST_BASE%:*}"
  # Check if the latest commit id is all 0's, if it is there is nothing to scan
  if [[ "$latest_commit_id" == "$zero_commit" ]]; then
    : # do nothing
  # Check if it is a pull request from a fork
  elif [[ "$pull_request_from_org" != "$pull_request_to_org" ]]; then
    # From git history list all commits between the base commit id and the newest commit id
    list_of_commits=$(git rev-list $base_commit_id..$latest_commit_id)
    APPEND_TO_COMMITS_AND_BRANCHES "$list_of_commits" "$commits_and_branches" "$branch_name"
  else
    # Check if base commit id is all 0's, meaning this is the initial commit/push
    if [[ "$base_commit_id" == "$zero_commit" ]]; then
      # From git history list all commit ids up to and including the newest commit id
      # --not --all prevents SEDATED from looping ALL commit ids when new branches
      # are created and pushed, allows it to only loop new commit ids
      list_of_commits=$(git rev-list $latest_commit_id --not --all)
      APPEND_TO_COMMITS_AND_BRANCHES "$list_of_commits" "$commits_and_branches" "$branch_name"
    else
      # List all commit ids between the base commit id and the newest commit id
      list_of_commits=$(git rev-list $base_commit_id..$latest_commit_id --not --all)
      APPEND_TO_COMMITS_AND_BRANCHES "$list_of_commits" "$commits_and_branches" "$branch_name"
    fi
  fi
}

# This reads in a variable and creates a ' ' (space) delimited array from it
# $1 is the variable to read in from
function CREATE_ARRAY() {
  commits_and_branches_array+=($1)
}

# Prints execution time to console, executes EXIT_SEDATED_CUSTOM, then exits SEDATED
# $1 is the exit status, should be equal to 0 or 1
function EXIT_SEDATED() {
  PRINT_SCRIPT_EXECUTION_TIME
  EXIT_SEDATED_CUSTOM
  exit $1
}

# Check if a line contains a filename from patch file
# $1 is the line to be checked
function CHECK_IF_LINE_CONTAINS_FILENAME() {
  local temp_filename=$(echo "$1" | grep -Po '^\+\+\+ b/\K(.*)')
  if [[ "$temp_filename" ]]; then
    filename="$temp_filename"
    file_violations=0
  fi
}

# Check if commit id is a commit id or branch name
# $1 is the commit id to be checked
function CHECK_IF_COMMIT_ID_IS_BRANCH_NAME() {
  if [[ ! "$1" =~ ^[a-z0-9]{40}$ ]]; then
    branch="$1"
    branch_violations=0
    return 0
  fi
  return 1
}

function PRINT_ON_BRANCH_MESSAGE() {
  echo "====================================================="
  echo "On branch -> $branch"
}

# Check if current commit id being scanned is whitelisted
# $1 commit id currently being scanned... "${commit_id}"
function CHECK_IF_COMMIT_ID_IS_WHITELISTED() {
  if [[ -f "$commit_whitelist" ]]; then # check if config/whitelists/commit_whitelist.txt file exists
    commit_whitelisted=$(cat "$commit_whitelist" | grep -E "^[[:blank:]]*($1)[[:blank:]]*$")
  fi

  if [[ "$commit_whitelisted" ]]; then
    if [[ "$branch_violations" == 0 && "$branch" ]]; then
      PRINT_ON_BRANCH_MESSAGE
      violation_commit_id_array=()
      ((branch_violations++))
    fi
    echo "------------ ** WHITELISTED COMMIT ** ---------------"
    echo ">>>>>> $1 <<<<<"
    commit_whitelisted_push=true
    return 0
  fi
  return 1
}

# Check if current repo being scanned is whitelisted
function CHECK_IF_REPO_IS_WHITELISTED() {
  if [[ -f "$repo_whitelist" ]]; then # check if config/whitelists/repo_whitelist.txt file exists
    repo_whitelisted=$(cat "$repo_whitelist" | grep -E "^[[:blank:]]*($user_group_name\/$repo_name)[[:blank:]]*$")
  else
    PRINT_ERROR_MESSAGE_CUSTOM "UNABLE TO FIND REPO WHITELIST FILE"
    UNABLE_TO_ACCESS_REPO_WHITELIST_CUSTOM
  fi

  if [[ "$repo_whitelisted" ]]; then
    repo_whitelisted_push=true
    echo "========================================"
    PRINT_HAPPY_CREDENTIAL_PANDA
    echo "$user_group_name/$repo_name has been whitelisted"
    PRINT_PUSH_ACCEPTED_MESSAGE
    PUSH_ACCEPTED_CUSTOM
    EXIT_SEDATED 0
  fi
}

# Create pipe delimited regex_string from regexes json output
function CREATE_PIPE_DELIMITED_REGEX_STRING() {
  if [[ -f "$regexes" ]]; then # check if config/regexes.json file exists
    regex_string=$(cat "${regexes}" | grep -Po ':[[:space:]]*\"[[:space:]]*\K(.*)' | sed 's/[[:space:]]*"[[:space:]]*}[[:space:]]*,/|/' | tr -d '\n' | sed 's/\\\\/\\/g' | sed '$s/"}$//' )
  fi
  # If no regexes included in the config/regexes.json file
  if [[ ! "$regex_string" ]]; then
    PRINT_ERROR_MESSAGE_CUSTOM "UNABLE TO ACCESS REGEXES"
    UNABLE_TO_ACCESS_REGEXES_CUSTOM
    EXIT_SEDATED 1
  fi
}

# $1 is commit ids included in push
# $2 is list of commit ids included in push
function PRINT_INITIAL_SEDATED_MESSAGE() {
  echo "Repo Name = $user_group_name/$repo_name"
  echo "========================================"
  echo "***Commits scanned ($1 total):"
  echo "$2"
  echo "========================================"
  echo "Violations listed, by line, below (results may be obfuscated):"
}

# $1 is total number of lines with sensitive data
# $2 is documentation link
function PRINT_PUSH_REJECTED_WITH_VIOLATIONS_MESSAGE() {
  PUSH_REJECTED_WITH_VIOLATIONS_CUSTOM
  echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  echo "This push contains sensitive data and needs your attention."
  echo "      .--._____.--.      "
  echo "      ( /_x) (x_\ )      "
  echo "  __   |  / o \  |   __  "
  echo " (oo\   \ \_-_/ /   /oo) "
  echo "  \  \__/       \__/  /  "
  echo "   \   /         \   /   "
  echo "$1 lines found with sensitive data"
  echo "Push REJECTED."
  echo "=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+="
  echo "Please remove any sensitive data from the flagged commit ID(s)"
  echo "For more information go to:"
  echo "$2"
  echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
  echo "============================================================="
  EXIT_SEDATED 1
}

# Subtract branches from total number of commits when multiple branches
# are included in a single push so branch count is not included in commit count
# $1 is length of array
# $2 is num_of_branches
function CALCULATE_NUM_COMMITS() {
  if [[ "$num_of_branches" > 1 ]]; then
    total_num_of_commits=$(($1-$2))
  else
    total_num_of_commits="$1"
  fi
}

function PRINT_NO_COMMITS_MESSAGE() {
  echo "========================="
  PRINT_HAPPY_CREDENTIAL_PANDA
  echo "No commits to traverse"
  echo "Push ACCEPTED"
  echo "========================="

}

# If only commit id included is all 0's then nothing to scan
# or if only branches and no commit ids then exit SEDATED
# $1 is the list of commit ids/branches in push
function CHECK_FOR_COMMIT_IDS_TO_SCAN() {
  if [[ ! "$1" || ! $(echo  "$1" | grep -E '^[a-z0-9]{40}$') ]]; then
    PRINT_NO_COMMITS_MESSAGE
    EXIT_SEDATED 0
  fi
}

# Remove branch name from commits_and_branches list if only a single branch is being pushed
# $1 is number of branches included in push
# $2 list of branches and commit ids
function REMOVE_BRANCH_NAME_IF_SINGE_BRANCH_PUSH() {
  if [[ "$1" == 1 ]]; then
    commits_and_branches=$(echo "$2" | grep -Ev "^$|^.*/.*/.*$")
  fi
}

function MAIN() {
  # Get org/user/group name as well as repo name minus the .git file ext.
  SET_USER_REPO_NAME_CUSTOM

  # When enabled globally allows selective enforcement as controlled
  # by the config/enforced_repos_list.txt config file
  if [[ "$use_enforced_repo_check_custom" == "True" ]]; then
    ENFORCED_REPO_CHECK
  elif [[ "$use_enforced_repo_check_custom" == "False" ]]; then
    : # No additional action is REQUIRED
  else
    # Action is required to create custom_configs.sh from custom_configs.sh.example
    echo ">>>>>>>>>> ACTION REQUIRED <<<<<<<<<<"
    echo ">>>>> Please set the use_enforced_repo_check_custom variable in..."
    echo ">>>>> config/custom_configs.sh to \"True\" or \"False\""
    echo ">>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<"
    exit 1
  fi

  # If repo is in config/whitelists/repo_whitelist.txt file, accept push and exit SEDATED℠
  CHECK_IF_REPO_IS_WHITELISTED

  # Loop through each branch being pushed
  while read -r base_commit_id latest_commit_id branch_name; do
    GET_PUSHED_COMMIT_IDS_AND_BRANCHES
  done

  CHECK_FOR_COMMIT_IDS_TO_SCAN "$commits_and_branches"
  REMOVE_BRANCH_NAME_IF_SINGE_BRANCH_PUSH "$num_of_branches" "$commits_and_branches"
  CREATE_ARRAY "$commits_and_branches"
  CALCULATE_NUM_COMMITS "${#commits_and_branches_array[*]}" "$num_of_branches"
  PRINT_INITIAL_SEDATED_MESSAGE "$total_num_of_commits" "$commits_and_branches"

  # Create pipe delimited regex_string from regexes
  CREATE_PIPE_DELIMITED_REGEX_STRING

  # Check if commit whitelist can be accessed, but don't exit
  if [[ ! -f "$commit_whitelist" ]]; then
    PRINT_ERROR_MESSAGE_CUSTOM "UNABLE TO FIND COMMIT WHITELIST FILE"
    UNABLE_TO_ACCESS_COMMIT_WHITELIST_CUSTOM
  fi
  # Loop through each commit id in the push
  for commit_id in "${commits_and_branches_array[@]}"; do
    CHECK_IF_COMMIT_ID_IS_BRANCH_NAME "${commit_id}"
    # Exit code 0 returned by function means commit id is branch name not a commit id
    local branch_name_check_exit_code=$?

    # If not a commit id and instead is a branch name (i.e. exit code 0) continue to next commit id
    if [[ "$branch_name_check_exit_code" == 0 ]]; then continue; fi

    CHECK_IF_COMMIT_ID_IS_WHITELISTED "${commit_id}"
    # Exit code 0 returned by function means commit id is whitelisted
    local whitelisted_exit_code=$?

    # If commit id is whitelisted (i.e. exit code 0) break out of loop to next commit id
    if [[ "$whitelisted_exit_code" == 0 ]]; then continue; fi

    # Loops the git patch files and checks for everything that begins with "+"
    # which denotes any new/modified lines of code. It then takes those results
    # and bounces against the regexes.
    local all_added_contents=$(git show -D "${commit_id}" | grep -E '^[\+]' | grep -P "${regex_string}" 2> /dev/null)
    REGEX_GREP_ERROR_CHECK # Checks if line length exceeds grep PCRE's backtracking limit or other grep error, if true throw error and exit 1
    if [[ "$all_added_contents" ]]; then
        while read line; do
          CHECK_IF_LINE_CONTAINS_FILENAME "${line}"
          # If line is not a filename
          if [[ ! "$temp_filename" ]]; then
            # If first violation in this file print filename
            if [[ "$file_violations" == 0 ]]; then
              # If first violation in commit OR commit id not already flagged for a violation
              if [[ ! "${violation_commit_id_array[@]}" || "${violation_commit_id_array[-1]}" != "${commit_id}" ]]; then
                if [[ "$branch_violations" == 0 && "$branch" ]]; then
                  PRINT_ON_BRANCH_MESSAGE
                fi
                violation_commit_id_array+=("${commit_id}")
                echo "-----------------------------------------------------"
                echo "In commit -> ${commit_id}"
              fi
              echo "------------ $filename ------------"
            fi
            OBFUSCATE_CUSTOM "${line:0:150}"
            echo "${masked}"
            ((branch_violations++))
            ((total_violations++))
            ((file_violations++))
          fi
        done <<< "$all_added_contents"
    fi
  done
  # If violations flagged reject push; else accept push; print respective messages
  if [[ "${total_violations}" -gt 0 ]]; then
    PRINT_PUSH_REJECTED_WITH_VIOLATIONS_MESSAGE "$total_violations" "$documentation_link_custom"
  else
    echo "NONE"
    PRINT_HAPPY_CREDENTIAL_PANDA
    echo "Good job! No sensitive data found in your commit(s)!"
    PRINT_PUSH_ACCEPTED_MESSAGE
    PUSH_ACCEPTED_CUSTOM
    EXIT_SEDATED 0
  fi
}

MAIN
