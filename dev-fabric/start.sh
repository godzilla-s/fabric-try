#!/bin/bash 


# generate crypto files
cryptogen generate --config=./crypto.yaml 

sleep 0.5 

export FABRIC_CFG_PATH=$PWD/v1.4
echo $FABRIC_CFG_PATH
mkdir channel-config 
configtxgen --profile TwoOrgsOrdererGenesis -outputBlock channel-config/genesis.block 
configtxgen --profile TwoOrgsChannel -outputCreateChannelTx channel-config/mychannel.tx --channelID mychannel

configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate channel-config/Org1MSPanchors.tx -channelID mychannel -asOrg Org1MSP
#configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate channel-config/Org2MSPanchors.tx -channelID mychannel -asOrg Org2MSP

sleep 0.5 
docker-compose up -d 

sleep 0.5
# 启动ca
Org1CaCert=$(cd crypto-config/peerOrganizations/org1.example.com/ca; ls *.pem)
Org1CaKey=$(cd crypto-config/peerOrganizations/org1.example.com/ca; ls *_sk)
Org2CaCert=$(cd crypto-config/peerOrganizations/org2.example.com/ca; ls *.pem)
Org2CaKey=$(cd crypto-config/peerOrganizations/org2.example.com/ca; ls *_sk)
os=`uname -s`

if [ "$os" == "Darwin" ]; then 
  sed -i "" "s/ORG1_CA_CERTFILE=.*/ORG1_CA_CERTFILE=${Org1CaCert}/g" .env
  sed -i "" "s/ORG1_CA_KEYFILE=.*/ORG1_CA_KEYFILE=${Org1CaKey}/g" .env
  sed -i "" "s/ORG2_CA_CERTFILE=.*/ORG2_CA_CERTFILE=${Org2CaCert}/g" .env
  sed -i "" "s/ORG2_CA_KEYFILE=.*/ORG2_CA_KEYFILE=${Org2CaKey}/g" .env
else
  sed -i "s/ORG1_CA_CERTFILE=.*/ORG1_CA_CERTFILE=${Org1CaCert}/g" .env
  sed -i "s/ORG1_CA_KEYFILE=.*/ORG1_CA_KEYFILE=${Org1CaKey}/g" .env
  sed -i "s/ORG2_CA_CERTFILE=.*/ORG2_CA_CERTFILE=${Org2CaCert}/g" .env
  sed -i "s/ORG2_CA_KEYFILE=.*/ORG2_CA_KEYFILE=${Org2CaKey}/g" .env
fi 

#docker-compose -f docker-compose-ca.yaml up -d