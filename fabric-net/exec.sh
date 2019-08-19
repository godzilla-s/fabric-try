#!/bin/bash 

ChannelName=mychannel
CCName=myapp 
CCVersion=0.0.1

source ../common-script/common.sh

echo ""
echo "### 🍺 create and join channel"
execute peer0 org1 "peer channel create -o orderer.example.com:7050 -c $ChannelName -f ./channel-config/mychannel.tx --tls --cafile $CA_FILE"
sleep 0.5
execute peer0 org1 "peer channel join -b mychannel.block"
execute peer1 org1 "peer channel join -b mychannel.block"
execute peer0 org2 "peer channel join -b mychannel.block"
execute peer1 org2 "peer channel join -b mychannel.block"

# sleep 1
# echo ""
# echo "### 🍺 update channel"
# execute peer0 org1 "peer channel update -o orderer.example.com:7050 -c $ChannelName -f ./channel-config/Org1MSPanchors.tx --tls --cafile $CA_FILE"
# execute peer0 org2 "peer channel update -o orderer.example.com:7050 -c $ChannelName -f ./channel-config/Org2MSPanchors.tx --tls --cafile $CA_FILE"

execute peer0 org1 "peer chaincode list --installed"