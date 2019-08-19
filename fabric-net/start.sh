#!/bin/bash 

source ../common-script/args.sh 

parseArgs $@

setImageTag

# generate crypto files
generate() {
  echo ""
  echo "### 🍺 generate cryptofiles with version $configDir"
  set -e 
  cryptogen generate --config=./$configDir/crypto.yaml
  set +e 

  sleep 0.5 

  export FABRIC_CFG_PATH=$PWD/$configDir
  mkdir channel-config 
  echo ""
  echo "### 🍺 create genesis block"
  set +e 
  if [ "$ordererType" == "solo" ]; then 
    echo "------ solo"
    configtxgen --profile TwoOrgsOrdererGenesis -outputBlock channel-config/genesis.block 
  elif [ "$ordererType" == "kafka" ]; then 
    configtxgen --profile SampleDevModeKafka -outputBlock channel-config/genesis.block 
  elif [ "$ordererType" == "raft" ]; then 
    configtxgen --profile SampleMultiNodeEtcdRaft -outputBlock channel-config/genesis.block 
  else 
    echo "unkown orderer type:$ordererType"
    exit 1
  fi 
  set -e 
  #configtxgen --profile SampleMultiNodeEtcdRaft -outputBlock channel-config/gensis-etcd.block 

  echo ""
  echo "### 🍺 create channel configfile"
  set -e
  configtxgen --profile TwoOrgsChannel -outputCreateChannelTx channel-config/mychannel.tx --channelID mychannel
  set +e 

  echo ""
  echo "### 🍺 create update anchor file"
  set -e
  configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate channel-config/Org1MSPanchors.tx -channelID mychannel -asOrg Org1MSP
  configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate channel-config/Org2MSPanchors.tx -channelID mychannel -asOrg Org2MSP
  set +e 
}

startCA() {
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
  docker-compose -f docker-ca.yaml up -d
}
startup() {
  echo ""
  echo "### ☕️ start fabric network ☕️ "
  if [ "$ordererType" == "solo" ]; then 
    docker-compose -f docker-orderer-solo.yaml up -d 
  elif [ "$ordererType" == "kafka" ]; then 
    docker-compose -f docker-kafka.yaml up -d 
    sleep 1
    docker-compose -f docker-orderer-kafka.yaml up -d 
  elif [ "$ordererType" == "raft" ]; then 
    docker-compose -f docker-orderer-raft.yaml up -d 
  fi 
  
  # start couchdb if set couchdb
  if [ "$couchdb" == "true" ]; then
    sleep 0.5
    docker-compose -f docker-couchdb.yaml up -d 
  fi 

  sleep 0.5
  docker-compose up -d 

 

  if [ "$ca" == "true" ]; then 
    sleep 0.5
    startCA 
  fi
  echo "### fabric start ok ###"
}

if [ "$action" == "up" ]; then
  generate
  sleep 0.5
  startup 
elif [ "$action" == "down" ]; then 
  ./stop.sh
elif [ "$action" == "start" ]; then 
  echo "start fabric"
  if [ "$ca" == "true" ]; then 
    startCA
  fi 
fi 
