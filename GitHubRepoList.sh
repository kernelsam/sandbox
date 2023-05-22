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
echo "[INFO] gh repo list ${org} -L ${limit} --json name,description,updatedAt --jq '.[]| [.name, .description, .updatedAt]' | tr -d '[]' > repolist.csv"

gh repo list ${org} -L ${limit} --json name,description,updatedAt --jq '.[]| [.name, .description, .updatedAt]' | tr -d '[]' > repolist.csv

sort -k 1 -o repolist.csv{,}
echo -e "Repo Name, Description, Last Updated\n$(cat repolist.csv)" > repolist.csv