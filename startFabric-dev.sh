#!/bin/bash
#
# Exit on first error
set -e

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1

starttime=$(date +%s)

docker-compose -f docker-compose-dev.yml down

docker-compose -f docker-compose-dev.yml up -d ca.cipbancos.org.br orderer.cipbancos.org.br

#### peer0 ####

red=$'\e[1;31m'
end=$'\e[0m'
if [[ $# -eq 0 ]] ; then
    echo "${red}Chaincode version is missing...${end}"
    exit 0
fi
set -ev

docker-compose -f docker-compose-dev.yml up -d peer0.cipbancos.org.br couchdb-peer0

docker exec --user root couchdb-peer0 /scripts/start.sh

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
docker-compose -f ./docker-compose-dev.yml up -d cli

#export CLI_PEER=peer0.cipbancos.org.br:7051

docker exec -e "CORE_PEER_ADDRESS=peer0.cipbancos.org.br:7051" -e "CORE_PEER_LOCALMSPID=CIPMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/cipbancos.org.br/users/Admin@cipbancos.org.br/msp" cli peer chaincode install -n minerva-app -v $1 -p github.com/minerva-app
docker exec -e "CORE_PEER_ADDRESS=peer0.cipbancos.org.br:7051" -e "CORE_PEER_LOCALMSPID=CIPMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/cipbancos.org.br/users/Admin@cipbancos.org.br/msp" cli peer chaincode instantiate -o orderer.cipbancos.org.br:7050 -C mychannel -n minerva-app -v $1 -c '{"Args":[""]}' -P "OR ('CIPMSP.member')"
sleep 10
# Invoke initLedger to populate the ledger.
docker exec -e "CORE_PEER_ADDRESS=peer0.cipbancos.org.br:7051" -e "CORE_PEER_LOCALMSPID=CIPMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/cipbancos.org.br/users/Admin@cipbancos.org.br/msp" cli peer chaincode invoke -o orderer.cipbancos.org.br:7050 -C mychannel -n minerva-app -c '{"function":"initLedger","Args":[""]}'

# Launch webapplication container.
docker-compose -f ./docker-compose-dev.yml up -d  webapp-peer0

###### peer1 #####

docker-compose -f docker-compose-dev.yml up -d peer1.cipbancos.org.br couchdb-peer1

# wait for Hyperledger Fabric to start
# incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
export FABRIC_START_TIMEOUT=5
#echo ${FABRIC_START_TIMEOUT}
sleep ${FABRIC_START_TIMEOUT}

# Fetch the channel
docker exec -e "CORE_PEER_LOCALMSPID=CIPMSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@cipbancos.org.br/msp" peer1.cipbancos.org.br peer channel fetch config -o orderer.cipbancos.org.br:7050 -c mychannel
# Join peer1.cipbancos.org.br to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=CIPMSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@cipbancos.org.br/msp" peer1.cipbancos.org.br peer channel join -b mychannel_config.block

docker exec -e "CORE_PEER_ADDRESS=peer1.cipbancos.org.br:7051" -e "CORE_PEER_LOCALMSPID=CIPMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/cipbancos.org.br/users/Admin@cipbancos.org.br/msp" cli peer chaincode install -n minerva-app -v $1 -p github.com/minerva-app
sleep 5

# Launch webapplication container.
docker-compose -f ./docker-compose-dev.yml up -d webapp-peer1

printf "\nTotal execution time : $(($(date +%s) - starttime)) secs ...\n\n"