#!/bin/bash

source ../common-script/common.sh

channel=mychannel
ccName=produce_tracing2
ccVersion=0.5
ccPath=github.com/hyperledger/fabric/peer/chaincode/produce_tracing2
endorserPolicy="OR('Org1MSP.member','Org2MSP.member')"

install() {
    localInstallCC $channel $ccName $ccVersion $ccPath "{\"Args\":[\"init\"]}" "OR('Org1MSP.member','Org2MSP.member')"
}

installCC() {
    echo "### install chaincode"
    execute peer0 org1 "peer chaincode install -n $ccName -v $ccVersion -p $ccPath"
    execute peer1 org1 "peer chaincode install -n $ccName -v $ccVersion -p $ccPath"
    execute peer0 org2 "peer chaincode install -n $ccName -v $ccVersion -p $ccPath"
    execute peer1 org2 "peer chaincode install -n $ccName -v $ccVersion -p $ccPath"
    sleep 1
    execute peer0 org1 "peer chaincode instantiate -o orderer.example.com:7050 --tls true --cafile $CA_FILE -C $channel -n $ccName -v $ccVersion -c {\"Args\":[\"init\"]} -P $endorserPolicy"
}

updateChaincode() {
    echo "### install chaincode"
    execute peer0 org1 "peer chaincode install -n $ccName -v $ccVersion -p $ccPath"
    execute peer1 org1 "peer chaincode install -n $ccName -v $ccVersion -p $ccPath"
    execute peer0 org2 "peer chaincode install -n $ccName -v $ccVersion -p $ccPath"
    execute peer1 org2 "peer chaincode install -n $ccName -v $ccVersion -p $ccPath"
    sleep 1
    execute peer0 org1 "peer chaincode upgrade -o orderer.example.com:7050 --tls true --cafile $CA_FILE -C $channel -n $ccName -v $ccVersion -c {\"Args\":[\"init\"]} -P $endorserPolicy"
}

function test() {
    client peer0 org1 Admin "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"{\\\"function\\\":\\\"save\\\",\\\"class\\\":\\\"participant.Farm\\\",\\\"args\\\":{\\\"id\\\":\\\"FM00001\\\",\\\"name\\\":\\\"RedStartPigFarm\\\",\\\"address\\\":\\\"ShenZhenLonggang\\\"}}\"]}"
    sleep 2
    client peer0 org2 Admin "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"{\\\"function\\\":\\\"save\\\",\\\"class\\\":\\\"participant.Farm\\\",\\\"args\\\":{\\\"id\\\":\\\"FM00002\\\",\\\"name\\\":\\\"BlueStartPigFarm\\\",\\\"address\\\":\\\"ShenZhenLonggang\\\"}}\"]}"
}

function query() {
    client peer0 org1 Admin "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"{\\\"function\\\":\\\"get\\\",\\\"class\\\":\\\"participant.Farm\\\",\\\"args\\\":{\\\"id\\\":\\\"FM00001\\\"}}\"]}"
    client peer0 org2 Admin "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"{\\\"function\\\":\\\"get\\\",\\\"class\\\":\\\"participant.Farm\\\",\\\"args\\\":{\\\"id\\\":\\\"FM00001\\\"}}\"]}"
}

testAsset() {
    client peer0 org1 Admin "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"{\\\"function\\\":\\\"save\\\",\\\"class\\\":\\\"asset.FarmPig\\\",\\\"args\\\":{\\\"id\\\":\\\"PF00009\\\",\\\"txdate\\\":\\\"2019-07-31:14:55:30\\\",\\\"quarantine\\\":\\\"QC000000003\\\",\\\"quantity\\\":5200}}\"]}"
    #client peer0 org2 Admin "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"{\\\"function\\\":\\\"save\\\",\\\"class\\\":\\\"asset.FarmPig\\\",\\\"args\\\":{\\\"id\\\":\\\"PF00010\\\",\\\"txdate\\\":\\\"2019-07-31:15:00:30\\\",\\\"quarantine\\\":\\\"QC000000003\\\",\\\"quantity\\\":5300}}\"]}"
}

testAssetQuery() {
    client peer0 org1 Admin "peer chaincode query -o orderer.example.com:7050  -C $channel -n $ccName -c {\"Args\":[\"{\\\"function\\\":\\\"query\\\",\\\"class\\\":\\\"asset.FarmPig\\\",\\\"args\\\":{\\\"id\\\":\\\"PF00009\\\"}}\"]}"
    #client peer0 org2 Admin "peer chaincode query -o orderer.example.com:7050  -C $channel -n $ccName -c {\"Args\":[\"{\\\"function\\\":\\\"get\\\",\\\"class\\\":\\\"asset.FarmPig\\\",\\\"args\\\":{\\\"id\\\":\\\"PF00009\\\"}}\"]}"
}

testAssetDelete() {
    client peer0 org1 Admin "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"{\\\"function\\\":\\\"delete\\\",\\\"class\\\":\\\"asset.FarmPigInfo\\\",\\\"args\\\":{\\\"id\\\":\\\"PF00009\\\"}}\"]}"
}

testAssetAuth() {
    client peer0 org2 Admin "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"{\\\"function\\\":\\\"auth\\\",\\\"class\\\":\\\"asset.FarmPigInfo\\\",\\\"args\\\":{\\\"Org1MSP\\\":\\\"readWrite\\\"}}\"]}"
}

testAssetUnAuth() {
    client peer0 org1 Admin "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"{\\\"function\\\":\\\"unauth\\\",\\\"class\\\":\\\"asset.FarmPigInfo\\\",\\\"args\\\":[\\\"Org2MSP\\\"]}\"]}"
}

#installCC

#updateChaincode

#test

#query
#testAsset

#testAssetAuth
#testAssetUnAuth
testAssetQuery
#testAssetUnAuth
#testAssetDelete
#client peer0 org1 Admin "peer chaincode query -o orderer.example.com:7050  -C $channel -n $ccName -c {\"Args\":[\"{\\\"function\\\":\\\"getAuth\\\",\\\"class\\\":\\\"asset.FarmPigInfo\\\"}\"]}"