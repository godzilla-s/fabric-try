#!/bin/bash

baseDir=./crypto-config

mkdir $baseDir

absDir=`cd $baseDir; PWD`

writeConfig() {
    caCert=$1
    pathDir=$2
    echo "NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/$caCert
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/$caCert
    OrganizationalUnitIdentifier: peer" > $pathDir/config.yaml
}

fabric-ca-client enroll -u http://admin:adminpw@localhost:7054 -H $baseDir/cadmin

#fabric-ca-client affiliation add com -H $baseDir/cadmin
#fabric-ca-client affiliation add com.example -H $baseDir/cadmin
#fabric-ca-client affiliation add com.example.org1 -H $baseDir/cadmin
#fabric-ca-client affiliation add com.example.org2 -H $baseDir/cadmin
fabric-ca-client affiliation add com.example.org1 -H $baseDir/cadmin --force
fabric-ca-client affiliation add com.example.org2 -H $baseDir/cadmin --force

set -x
fabric-ca-client getcacert -u http://admin:adminpw@localhost:7054 -M $absDir/ordererOrganizations/example.com/msp
set +x
rm -rf $baseDir/ordererOrganizations/example.com/msp/{signcerts,keystore,user}
mkdir $baseDir/ordererOrganizations/example.com/msp/{admincerts,tlscacerts}

set -x
fabric-ca-client getcacert -u http://admin:adminpw@localhost:7054 -M $absDir/peerOrganizations/org1.example.com/msp
set +x
rm -rf $baseDir/peerOrganizations/org1.example.com/msp/{signcerts,keystore,user}
mkdir $baseDir/peerOrganizations/org1.example.com/msp/{admincerts,tlscacerts}
certFile=$(cd $baseDir/peerOrganizations/org1.example.com/msp/cacerts; ls)
set -x
writeConfig $certFile $baseDir/peerOrganizations/org1.example.com/msp
set +x

set -x
fabric-ca-client getcacert -u http://admin:adminpw@localhost:7054 -M $absDir/peerOrganizations/org2.example.com/msp
set +x
rm -rf $baseDir/peerOrganizations/org2.example.com/msp/{signcerts,keystore,user}
mkdir $baseDir/peerOrganizations/org2.example.com/msp/{admincerts,tlscacerts}
certFile=$(cd $baseDir/peerOrganizations/org2.example.com/msp/cacerts; ls)
set -x
writeConfig $certFile $baseDir/peerOrganizations/org2.example.com/msp
set +x

echo "============= create orderer certificate ============ "
set -x
fabric-ca-client register --id.name Admin@example.com --id.secret "12345" --id.type client --id.affiliation "com.example" --csr.hosts "Admin@example.com" \
   --id.attrs '"hf.Registrar.Roles=client,orderer,peer,user","hf.Registrar.DelegateRoles=client,orderer,peer,user",hf.Registrar.Attributes=*,hf.GenCRL=true,hf.Revoker=true,hf.AffiliationMgr=true,hf.IntermediateCA=true,role=admin:ecert' \
   -u http://admin:adminpw@localhost:7054 -H $baseDir/cadmin

fabric-ca-client enroll --csr.hosts "Admin@example.com" --csr.names "C=CN,O=example.com,OU=client" -u http://Admin@example.com:12345@localhost:7054 -M $absDir/ordererOrganizations/example.com/users/Admin@example.com/msp
rm -rf $baseDir/ordererOrganizations/example.com/users/Admin@example.com/msp/user
mkdir $baseDir/ordererOrganizations/example.com/users/Admin@example.com/msp/admincerts
cp $baseDir/ordererOrganizations/example.com/users/Admin@example.com/msp/signcerts/*.pem  $baseDir/ordererOrganizations/example.com/users/Admin@example.com/msp/admincerts
cp $baseDir/ordererOrganizations/example.com/users/Admin@example.com/msp/signcerts/*.pem  $baseDir/ordererOrganizations/example.com/msp/admincerts

set -x
fabric-ca-client register --id.name orderer.example.com --id.secret "12345" --id.type orderer --id.affiliation "com.example" --csr.hosts "orderer.example.com" \
   --id.attrs "role=orderer:ecert" -u http://admin:adminpw@localhost:7054 -H $baseDir/ordererOrganizations/example.com/users/Admin@example.com

fabric-ca-client enroll --csr.hosts "orderer.example.com" --csr.names "C=CN,O=example.com,OU=orderer" -u http://orderer.example.com:12345@localhost:7054 -M $absDir/ordererOrganizations/example.com/orderers/orderer.example.com/msp
rm -rf $baseDir/ordererOrganizations/example.com/orderers/orderer.example.com/msp/user
mkdir $baseDir/ordererOrganizations/example.com/orderers/orderer.example.com/msp/admincerts
cp $baseDir/ordererOrganizations/example.com/msp/admincerts/*.pem  $baseDir/ordererOrganizations/example.com/orderers/orderer.example.com/msp/admincerts
set +x


echo "============== create org1 certificate ================"
set -x
fabric-ca-client register --id.name Admin@org1.example.com --id.secret "12345" --id.type client --id.affiliation "com.example.org1" --csr.hosts "Admin@org1.example.com" \
   --id.attrs '"hf.Registrar.Roles=client,orderer,peer,user","hf.Registrar.DelegateRoles=client,orderer,peer,user",hf.Registrar.Attributes=*,hf.GenCRL=true,hf.Revoker=true,hf.AffiliationMgr=true,hf.IntermediateCA=true,role=admin:ecert' \
   -u http://admin:adminpw@localhost:7054 -H $baseDir/cadmin

fabric-ca-client enroll --csr.hosts "Admin@org1.example.com" --csr.names "C=CN,O=org1.example.com,OU=client" -u http://Admin@org1.example.com:12345@localhost:7054 -M $absDir/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
rm -rf $baseDir/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/user
mkdir $baseDir/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/admincerts
cp $baseDir/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/*.pem  $baseDir/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/admincerts
cp $baseDir/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/*.pem  $baseDir/peerOrganizations/org1.example.com/msp/admincerts
set +x

set -x
fabric-ca-client register --id.name peer0.org1.example.com --id.secret "12345" --id.type peer --id.affiliation "com.example.org1" --csr.hosts "peer0.org1.example.com" \
   --id.attrs "role=peer:ecert" -u http://admin:adminpw@localhost:7054 -H $baseDir/peerOrganizations/org1.example.com/users/Admin@org1.example.com

fabric-ca-client enroll --csr.hosts "peer0.org1.example.com" --csr.names "C=CN,O=org1.example.com,OU=peer" -u http://peer0.org1.example.com:12345@localhost:7054 -M $absDir/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp
rm -rf $baseDir/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp/user
mkdir $baseDir/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp/admincerts
cp $baseDir/peerOrganizations/org1.example.com/msp/admincerts/*.pem  $baseDir/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp/admincerts

certFile=$(cd $baseDir/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp/cacerts; ls)
writeConfig $certFile $baseDir/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp
set +x


echo "============= create org2 certificate ================"
set -x
fabric-ca-client register --id.name Admin@org2.example.com --id.secret "12345" --id.type client --id.affiliation "com.example.org2" --csr.hosts "Admin@org2.example.com" \
   --id.attrs '"hf.Registrar.Roles=client,orderer,peer,user","hf.Registrar.DelegateRoles=client,orderer,peer,user",hf.Registrar.Attributes=*,hf.GenCRL=true,hf.Revoker=true,hf.AffiliationMgr=true,hf.IntermediateCA=true,role=admin:ecert' \
   -u http://admin:adminpw@localhost:7054 -H $baseDir/cadmin

fabric-ca-client enroll --csr.hosts "Admin@org2.example.com" --csr.names "C=CN,O=org2.example.com,OU=client" -u http://Admin@org2.example.com:12345@localhost:7054 -M $absDir/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
rm -rf $baseDir/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/user
mkdir $baseDir/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/admincerts
cp $baseDir/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/signcerts/*.pem  $baseDir/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/admincerts
cp $baseDir/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/signcerts/*.pem  $baseDir/peerOrganizations/org2.example.com/msp/admincerts
set +x


set -x
fabric-ca-client register --id.name peer0.org2.example.com --id.secret "12345" --id.type peer --id.affiliation "com.example.org2" --csr.hosts "peer0.org2.example.com" \
   --id.attrs "role=peer:ecert" -u http://admin:adminpw@localhost:7054 -H $baseDir/peerOrganizations/org2.example.com/users/Admin@org2.example.com

fabric-ca-client enroll --csr.hosts "peer0.org2.example.com" --csr.names "C=CN,O=org2.example.com,OU=peer" -u http://peer0.org2.example.com:12345@localhost:7054 -M $absDir/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp
rm -rf $baseDir/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp/user
mkdir $baseDir/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp/admincerts
cp $baseDir/peerOrganizations/org2.example.com/msp/admincerts/*.pem  $baseDir/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp/admincerts

certFile=$(cd $baseDir/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp/cacerts; ls)
writeConfig $certFile $baseDir/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp
set +x

rm -rf $baseDir/cadmin