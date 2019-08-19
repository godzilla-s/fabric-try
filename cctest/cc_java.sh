#!/bin/bash

source ../common-script/common.sh

channel=mychannel
ccName=SimpleJavax
ccVersion=0.1.2
ccPath=/opt/gopath/src/github.com/hyperledger/fabric/peer/chaincode/fabric-chaincode-example-maven
#ccPath=/opt/gopath/src/github.com/hyperledger/fabric/peer/chaincode/tracing_product/java-maven
endorserPolicy="OR('Org1MSP.member','Org2MSP.member')"
instancePolicy="AND('Org1MSP.admin')"

installCC() {
    echo "### install chaincode"
    execute peer0 org1 "peer chaincode install -n $ccName -l java -v $ccVersion -p $ccPath"
    execute peer1 org1 "peer chaincode install -n $ccName -l java -v $ccVersion -p $ccPath"
    execute peer0 org2 "peer chaincode install -n $ccName -l java -v $ccVersion -p $ccPath"
    execute peer1 org2 "peer chaincode install -n $ccName -l java -v $ccVersion -p $ccPath"
    sleep 1
    #execute peer0 org1 "peer chaincode instantiate -o orderer.example.com:7050 --tls true -l java --cafile $CA_FILE -C $channel -n $ccName -v $ccVersion -c {\"Args\":[\"init\"]} -P $endorserPolicy"
    execute peer0 org1 "peer chaincode instantiate -o orderer.example.com:7050 --tls true -l java --cafile $CA_FILE -C $channel -n $ccName -v $ccVersion -c {\"Args\":[\"init\",\"a\",\"100\",\"b\",\"250\"]} -P $endorserPolicy"
}

upgradeCC() {
    echo "### install chaincode"
    execute peer0 org1 "peer chaincode install -n $ccName -l java -v $ccVersion -p $ccPath"
    execute peer1 org1 "peer chaincode install -n $ccName -l java -v $ccVersion -p $ccPath"
    execute peer0 org2 "peer chaincode install -n $ccName -l java -v $ccVersion -p $ccPath"
    execute peer1 org2 "peer chaincode install -n $ccName -l java -v $ccVersion -p $ccPath"
    sleep 1
    #execute peer0 org1 "peer chaincode upgrade -o orderer.example.com:7050 --tls true -l java --cafile $CA_FILE -C $channel -n $ccName -v $ccVersion -c {\"Args\":[\"init\"]} -P $endorserPolicy"
    execute peer0 org1 "peer chaincode upgrade -o orderer.example.com:7050 --tls true -l java --cafile $CA_FILE -C $channel -n $ccName -v $ccVersion -c {\"Args\":[\"init\",\"a\",\"100\",\"b\",\"250\"]} -P $endorserPolicy"
}

#execute peer0 org1 "peer chaincode package -n $ccName -l java -v $ccVersion -p $ccPath -s -S -i $instancePolicy simple.out"
#installCC
#upgradeCC

#client peer0 org1 Admin "peer chaincode query -o orderer.example.com:7050  -C $channel -n $ccName -c {\"Args\":[\"{\\\"function\\\":\\\"save\\\",\\\"class\\\":\\\"asset.FarmPig\\\",\\\"args\\\":{\\\"id\\\":\\\"FP00005\\\",\\\"farmID\\\":\\\"FARM001\\\",\\\"quarantineCert\\\":\\\"QC10001\\\",\\\"quantity\\\":1000,\\\"batchNo\\\":\\\"00001\\\"}}\"]}"

#client peer0 org1 Admin "peer chaincode query -o orderer.example.com:7050  -C $channel -n $ccName -c {\"Args\":[\"{\\\"function\\\":\\\"get\\\",\\\"class\\\":\\\"asset.FarmPig\\\",\\\"args\\\":{\\\"id\\\":\\\"FP00004\\\"}}\"]}"

#client peer0 org1 Admin "peer chaincode query -o orderer.example.com:7050  -C $channel -n $ccName -c {\"Args\":[\"query\",\"a\"]}"
#sleep 2
#client peer0 org1 Admin "peer chaincode invoke -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"invoke\",\"a\",\"b\",\"15\"]}"
client peer0 org1 Admin "peer chaincode invoke -o orderer.example.com:7050  --tls true --cafile $CA_FILE -C mychannel -n $ccName -c {\"Args\":[\"invoke\",\"a\",\"b\",\"15\"]}"