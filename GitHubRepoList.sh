#!/usr/bin/env bash
#
# Create a CSV report of all repositories 
#
# PreReq: GH_TOKEN set in env
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
   echo "l     Maximum number of repositories to list"
   echo "o     github org"
   echo
}

while [ ! -z "$1" ]; do
  case "$1" in
     --help|-h)
         shift
         echo "You entered number as: $1"
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


echo "[INFO] gh repo list ${org} -L ${limit} --json name --jq '.[].name' > repolist.csv"

gh repo list ${org} -L ${limit} --json name --jq '.[].name' > repolist

sort repolist