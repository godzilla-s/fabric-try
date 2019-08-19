#!/bin/bash

source ../common-script/common.sh

channel=mychannel
ccName=produce_tracing
ccName2=produce_tracing
ccVersion=0.0.3
ccPath=github.com/hyperledger/fabric/peer/chaincode/produce_tracing
endorserPolicy="OR('Org1MSP.member','Org2MSP.member')"

install() {
    localInstallCC $channel $ccName $ccVersion $ccPath "{\"Args\":[\"init\"]}" "OR('Org1MSP.member','Org2MSP.member')"
}

installWithColl() {
    echo "### 🍺 update channel"
    execute peer0 org1 "peer channel update -o orderer.example.com:7050 -c $channel -f ./channel-config/Org1MSPanchors.tx --tls --cafile $CA_FILE"
    execute peer0 org2 "peer channel update -o orderer.example.com:7050 -c $channel -f ./channel-config/Org2MSPanchors.tx --tls --cafile $CA_FILE"
    sleep 2
    echo "### install chaincode"
    execute peer0 org1 "peer chaincode install -n $ccName2 -v $ccVersion -p $ccPath"
    execute peer1 org1 "peer chaincode install -n $ccName2 -v $ccVersion -p $ccPath"
    execute peer0 org2 "peer chaincode install -n $ccName2 -v $ccVersion -p $ccPath"
    execute peer1 org2 "peer chaincode install -n $ccName2 -v $ccVersion -p $ccPath"
    sleep 1
    execute peer0 org1 "peer chaincode instantiate -o orderer.example.com:7050 --tls true --cafile $CA_FILE -C $channel -n $ccName2 -v $ccVersion -c {\"Args\":[\"init\"]} -P $endorserPolicy --collections-config ./chaincode/produce_tracing/data_collection.json"
}

updateChaincodeWithColl() {
    echo "### install chaincode"
    execute peer0 org1 "peer chaincode install -n $ccName2 -v $ccVersion -p $ccPath"
    execute peer1 org1 "peer chaincode install -n $ccName2 -v $ccVersion -p $ccPath"
    execute peer0 org2 "peer chaincode install -n $ccName2 -v $ccVersion -p $ccPath"
    execute peer1 org2 "peer chaincode install -n $ccName2 -v $ccVersion -p $ccPath"
    sleep 1
    execute peer0 org1 "peer chaincode upgrade -o orderer.example.com:7050 --tls true --cafile $CA_FILE -C $channel -n $ccName2 -v $ccVersion -c {\"Args\":[\"init\"]} -P $endorserPolicy --collections-config ./chaincode/produce_tracing/data_collection.json"
}

function test() {
    client peer0 org1 Admin "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"{\\\"function\\\":\\\"save\\\",\\\"class\\\":\\\"participant.Farm\\\",\\\"coll\\\":\\\"*\\\",\\\"data\\\":{\\\"id\\\":\\\"FM12345\\\",\\\"name\\\":\\\"RedStartPigFarm\\\",\\\"address\\\":\\\"ShenZhenLonggang\\\"}}\"]}"
    sleep 2
    client peer0 org2 Admin "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"{\\\"function\\\":\\\"save\\\",\\\"class\\\":\\\"participant.Farm\\\",\\\"coll\\\":\\\"*\\\",\\\"data\\\":{\\\"id\\\":\\\"FM34567\\\",\\\"name\\\":\\\"BlueStartPigFarm\\\",\\\"address\\\":\\\"ShenZhenLonggang\\\"}}\"]}"
}

function query() {
    client peer0 org1 Admin "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"{\\\"function\\\":\\\"get\\\",\\\"class\\\":\\\"participant.Farm\\\",\\\"coll\\\":\\\"*\\\",\\\"data\\\":{\\\"id\\\":\\\"FM12345\\\"}}\"]}"
    client peer0 org2 Admin "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"{\\\"function\\\":\\\"get\\\",\\\"class\\\":\\\"participant.Farm\\\",\\\"coll\\\":\\\"*\\\",\\\"data\\\":{\\\"id\\\":\\\"FM34567\\\"}}\"]}"
}

function testWithColl() {
    client peer0 org1 Admin "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $channel -n $ccName2 -c {\"Args\":[\"{\\\"function\\\":\\\"save\\\",\\\"class\\\":\\\"participant.Farm\\\",\\\"coll\\\":\\\"farm\\\",\\\"data\\\":{\\\"id\\\":\\\"FM00001\\\",\\\"name\\\":\\\"RedStartPigFarm\\\",\\\"address\\\":\\\"ShenZhenLonggang\\\"}}\"]}"
    sleep 2
    client peer0 org2 Admin "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $channel -n $ccName2 -c {\"Args\":[\"{\\\"function\\\":\\\"save\\\",\\\"class\\\":\\\"participant.Farm\\\",\\\"coll\\\":\\\"farm\\\",\\\"data\\\":{\\\"id\\\":\\\"FM00002\\\",\\\"name\\\":\\\"BlueStartPigFarm\\\",\\\"address\\\":\\\"ShenZhenLonggang\\\"}}\"]}"
    sleep 2
    client peer0 org1 Admin "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $channel -n $ccName2 -c {\"Args\":[\"{\\\"function\\\":\\\"save\\\",\\\"class\\\":\\\"participant.Slaughterhouse\\\",\\\"coll\\\":\\\"slaughterhouse\\\",\\\"data\\\":{\\\"id\\\":\\\"SL00001\\\",\\\"name\\\":\\\"GraySkySlaughter\\\",\\\"address\\\":\\\"ShenZhenBao'anShajin\\\"}}\"]}"
    sleep 2
    client peer0 org2 Admin "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $channel -n $ccName2 -c {\"Args\":[\"{\\\"function\\\":\\\"save\\\",\\\"class\\\":\\\"participant.Slaughterhouse\\\",\\\"coll\\\":\\\"slaughterhouse\\\",\\\"data\\\":{\\\"id\\\":\\\"SL00002\\\",\\\"name\\\":\\\"GraySkySlaughter\\\",\\\"address\\\":\\\"ShenZhenBao'anShajin\\\"}}\"]}"
    sleep 2
    client peer0 org1 Admin "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $channel -n $ccName2 -c {\"Args\":[\"{\\\"function\\\":\\\"save\\\",\\\"class\\\":\\\"asset.PigFarmInfo\\\",\\\"coll\\\":\\\"PigFarmInfo\\\",\\\"data\\\":{\\\"id\\\":\\\"PFI00001\\\",\\\"farm\\\":{\\\"id\\\":\\\"FM11111\\\"},\\\"saleTime\\\":\\\"2019-07-19:14:55\\\",\\\"batchNo\\\":\\\"NO0001\\\",\\\"qcert\\\":\\\"QC000000001\\\",\\\"quantity\\\":5000}}\"]}"
    sleep 1
    client peer0 org1 Admin "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $channel -n $ccName2 -c {\"Args\":[\"{\\\"function\\\":\\\"save\\\",\\\"class\\\":\\\"asset.PigFarmInfo\\\",\\\"coll\\\":\\\"PigFarmInfo\\\",\\\"data\\\":{\\\"id\\\":\\\"PFI00002\\\",\\\"farm\\\":{\\\"id\\\":\\\"FM11111\\\"},\\\"saleTime\\\":\\\"2019-07-19:14:55\\\",\\\"batchNo\\\":\\\"NO0001\\\",\\\"qcert\\\":\\\"QC000000002\\\",\\\"quantity\\\":5200}}\"]}"
}

function queryWithColl() {
    client peer0 org1 Admin "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName2 -c {\"Args\":[\"{\\\"function\\\":\\\"get\\\",\\\"class\\\":\\\"participant.Farm\\\",\\\"coll\\\":\\\"farm\\\",\\\"data\\\":{\\\"id\\\":\\\"FM00001\\\"}}\"]}"
    client peer0 org2 Admin "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName2 -c {\"Args\":[\"{\\\"function\\\":\\\"get\\\",\\\"class\\\":\\\"participant.Farm\\\",\\\"coll\\\":\\\"farm\\\",\\\"data\\\":{\\\"id\\\":\\\"FM00002\\\"}}\"]}"
    client peer0 org1 Admin "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName2 -c {\"Args\":[\"{\\\"function\\\":\\\"get\\\",\\\"class\\\":\\\"participant.Slaughterhouse\\\",\\\"coll\\\":\\\"slaughterhouse\\\",\\\"data\\\":{\\\"id\\\":\\\"SL00001\\\"}}\"]}"
    client peer0 org2 Admin "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName2 -c {\"Args\":[\"{\\\"function\\\":\\\"get\\\",\\\"class\\\":\\\"participant.Slaughterhouse\\\",\\\"coll\\\":\\\"slaughterhouse\\\",\\\"data\\\":{\\\"id\\\":\\\"SL00002\\\"}}\"]}"
    client peer0 org1 Admin "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName2 -c {\"Args\":[\"{\\\"function\\\":\\\"get\\\",\\\"class\\\":\\\"asset.PigFarmInfo\\\",\\\"coll\\\":\\\"PigFarmInfo\\\",\\\"data\\\":{\\\"id\\\":\\\"PFI00001\\\"}}\"]}"
    client peer0 org2 Admin "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName2 -c {\"Args\":[\"{\\\"function\\\":\\\"get\\\",\\\"class\\\":\\\"asset.PigFarmInfo\\\",\\\"coll\\\":\\\"PigFarmInfo\\\",\\\"data\\\":{\\\"id\\\":\\\"PFI00002\\\"}}\"]}"
}

#install
#sleep 1
#installWithColl

#updateChaincodeWithColl
#test

#query

#testWithColl

queryWithColl