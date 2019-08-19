#!/bin/bash

CA_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-files/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem

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

 execute peer0 org1 "peer channel create -o orderer.example.com:7050 -c mychannel -f ./channel-config/mychannel.tx --tls --cafile $CA_FILE"
 sleep 0.5

 execute peer0 org1 "peer channel join -b mychannel.block"
# execute peer0 org2 "peer channel join -b mychannel.block"

# sleep 0.5
# execute peer0 org1 "peer chaincode install -n myapp -v 0.0.1 -p github.com/hyperledger/fabric/peer/chaincode/marble"
# execute peer0 org2 "peer chaincode install -n myapp -v 0.0.1 -p github.com/hyperledger/fabric/peer/chaincode/marble"

# sleep 1
# execute peer0 org1 "peer chaincode instantiate -o orderer.example.com:7050 --tls --cafile $CA_FILE -C mychannel -n myapp -v 0.0.1 -c {\"Args\":[\"init\"]} -P OR('Org1MSP.peer','Org2MSP.peer')"
# sleep 2
# execute peer0 org1 "peer chaincode invoke -C mychannel --tls --cafile $CA_FILE -n myapp -c {\"Args\":[\"initMarble\",\"marble1\",\"blue\",\"35\",\"tom\"]}"
# execute peer0 org1 "peer chaincode invoke -C mychannel --tls --cafile $CA_FILE -n myapp -c {\"Args\":[\"initMarble\",\"marble4\",\"red\",\"54\",\"tom\"]}"
# execute peer0 org2 "peer chaincode invoke -C mychannel --tls --cafile $CA_FILE -n myapp -c {\"Args\":[\"initMarble\",\"marble2\",\"crayon\",\"70\",\"jim\"]}"
# execute peer0 org1 "peer chaincode invoke -C mychannel --tls --cafile $CA_FILE -n myapp -c {\"Args\":[\"initMarble\",\"marble3\",\"white\",\"49\",\"tim\"]}"

#execute peer0 org1 "peer chaincode query -C mychannel -n myapp -c {\"Args\":[\"queryMarbles\",\"{\\\"selector\\\":{\\\"docType\\\":\\\"marble\\\",\\\"owner\\\":\\\"tom\\\"},\\\"use_index\\\":[\\\"indexOwnerDoc\\\",\\\"indexOwner\\\"]}\"]}"
# 下面查询条件错误
#execute peer0 org1 "peer chaincode query -C mychannel -n myapp -c {\"Args\":[\"queryMarbles\",\"{\\\"selector\\\":{\\\"docType\\\":\\\"marble\\\",\\\"owner\\\":\\\"tom\\\",\\\"color\\\":\\\"red\\\"},\\\"use_index\\\":[\\\"indexOwnerDoc\\\",\\\"indexOwner\\\"]}\"]}"
#execute peer0 org1 "peer chaincode query -C mychannel -n myapp -c {\"Args\":[\"queryMarbles\",\"{\\\"selector\\\":{\\\"docType\\\":\\\"marble\\\",\\\"owner\\\":\\\"tim\\\"},\\\"use_index\\\":[\\\"indexOwnerDoc\\\",\\\"indexOwner\\\"]}\"]}"
#execute peer0 org2 "peer chaincode query -C mychannel -n myapp -c {\"Args\":[\"readMarble\",\"marble1\"]}"
#execute peer0 org1 "peer chaincode invoke -C mychannel --tls --cafile $CA_FILE -n myapp -c {\"Args\":[\"transferMarble\",\"marble1\",\"Jackson\"]}"

## 删除
#execute peer0 org1 "peer chaincode invoke -C mychannel --tls --cafile $CA_FILE -n myapp -c {\"Args\":[\"delete\",\"marble3\"]}"
#sleep 0.5
#execute peer0 org1 "peer chaincode query -C mychannel -n myapp -c {\"Args\":[\"readMarble\",\"marble3\"]}"
## 新增检索
# curl -i -X POST -H "Content-Type: application/json" -d "{\"index\":{\"fields\":[\"owner\"]},
#          \"name\":\"indexOwner1\",
#          \"ddoc\":\"indexOwnerDoc1\",
#          \"type\":\"json\"}" http://localhost:5984/mychannel_myapp/_index