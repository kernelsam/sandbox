#!/usr/bin/env bash
#
# Create a CSV report of all repositories 
#
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
   echo "Syntax: GitHubRepoList.sh [-h|t]"
   echo "options:"
   echo "h     Print this Help."
   echo "f     Fields to search. Comma separated list. Ex. \"name,description,updatedAt"\"
   echo "l     Maximum number of repositories to list"
   echo "o     github org"
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

# update fields to be passed to jq in the format
# .<value1>,.<value2>,...,.<valuen>
if grep -q "," <<< "${fields}"; then
   jqfields=$(echo "${fields}" | awk -F "," '{ for(i=1; i<NF; i++) printf ".%s,", $i }')
   jqfields=$jqfields$(echo ".${fields}" | awk -F, '{ print "."$NF }')
else
   # single field should have no trailing comma
   jqfields=".${fields}"
fi

# list the repos to a file 
echo "[INFO] gh repo list ${org} -L ${limit} --json ${fields} --jq .[]| [${jqfields}] | tr -d '[]' > repolist.csv"
gh repo list "${org}" -L "${limit}" --json "${fields}" --jq " .[]| [${jqfields}]" | tr -d '[]' > repolist.csv

# sort the file in place and add a header 
sort -k 1 -o repolist.csv{,}
echo -e "${fields}\n$(cat repolist.csv)" > repolist.csv

