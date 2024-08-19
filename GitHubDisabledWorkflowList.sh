#!/usr/bin/env bash
#
# Create a list of manually disabled workflows
# PreReqs:
#	github cli, jq, sort installed 
# 	GH_TOKEN set in env or login via gh cli
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
   echo "Syntax: GitHubIssueSearch.sh [-h|t]"
   echo "options:"
   echo "f     Fields to search. Comma separated list. Ex. \"name,description,updatedAt"\"
   echo "h     Print this Help."
   echo "l     Maximum number of repositories to list"
   echo "o     github org"
   echo
}

############################################################
# read args                                                  
############################################################
while [ -n "$1" ]; do
  case "$1" in
    --fields|-f)
      shift
      fields="${1:-name}"
      ;;
    --help|-h)
      shift
      echo "You entered number as: $1"
      ;;
    --limit|-l)
      shift
      limit="${1:-500}"
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

if [ ! -n "$org" ]; then
 echo "[ERROR] Org was not provided"
 exit 1
fi


############################################################
# main
# list gh repos to file and sort                                                 
############################################################
./GitHubRepoList.sh -o "${org}" -l "${limit}" -f "name"

while IFS= read -r line; do
  repo=$(echo "${line}" | tr -d '"')

  if [[ $repo == "name" ]]; then
     continue
  fi

  workflows=$(gh api \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    /repos/"${org}"/"${repo}"/actions/workflows | jq '.workflows[] | select(.state == "disabled_manually") | .path')
  
  if [ -n "$workflows" ]; then
    for workflow_path in $workflows
    do
      echo "${org}/${repo}/$(echo $workflow_path | tr -d \")"
    done
  fi

done < repolist.csv

rm repolist.csv