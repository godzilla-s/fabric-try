#!/bin/bash 

source ../common-script/common.sh

channel=mychannel
ccName=example
ccVersion=0.1
ccPath=github.com/hyperledger/fabric/peer/chaincode/example

install() {
    localInstallCC $channel $ccName $ccVersion $ccPath "{\"Args\":[\"init\"]}" "OR('Org1MSP.member','Org2MSP.member')"
}

testSetKVS() {
    execute peer0 org1 "peer chaincode invoke -o orderer.example.com:7050 --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"setkvs\",\"fox\",\"Org1MSP\"]}"
    #sleep 2

    #execute peer0 org1 "peer chaincode invoke -o orderer.example.com:7050 --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"setAuth\",\"pig\",\"Org1MSP\"]}"
    sleep 2
    execute peer0 org2 "peer chaincode invoke -o orderer.example.com:7050 --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"set\",\"pig\",\"6690\"]}"
    sleep 2
    execute peer0 org1 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"get\",\"pig\"]}"
    execute peer0 org2 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"get\",\"pig\"]}"

    execute peer0 org1 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"getAuth\",\"fox\"]}"
    execute peer0 org2 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"getAuth\",\"pig\"]}"
    #sleep 2
    #execute peer0 org2 "peer chaincode invoke -o orderer.example.com:7050 --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"set\",\"fox\",\"3600\"]}"
    #sleep 2
    #execute peer0 org1 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"get\",\"fox\"]}"
    #execute peer0 org2 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"get\",\"fox\"]}"
}

testAddOrgs() {
    execute peer0 org1 "peer chaincode invoke -o orderer.example.com:7050 --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"setkvs\",\"apple\",\"Org1MSP\"]}"
    sleep 2
    execute peer0 org1 "peer chaincode invoke -o orderer.example.com:7050 --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"set\",\"apple\",\"250\"]}"
    sleep 2
    execute peer0 org1 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"get\",\"apple\"]}"
    execute peer0 org2 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"get\",\"apple\"]}"
    sleep 2
    execute peer0 org2 "peer chaincode invoke -o orderer.example.com:7050 --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"set\",\"apple\",\"380\"]}"
    sleep 2
    execute peer0 org1 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"get\",\"apple\"]}"
    execute peer0 org2 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"get\",\"apple\"]}"

    execute peer0 org2 "peer chaincode invoke -o orderer.example.com:7050 --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"addorg\",\"Org2MSP\"]}"
    sleep 2
    execute peer0 org2 "peer chaincode invoke -o orderer.example.com:7050 --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"set\",\"apple\",\"450\"]}"
    sleep 2
    execute peer0 org1 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"get\",\"apple\"]}"
    execute peer0 org2 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"get\",\"apple\"]}"
}

testDelOrgs() {
    execute peer0 org1 "peer chaincode invoke -o orderer.example.com:7050 --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"setkvs\",\"banana\",\"Org1MSP\",\"Org2MSP\"]}"
    sleep 2
    execute peer0 org1 "peer chaincode invoke -o orderer.example.com:7050 --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"set\",\"banana\",\"280\"]}"
    sleep 2
    execute peer0 org1 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"get\",\"banana\"]}"
    execute peer0 org2 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"get\",\"banana\"]}"
    sleep 2
    execute peer0 org2 "peer chaincode invoke -o orderer.example.com:7050 --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"set\",\"banana\",\"320\"]}"
    sleep 2
    execute peer0 org1 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"get\",\"banana\"]}"
    execute peer0 org2 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"get\",\"banana\"]}"

    #delete org2
    execute peer0 org2 "peer chaincode invoke -o orderer.example.com:7050 --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"delorg\",\"Org2MSP\"]}"
    sleep 2
    execute peer0 org2 "peer chaincode invoke -o orderer.example.com:7050 --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"set\",\"banana\",\"500\"]}"
    sleep 2
    # 预期值不会被变更
    execute peer0 org1 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"get\",\"banana\"]}"
    execute peer0 org2 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"get\",\"banana\"]}"
}

testSet() {
    execute peer0 org1 "peer chaincode invoke -o orderer.example.com:7050 --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"set\",\"x\",\"4000\"]}"
    sleep 2
    execute peer0 org1 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"get\",\"x\"]}"
    execute peer0 org2 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"get\",\"x\"]}"
    sleep 2
    execute peer0 org1 "peer chaincode invoke -o orderer.example.com:7050 --tls --cafile $CA_FILE -C $channel -n $ccName -c {\"Args\":[\"set\",\"x\",\"6000\"]}"
    sleep 2
    execute peer0 org1 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"get\",\"x\"]}"
    execute peer0 org2 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"get\",\"x\"]}"
}

#execute peer0 org1 "peer chaincode upgrade -o orderer.example.com:7050 --tls true --cafile $CA_FILE -C $channel -n $ccName -v $ccVersion -c {\"Args\":[\"init\"]} OR('Org1MSP.member','Org2MSP.member')"
#install
#testSetKVS

#testAddOrgs
#testSet

#execute peer0 org1 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"get\",\"apple\"]}"
#execute peer0 org2 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"get\",\"apple\"]}"

execute peer0 org1 "peer chaincode query -o orderer.example.com:7050 -C $channel -n $ccName -c {\"Args\":[\"getinfo\"]}"
