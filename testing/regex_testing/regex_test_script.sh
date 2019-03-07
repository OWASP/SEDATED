#!/bin/bash

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
            echo "-------------- TRUE REJECT: VERIFIED -----------------------------"
          else # supposed to be caught by the regexes, but was not
            echo "+++++++++++++++ ERROR:EXPECTED SUCCESS, GOT FAIL +++++++++++++++++"
            error_array+=("### FALSE POSITIVE =====> $KEY")
          fi
        else
          if [[ "$VAL" == "pass" ]]; then # it was not supposed to be caught by the regexes
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
