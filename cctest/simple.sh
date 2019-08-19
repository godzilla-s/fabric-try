#!/bin/bash

ChannelName=mychannel
CCName=priv_cck0
CCVersion=0.0.1
withPvt=false

endorserPolicy="OR('Org1MSP.member','Org2MSP.member')"
instancePolicy="AND('Org1MSP.admin')"

source ../common-script/common.sh 

function localInstallAndInstance() {
    echo "🍺 安装链码，本地安装"
    execute peer0 org1 "peer chaincode install -n $CCName -v $CCVersion -p github.com/hyperledger/fabric/peer/chaincode/simple"
    execute peer1 org1 "peer chaincode install -n $CCName -v $CCVersion -p github.com/hyperledger/fabric/peer/chaincode/simple"
    execute peer0 org2 "peer chaincode install -n $CCName -v $CCVersion -p github.com/hyperledger/fabric/peer/chaincode/simple"
    execute peer1 org2 "peer chaincode install -n $CCName -v $CCVersion -p github.com/hyperledger/fabric/peer/chaincode/simple"
    echo "🍺 实例化链码"
    if [ "$withPvt" == "true" ]; then 
        execute peer0 org1 "peer chaincode instantiate -o orderer.example.com:7050 --tls true --cafile $CA_FILE -C $ChannelName -n $CCName -v $CCVersion -c {\"Args\":[\"init\"]} -P $endorserPolicy --collections-config ./chaincode/simple/simple_coll.json"
    else 
        execute peer0 org1 "peer chaincode instantiate -o orderer.example.com:7050 --tls true --cafile $CA_FILE -C $ChannelName -n $CCName -v $CCVersion -c {\"Args\":[\"init\"]} -P $endorserPolicy"
    fi 
}

function packageInstallAndInstance() {
    echo "🍺 安装链码，打包安装"
    execute peer0 org1 "peer chaincode package -n $CCName -v $CCVersion -p github.com/hyperledger/fabric/peer/chaincode/simple -s -S -i $instancePolicy simple.out"
    execute peer0 org1 "peer chaincode signpackage simple.out simple-signed.out"

    #execute peer0 org1 "peer chaincode install -n $CCName -v $CCVersion simple-signed.out"
    execute peer0 org1 "peer chaincode install simple-signed.out"
    execute peer1 org1 "peer chaincode install simple-signed.out"
    execute peer0 org2 "peer chaincode install simple-signed.out"
    execute peer1 org2 "peer chaincode install simple-signed.out"
    execute peer1 org2 "peer chaincode list --installed"
    sleep 0.5
    echo "🍺 实例化链码"
    if [ "$withPvt" == "true" ]; then 
        execute peer0 org1 "peer chaincode instantiate -o orderer.example.com:7050 --tls true --cafile $CA_FILE -C $ChannelName -n $CCName -v $CCVersion -c {\"Args\":[\"init\"]} -P $endorserPolicy --collections-config ./chaincode/simple/simple_coll.json"
    else 
        execute peer0 org1 "peer chaincode instantiate -o orderer.example.com:7050 --tls true --cafile $CA_FILE -C $ChannelName -n $CCName -v $CCVersion -c {\"Args\":[\"init\"]} -P $endorserPolicy"
    fi 
}

function normalDataTest() {
    echo "
#====================================
# 🍺 普通数据测试
#===================================="
    # save data 
    client peer0 org1 Admin "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $ChannelName -n $CCName -c {\"Args\":[\"set\",\"a\",\"2000\"]}"
    client peer0 org1 User1 "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $ChannelName -n $CCName -c {\"Args\":[\"set\",\"b\",\"3000\"]}"
    client peer0 org2 Admin "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $ChannelName -n $CCName -c {\"Args\":[\"set\",\"c\",\"4000\"]}"
    client peer0 org2 User1 "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $ChannelName -n $CCName -c {\"Args\":[\"set\",\"d\",\"5000\"]}"
    sleep 2

    client peer0 org1 Admin "peer chaincode query -o orderer.example.com:7050 -C $ChannelName -n $CCName -c {\"Args\":[\"get\",\"a\",\"b\",\"c\",\"d\"]}"
    client peer0 org2 Admin "peer chaincode query -o orderer.example.com:7050 -C $ChannelName -n $CCName -c {\"Args\":[\"get\",\"a\",\"b\",\"c\",\"d\"]}"

    sleep 0.5
    # delete data
    execute peer0 org1 "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $ChannelName -n $CCName -c {\"Args\":[\"delete\",\"a\"]}"
    execute peer0 org2 "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $ChannelName -n $CCName -c {\"Args\":[\"delete\",\"b\"]}"

    sleep 2
    client peer0 org1 Admin "peer chaincode query -o orderer.example.com:7050 -C $ChannelName -n $CCName -c {\"Args\":[\"get\",\"a\",\"b\",\"c\",\"d\"]}"
    client peer0 org2 Admin "peer chaincode query -o orderer.example.com:7050 -C $ChannelName -n $CCName -c {\"Args\":[\"get\",\"a\",\"b\",\"c\",\"d\"]}"
}

function pvtDataTest() {
    echo "
#======================================
# 🍺 私有数据测试 
#======================================"
    execute peer0 org1 "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $ChannelName -n $CCName -c {\"Args\":[\"setPrivate\",\"collectionData0\",\"password\",\"123456789\"]}"
    execute peer0 org1 "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $ChannelName -n $CCName -c {\"Args\":[\"setPrivate\",\"collectionData2\",\"code\",\"450987\"]}"
    execute peer0 org1 "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $ChannelName -n $CCName -c {\"Args\":[\"setPrivate\",\"collectionData1\",\"phone\",\"13472808794\"]}"
    execute peer0 org2 "peer chaincode invoke -o orderer.example.com:7050  --tls --cafile $CA_FILE -C $ChannelName -n $CCName -c {\"Args\":[\"setPrivate\",\"collectionData0\",\"color\",\"black\"]}"
    sleep 2

    execute peer0 org1 "peer chaincode query -o orderer.example.com:7050 -C $ChannelName -n $CCName -c {\"Args\":[\"getPrivate\",\"collectionData2\",\"password\",\"phone\",\"code\"]}"
    execute peer1 org1 "peer chaincode query -o orderer.example.com:7050 -C $ChannelName -n $CCName -c {\"Args\":[\"getPrivate\",\"collectionData0\",\"password\",\"code\",\"phone\"]}"
    execute peer0 org2 "peer chaincode query -o orderer.example.com:7050 -C $ChannelName -n $CCName -c {\"Args\":[\"getPrivate\",\"collectionData2\",\"password\",\"phone\",\"code\"]}"
    execute peer1 org1 "peer chaincode query -o orderer.example.com:7050 -C $ChannelName -n $CCName -c {\"Args\":[\"getPrivate\",\"collectionData\",\"cardno\",\"password\"]}"
}

#parseArgs $@

localInstallAndInstance
#packageInstallAndInstance
#sleep 4
#normalDataTest

# execute peer0 org1 "peer chaincode query -o orderer2.example.com:7050 -C $ChannelName -n $CCName -c {\"Args\":[\"get\",\"e\",\"f\"]}" 
# execute peer0 org1 "peer chaincode query -o orderer5.example.com:7050 -C $ChannelName -n $CCName -c {\"Args\":[\"get\",\"e\",\"h\"]}" 
