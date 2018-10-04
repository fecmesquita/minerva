#!/bin/bash
#
# Exit on first error
set -ev

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1

starttime=$(date +%s)

docker-compose -f docker-compose.yml down

docker-compose -f docker-compose.yml up -d ca.cipbancos.org.br orderer.cipbancos.org.br

printf "\nTotal execution time : $(($(date +%s) - starttime)) secs ...\n\n"
