#!/bin/bash 

#========================================
#  手动添加组织
#========================================

CA_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-files/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem

# 生成org3的证书 
cryptogen generate --config=./org3/crypto.yaml
workdir="/opt/gopath/src/github.com/hyperledger/fabric/peer/temp"

function action() {
    cmd=$1
    echo "==> $cmd"
    docker exec -t -w $workdir client bash -c "$cmd"
}

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
      -t -w $workdir client $cmd
}



function updateChannelWithOrg3() {
    # 下面步骤是操作更新创世通道的配置，将组织3的信息加入到联盟通道的配置中去。
    export FABRIC_CFG_PATH=$PWD/org3
    configtxgen -printOrg Org3MSP > ./temp/org3.json
    action "peer channel fetch config config_block.pb -o orderer.example.com:7050 -c mychannel --tls --cafile $CA_FILE"
    sleep 0.5
    action "configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json"
    sleep 0.5
    action "jq -s '.[0]*{\"channel_group\":{\"groups\":{\"Application\":{\"groups\":{\"Org3MSP\":.[1]}}}}}' config.json org3.json > newconfig.json"
    sleep 0.5
    action "configtxlator proto_encode --input config.json --type common.Config --output config.pb"
    sleep 0.5
    action "configtxlator proto_encode --input newconfig.json --type common.Config --output newconfig.pb"
    sleep 0.5
    action "configtxlator compute_update --channel_id mychannel --original config.pb --updated newconfig.pb --output org3_update.pb"
    sleep 0.5
    action "configtxlator proto_decode --input org3_update.pb --type common.ConfigUpdate | jq . > org3_update.json"
    sleep 0.5
    action "echo '{\"payload\":{\"header\":{\"channel_header\":{\"channel_id\":\"mychannel\",\"type\":2}},\"data\":{\"config_update\":$(cd temp;cat org3_update.json)}}}' | jq . > org3_update_in_envelope.json"
    sleep 0.5
    action "configtxlator proto_encode --input org3_update_in_envelope.json --type common.Envelope --output org3_update_in_envelope.pb"
    sleep 0.5
    action "peer channel signconfigtx -f org3_update_in_envelope.pb"
    sleep 0.5
    execute peer0 org2 "peer channel update -f org3_update_in_envelope.pb -c mychannel -o orderer.example.com:7050 --tls --cafile $CA_FILE"
    action "peer channel getinfo -c mychannel"

    #echo '{"payload":{"header":{"channel_header":{"channel_id":"mychannel","type":2}},"data":{"config_update":'$(cat org3_update.json)'}}}' | jq . > org3_update_in_envelope.json
}

# 启动组织3
# docker-compose -f docker-compose-org3.yaml up -d 
# sleep 1

# execute peer0 org3 "peer channel join -b ../mychannel.block"
# sleep 0.5
# execute peer0 org3 "peer channel getinfo -c mychannel"
# execute peer0 org1 "peer chaincode install -n myapp -v 0.0.2 -p github.com/hyperledger/fabric/peer/chaincode/example01"
# execute peer0 org2 "peer chaincode install -n myapp -v 0.0.2 -p github.com/hyperledger/fabric/peer/chaincode/example01"
# execute peer0 org3 "peer chaincode install -n myapp -v 0.0.2 -p github.com/hyperledger/fabric/peer/chaincode/example01"

# sleep 1
# execute peer0 org1 "peer chaincode upgrade -o orderer.example.com:7050 --tls --cafile $CA_FILE -C mychannel -n myapp -v 0.0.2 -c {\"Args\":[\"init\",\"a\",\"60000\",\"b\",\"54000\"]} -P OR('Org1MSP.member','Org2MSP.member','Org3MSP.member')"
# sleep 3
execute peer0 org1 "peer chaincode query -C mychannel -n myapp -c {\"Args\":[\"query\",\"name\"]}"
execute peer0 org2 "peer chaincode query -C mychannel -n myapp -c {\"Args\":[\"query\",\"b\"]}"
execute peer0 org3 "peer chaincode query -C mychannel -n myapp -c {\"Args\":[\"query\",\"b\",\"time\",\"name\",\"nation\"]}"