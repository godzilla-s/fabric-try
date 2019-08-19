#!/bin/bash 

# yo hyperledger-composer:businessnetwork # 创建一个composer项目

baseCrypto=../crypto-config/peerOrganizations
chaincode=/Users/zuvakin/project/tracing_produce

filePath=""
getFile() {
    path=$1
    fname=$(ls $path)
    filePath=$path/$fname
}

getFile $baseCrypto/org1.example.com/users/Admin@org1.example.com/msp/signcerts
org1AdminCert=$filePath
getFile $baseCrypto/org1.example.com/users/Admin@org1.example.com/msp/keystore
org1AdminKey=$filePath

getFile $baseCrypto/org2.example.com/users/Admin@org2.example.com/msp/signcerts
org2AdminCert=$filePath
getFile $baseCrypto/org2.example.com/users/Admin@org2.example.com/msp/keystore
org2AdminKey=$filePath

#echo "==> build chaincode"
#composer archive create -t dir -n $chaincode
#sleep 1

# awk 'NF {sub(/\r/, ""); printf "%s\\n", $0;}' ../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt
# echo ""
# awk 'NF {sub(/\r/, ""); printf "%s\\n", $0;}' ../crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
# echo ""
# awk 'NF {sub(/\r/, ""); printf "%s\\n", $0;}' ../crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

echo "==> create card"
set -x
composer card create -p composer-org1.json -u PeerAdmin -c $org1AdminCert -k $org1AdminKey -r PeerAdmin -r ChannelAdmin -f PeerAdmin@org1-fabric.card
composer card create -p composer-org2.json -u PeerAdmin -c $org2AdminCert -k $org2AdminKey -r PeerAdmin -r ChannelAdmin -f PeerAdmin@org2-fabric.card
set +x
sleep 1
echo "==> import card "
set -x
composer card import -f PeerAdmin@org1-fabric.card --card PeerAdmin@org1-fabric
composer card import -f PeerAdmin@org2-fabric.card --card PeerAdmin@org2-fabric
set +x


# echo "==> install composer chaincode"
# composer network install --card PeerAdmin@org1-fabric --archiveFile tracing_produce@0.0.2.bna
# composer network install --card PeerAdmin@org2-fabric --archiveFile tracing_produce@0.0.2.bna

#composer network start -c PeerAdmin@org1-fabric -n tracing_produce -V 0.0.1 -A admin -S adminpw -f admin@org1-fabric.card

#composer network upgrade -c PeerAdmin@org1-fabric -n tracing_produce -V 0.0.2 
# composer card import -f admin@org1-fabric.card
# pm2 start composer-rest-server --name rest-server -- -c admin@tracing_produce -n never -w true -m false -p 3000