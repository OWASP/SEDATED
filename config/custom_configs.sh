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
#### Script name: custom_configs.sh
#### Authored by: Dennis Kennedy and Simeon Cloutier
#### Description: The SEDATED custom configurations file used in conjunction with 
####              pre-receive.sh allows organizations to customize their SEDATED  
####              implementation without having to modify any of the source code  
####              within SEDATED's pre-receive.sh script by providing built-in 
####              customizable variables and functions that are sourced by pre-receive.sh.
####              

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
obfuscate_output_custom="True" # Set to "True" or "False"

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

# All functions listed below are optional, SEDATED already handles these cases,
# these custom functions allow organizations to customize their implementation
# of SEDATED by adding additional functionality upon the occurence of each of the
# below listed events. Some options are to print an additional message, log,
# or send a metric in a custom fashion.

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

# Take custom action when there is an error accessing the config/regexes.json file
function UNABLE_TO_ACCESS_REGEXES_CUSTOM() {
  : # enter custom action to be taken
}

# Take custom action when a push is properly prevented from pushing due to violations
function PUSH_REJECTED_WITH_VIOLATIONS_CUSTOM() {
  : # enter custom action to be taken
}

# Take custom action when SEDATED is unable to access config/whitelists/commit_whitelist.txt
function UNABLE_TO_ACCESS_COMMIT_WHITELIST_CUSTOM() {
  : # enter custom action to be taken
}

# This function will mask the value passed to it and store in a variable named $masked.
# The algorithm for the masking is as follows:
# If any of these characters " ='.-:+(){}", " is found, don't mask and restart counter. 
# Mask every 3rd and 4th character, and randomly every 2nd character.
masked=""
function OBFUSCATE_CUSTOM() {

	if [[ "$obfuscate_output_custom" != "True" ]]; then
		masked="$1"
		return 0
	fi
	
	unmasked="$1 "
	masked=""
	
	counter=0
	totalCounter=0

	size=${#unmasked}
	for (( i=0; i<size; i++ )); do

		((counter++))
		((totalCounter++))


		if [ "$totalCounter" == "150" ]; then
			masked="$masked..."
			return 0
		fi

		letter=${unmasked:$i:1}

		if [ "$letter" == " " ] || [ "$letter" == "=" ] || [ "$letter" == "'" ] || [ "$letter" == "\"" ]  || [ "$letter" == "." ] || [ "$letter" == "-" ] || [ "$letter" == ":" ] || [ "$letter" == "+" ] || [ "$letter" == "(" ] || [ "$letter" == ")" ] || [ "$letter" == "{" ] || [ "$letter" == "}" ]; then
			masked="$masked$letter"
			counter=0
		else

			if [ "$counter" == "4" ]; then
				masked="$masked*"
			elif [ "$counter" == "5" ]; then
				masked="$masked*"
				counter=0

			elif [ "$counter" == "2" ]; then
				randomVal=$(( ((RANDOM<<15)|RANDOM) % 4 + 1 ))

				if [ "$randomVal" == "1" ] || [ "$randomVal" == "2" ] || [ "$randomVal" == "3" ]; then
					masked="$masked$letter"
				else
					masked="$masked*"
				fi
			else
				masked="$masked$letter"	
			fi
		fi

	done

}