#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0
# This code is based on code written by the Hyperledger Fabric community. 
# Original code can be found here: https://github.com/hyperledger/fabric-samples/blob/release/fabcar/startFabric.sh
#
# Modifications copyright (C) 2018 CIP
#
red=$'\e[1;31m'
end=$'\e[0m'
if [[ $# -eq 0 ]] ; then
    echo "${red}Chaincode version is missing...${end}"
    exit 0
fi
# Exit on first error, print all commands.
set -ev
# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1

starttime=$(date +%s)

# launch network; create channel and join peer to channel
docker-compose -f docker-compose-bluemix.yml down

docker-compose -f docker-compose-bluemix.yml up -d peer0.cipbancos.org.br couchdb

# wait for Hyperledger Fabric to start
# incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
export FABRIC_START_TIMEOUT=5
#echo ${FABRIC_START_TIMEOUT}
sleep ${FABRIC_START_TIMEOUT}

# Create the channel
docker exec -e "CORE_PEER_LOCALMSPID=CIPMSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@cipbancos.org.br/msp" peer0.cipbancos.org.br peer channel create -o orderer.cipbancos.org.br:7050 -c mychannel -f /etc/hyperledger/configtx/channel.tx
# Join peer0.cipbancos.org.br to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=CIPMSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@cipbancos.org.br/msp" peer0.cipbancos.org.br peer channel join -b mychannel.block

# Now launch the CLI container in order to install and instantiate chaincode
docker-compose -f ./docker-compose-bluemix.yml up -d cli

docker exec -e "CORE_PEER_LOCALMSPID=CIPMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/cipbancos.org.br/users/Admin@cipbancos.org.br/msp" cli peer chaincode install -n minerva-app -v $1 -p github.com/minerva-app
docker exec -e "CORE_PEER_LOCALMSPID=CIPMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/cipbancos.org.br/users/Admin@cipbancos.org.br/msp" cli peer chaincode instantiate -o orderer.cipbancos.org.br:7050 -C mychannel -n minerva-app -v $1 -c '{"Args":[""]}' -P "OR ('CIPMSP.member')"
sleep 10
# Invoke initLedger to populate the ledger.
docker exec -e "CORE_PEER_LOCALMSPID=CIPMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/cipbancos.org.br/users/Admin@cipbancos.org.br/msp" cli peer chaincode invoke -o orderer.cipbancos.org.br:7050 -C mychannel -n minerva-app -c '{"function":"initLedger","Args":[""]}'

# Launch webapplication container.
docker-compose -f ./docker-compose-bluemix.yml up -d webapp
docker exec webapp export WEBAPP_PEER=peer0.cipbancos.org.br

printf "\nTotal execution time : $(($(date +%s) - starttime)) secs ...\n\n"