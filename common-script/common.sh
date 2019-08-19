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
    echo "☕️ ==> $peer.$org[$mspid][Admin]: $cmd"
    docker exec -t -e CORE_PEER_LOCALMSPID=$mspid \
      -e CORE_PEER_ADDRESS=$peer.$org.example.com:7051 \
      -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-files/peerOrganizations/$org.example.com/users/Admin@$org.example.com/msp \
      -e CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-files/peerOrganizations/$org.example.com/peers/$peer.$org.example.com/tls/server.crt \
      -e CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-files/peerOrganizations/$org.example.com/peers/$peer.$org.example.com/tls/server.key \
      -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-files/peerOrganizations/$org.example.com/peers/$peer.$org.example.com/tls/ca.crt \
      -t client $cmd
}

function client() {
    org=$2
    peer=$1
    user=$3
    cmd=$4
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
    echo "☕️ ==> $peer.$org[$mspid][$user]: $cmd"
    docker exec -t -e CORE_PEER_LOCALMSPID=$mspid \
      -e CORE_PEER_ADDRESS=$peer.$org.example.com:7051 \
      -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-files/peerOrganizations/$org.example.com/users/$user@$org.example.com/msp \
      -e CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-files/peerOrganizations/$org.example.com/peers/$peer.$org.example.com/tls/server.crt \
      -e CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-files/peerOrganizations/$org.example.com/peers/$peer.$org.example.com/tls/server.key \
      -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-files/peerOrganizations/$org.example.com/peers/$peer.$org.example.com/tls/ca.crt \
      -t client $cmd
    if [[ "$?" == "0" ]]; then
        echo "====> Success <====="
    else
        echo "====> Fail <===="
    fi
}

function localInstallCC() {
    ccChannel=$1
    ccName=$2
    ccVersion=$3
    ccPath=$4
    initArgs=$5
    endorserPolicy=$6

    echo "🍺 安装链码，本地安装"
    execute peer0 org1 "peer chaincode install -n $ccName -v $ccVersion -p $ccPath"
    execute peer1 org1 "peer chaincode install -n $ccName -v $ccVersion -p $ccPath"
    execute peer0 org2 "peer chaincode install -n $ccName -v $ccVersion -p $ccPath"
    execute peer1 org2 "peer chaincode install -n $ccName -v $ccVersion -p $ccPath"
    echo "🍺 实例化链码"
    if [ "$withPvt" == "true" ]; then 
        execute peer0 org1 "peer chaincode instantiate -o orderer.example.com:7050 --tls true --cafile $CA_FILE -C $ccChannel -n $ccName -v $ccVersion -c $initArgs -P $endorserPolicy --collections-config ./chaincode/simple/simple_coll.json"
    else 
        execute peer0 org1 "peer chaincode instantiate -o orderer.example.com:7050 --tls true --cafile $CA_FILE -C $ccChannel -n $ccName -v $ccVersion -c $initArgs -P $endorserPolicy"
    fi 
}

function packageInstallCC() {
    ccChannel=$1
    ccName=$2
    ccVersion=$3
    ccPath=$4
    initArgs=$5
    instancePolicy=$6
    endorserPolicy=$7
    echo "🍺 安装链码，打包安装"
    execute peer0 org1 "peer chaincode package -n $ccName -v $ccVersion -p $ccPath -s -S -i $instancePolicy $ccName.out"
    execute peer0 org1 "peer chaincode signpackage simple.out $ccName-signed.out"

    #execute peer0 org1 "peer chaincode install -n $CCName -v $CCVersion simple-signed.out"
    execute peer0 org1 "peer chaincode install $ccName-signed.out"
    execute peer1 org1 "peer chaincode install $ccName-signed.out"
    execute peer0 org2 "peer chaincode install $ccName-signed.out"
    execute peer1 org2 "peer chaincode install $ccName-signed.out"
    execute peer1 org2 "peer chaincode list --installed"
    sleep 0.5
    echo "🍺 实例化链码"
    if [ "$withPvt" == "true" ]; then 
        execute peer0 org1 "peer chaincode instantiate -o orderer.example.com:7050 --tls true --cafile $CA_FILE -C $ccChannel -n $ccName -v $ccVersion  -c $initArgs -P $endorserPolicy --collections-config ./chaincode/simple/simple_coll.json"
    else 
        execute peer0 org1 "peer chaincode instantiate -o orderer.example.com:7050 --tls true --cafile $CA_FILE -C $ccChannel -n $ccName -v $ccVersion  -c $initArgs -P $endorserPolicy"
    fi 
}