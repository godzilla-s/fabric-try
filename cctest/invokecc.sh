#!/bin/bash 

source ../common-script/common.sh

channel=mychannel
ccName=invokecc 
ccVersion=0.0.1 
ccPath=github.com/hyperledger/fabric/peer/chaincode/invokecc

source ../common-script/common.sh

#installChaincode $channel $ccName $ccVersion $ccPath "{\"Args\":[\"init\"]}" "OR('Org1MSP.member','Org2MSP.member')"

testInvoke() {
    execute peer0 org1 "peer chaincode invoke -o orderer.example.com:7050 --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"priv_cck0\",\"mychannel\",\"set\",\"h\",\"8000\"]}"
    execute peer0 org2 "peer chaincode invoke -o orderer.example.com:7050 --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"priv_cck0\",\"mychannel\",\"set\",\"j\",\"9000\"]}"

    execute peer0 org1 "peer chaincode query -o orderer.example.com:7050 -C $channel -n simple -c {\"Args\":[\"get\",\"h\",\"j\"]}"
    execute peer0 org2 "peer chaincode query -o orderer.example.com:7050 -C $channel -n simple -c {\"Args\":[\"get\",\"h\",\"j\"]}"
}

if [ "$1" == "-test" ]; then 
    echo "test function $2"
    echo `$2`
else
    echo "todo"
fi 