#!/bin/bash

CA_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-files/ordererOrganizations/example.com/msp/tlscacerts/tls-localhost-8054.pem

function execute() {
  org=$2
  peer=$1
  cmd=$3
  mspid=""
  case $org in
    "org1")
      mspid=Org1MSP
      ;;
    "org2")
      mspid=Org2MSP
      ;;
    "org3")
      mspid=Org3MSP
      ;;
  esac
  echo "==> $peer.$org[$mspid]: $cmd"
  docker exec -t -e CORE_PEER_LOCALMSPID=$mspid \
      -e CORE_PEER_ADDRESS=$peer.$org.example.com:7051 \
      -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-files/peerOrganizations/$org.example.com/users/Admin@$org.example.com/msp \
      -e CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-files/peerOrganizations/$org.example.com/peers/$peer.$org.example.com/tls/server.crt \
      -e CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-files/peerOrganizations/$org.example.com/peers/$peer.$org.example.com/tls/server.key \
      -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-files/peerOrganizations/$org.example.com/peers/$peer.$org.example.com/tls/ca.crt \
      -t client $cmd
}

#cryptogen generate --config=./crypto.yaml

test() {
    # execute peer0 org1 "peer channel create -o orderer.example.com:7050 --tls --cafile $CA_FILE -c mychannel -f ./channel-config/mychannel.tx"
    # sleep 2
    execute peer0 org1 "peer channel join -b mychannel.block"
    execute peer0 org2 "peer channel join -b mychannel.block"
    # sleep 1
    # execute peer0 org1 "peer chaincode install -n simple -v 0.0.1 -p github.com/hyperledger/fabric/peer/chaincode/simple"
    # execute peer0 org2 "peer chaincode install -n simple -v 0.0.1 -p github.com/hyperledger/fabric/peer/chaincode/simple"
    # sleep 2
    # execute peer0 org1 "peer chaincode instantiate -o orderer.example.com:7050 --tls true --cafile $CA_FILE -C mychannel -n simple -v 0.0.1 -c {\"Args\":[\"init\"]} -P OR('Org1MSP.member','Org2MSP.member')"
    # echo "instantiate ok"
    # sleep 3
    # execute peer0 org1 "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C mychannel -n simple -c {\"Args\":[\"set\",\"a\",\"2000\"]}"
    # execute peer0 org2 "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C mychannel -n simple -c {\"Args\":[\"set\",\"b\",\"3000\"]}"
    # sleep 2
    # execute peer0 org1 "peer chaincode query -o orderer.example.com:7050 -C mychannel -n simple -c {\"Args\":[\"get\",\"a\",\"b\"]}"
}

if [ "$1" == "init" ]; then
    configtxgen --profile TwoOrgsOrdererGenesis -outputBlock channel-config/genesis.block
    configtxgen --profile TwoOrgsChannel -outputCreateChannelTx channel-config/mychannel.tx --channelID mychannel
    docker-compose up -d
elif [ "$1" == "test" ]; then
    test
elif [ "$1" == "clean" ]; then
    docker-compose down
    docker volume prune -f
    docker rm -f $(docker ps -a | grep dev | awk '{print $1}')
    docker rmi -f $(docker images | grep dev | awk '{print $3}')
    rm -f channel-config/*
fi