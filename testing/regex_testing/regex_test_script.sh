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
#### Script name: regex_test_script.sh
#### Authored by: Dennis Kennedy and Simeon Cloutier
#### Description: The SEDATED regular expression testing script used in conjunction with 
####              testing/regex_testing/test_cases.txt is a simple, quick, offline way to 
####              test/validate that the regular expressions inside config/regexes.json 
####              are valid and matching the desired patterns as well as excluding/not 
####              matching as desired.
####

### ! MUST USE GNU GREP, BSD GREP WILL GIVE ERRONEOUS RESULTS ! ###
### ! SEDATED℠ USES GNU GREP, BSD GREP DOES NOT HAVE A -P FLAG ! ###

function PRINT_SEDATED() {
  echo "  ___ ___ ___   _ _____ ___ ___  "
  echo " / __| __|   \ / \_   _| __|   \ SM"
  echo " \__ \ _|| |) / A \| | | _|| |) |"
  echo " |___/___|___/_/ \_\_| |___|___/ "
  echo " https://github.com/owasp/sedated"
  echo ""
}

filename="$1"
regexes=../../config/regexes.json
# regex_string matches the EXACT way pre-recieve.sh pulls in the regexes from config/regexes.json
regex_string=$( cat "${regexes}" | grep -Po ':[[:space:]]*\"[[:space:]]*\K(.*)' | sed 's/[[:space:]]*"[[:space:]]*}[[:space:]]*,/|/' | tr -d '\n' | sed 's/\\\\/\\/g' | sed '$s/"}$//' )

# Allows a filename other than test_cases.txt to be passed as an argument and run the regexes against
# The other file would need to be in the same format as test_cases.txt to work
if [[ -z "$filename" ]]; then
  filename="test_cases.txt"
fi

echo "##################################################################"

while read line; do
  ((counter+=1))
  KEY=${line%>>*} # captures everything on the line prior to the ">>" characters
  VAL=${line#*>>} # captures everything on the line after to the ">>" characters i.e. pass/fail

  echo "### $KEY ----> $VAL." # KEY = test_cases line; VAL = supposed to be caught (fail) OR not supposed to be caught (pass)

  regex_check=$( echo "$KEY" | grep -P "${regex_string}" ) # gnu grep for lines that match regexes
        if [[ "$regex_check" ]]; then # returns TRUE if the regexes can catch/match the line
          if [[ "$VAL" == "fail" ]]; then # it was supposed to be caught by the regexes
            ((fail_counter+=1))
            echo "-------------- TRUE REJECT: VERIFIED -----------------------------"
          else # supposed to be caught by the regexes, but was not
            echo "+++++++++++++++ ERROR:EXPECTED SUCCESS, GOT FAIL +++++++++++++++++"
            error_array+=("### FALSE POSITIVE =====> $KEY")
          fi
        else
          if [[ "$VAL" == "pass" ]]; then # it was not supposed to be caught by the regexes
            ((pass_counter+=1))
            echo "-------------- TRUE ACCEPT: VERIFIED -----------------------------"
          else # not supposed to be caught by the regexes, but was
            echo "+++++++++++++++ ERROR:EXPECTED FAIL, GOT SUCCESS +++++++++++++++++"
            error_array+=("### FALSE NEGATIVE =====> $KEY")
          fi
        fi
done < "$filename"

echo "##################################################################"

if [[ "${#error_array[*]}" -eq 0 ]]; then # regexes catching and not catching everything as expected
  echo "########################## ALL GOOD!! ############################"
  echo "### $counter REGEX TEST CASES CHECKED"
  echo "### $fail_counter LINES BEING FLAGGED, AS EXPECTED (>>fail cases)"
  echo "### $pass_counter LINES NOT BEING FLAGGED, AS EXPECTED (>>pass cases)"
  echo "### REGEXES CATCHING EVERYTHING AS EXPECTED"
  echo "##################################################################"
  PRINT_SEDATED
  exit 0
else # Output results of lines that failed due to the regexes catching or not catching lines in an unexpected way
  echo "########################### UH OH!! ##############################"
  echo "### ${#error_array[*]} OF $counter TEST CASES NOT ACCOUNTED FOR"
  for err in "${error_array[@]}"; do
    echo "${err}"
  done
  echo "##################################################################"
  PRINT_SEDATED
  exit 1
fi
