#!/usr/bin/env bash
#
# Create a list of prs matching a search string based on a list of repositories
# PreReqs:
#	github cli, jq, sort installed 
# 	GH_TOKEN set in env
#
# TODO(kernelsam): Read token from lastpass
#

############################################################
# help                                                   
############################################################
help()
{
   # Display Help
   echo
   echo "Syntax: GitHubPRSearch.sh [-h|t]"
   echo "options:"
   echo "h     Print this Help."
   echo "f     Fields to search. Comma separated list. Ex. \"number,headRepository"\"
   echo "l     Maximum number of repositories to list"
   echo "o     github org"
   echo "s     Filter by state: {open|closed|merged|all}"
   echo "ss    search string"
   echo
}

############################################################
# read args                                                  
############################################################
while [ -n "$1" ]; do
  case "$1" in
     --help|-h)
         shift
         echo "You entered number as: $1"
         ;;
     --fields|-f)
         shift
         fields=$1
         ;;
     --limit|-l)
         shift
         limit=$1
         ;;
     --org|-o)
        shift
        org=$1
         ;;
     --searchstring|-ss)
        shift
        searchstring=$1
        ;;
     --state|-s)
        shift
        state=$1
        ;;
     *)
        help
        exit 1
        ;;
  esac
shift
done


############################################################
# main
# list gh repos to file and sort                                                 
############################################################
./GitHubRepoList.sh -o "${org}" -l "${limit}" -f "name"

# update fields to be passed to jq in the format
# .<value1>,.<value2>,...,.<valuen>
if grep -q "," <<< "${fields}"; then
   jqfields=$(echo "${fields}" | awk -F "," '{ for(i=1; i<NF; i++) printf ".%s,", $i }')
   jqfields=$jqfields$(echo ".${fields}" | awk -F, '{ print "."$NF }')
else
   # single field should have no trailing comma
   jqfields=".${fields}"
fi


while IFS= read -r line; do
   repo=$(echo "${line}" | tr -d '"')
   echo "[INFO] gh pr list -R https://github.com/${org}/${repo} --state \"${state}\" --search \"${searchstring}\" --json \"${fields}\" --jq \" .[]| [${jqfields}]\" >> prs.csv"
   gh pr list -R https://github.com/"${org}"/"${repo}" --state "${state}" --search "${searchstring}" --json "${fields}" --jq " .[]| [${jqfields}]" >> prs.csv
done < repolist.csv
