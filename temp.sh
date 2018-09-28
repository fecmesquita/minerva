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
# Join peer0.cipbancos.org.br to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=CIPMSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@cipbancos.org.br/msp" peer1.cipbancos.org.br peer channel join -b mychannel_config.block

# Now launch the CLI container in order to install and instantiate chaincode
#docker-compose -f ./docker-compose-dev.yml up -d cli

docker exec -e "CORE_PEER_ADDRESS=peer1.cipbancos.org.br:7061" -e "CORE_PEER_LOCALMSPID=CIPMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/cipbancos.org.br/users/Admin@cipbancos.org.br/msp" cli peer chaincode install -n minerva-app -v $1 -p github.com/minerva-app
sleep 5

# Launch webapplication container.
docker-compose -f ./docker-compose-dev.yml up -d webapp-peer1

printf "\nTotal execution time : $(($(date +%s) - starttime)) secs ...\n\n"