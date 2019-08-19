#!/bin/bash

baseDir=./crypto-config

absDir=`cd $baseDir; PWD`

CAUrl=localhost:7054

fabric-ca-client enroll -u http://admin:adminpw@$CAUrl -H $baseDir/tlsadmin

## older method
# fabric-ca-client affiliation add com -H $baseDir/tlsadmin
# fabric-ca-client affiliation add com.example -H $baseDir/tlsadmin
# fabric-ca-client affiliation add com.example.org1 -H $baseDir/tlsadmin
# fabric-ca-client affiliation add com.example.org2 -H $baseDir/tlsadmin
fabric-ca-client affiliation add com.example.org1 -H $baseDir/tlsadmin --force
fabric-ca-client affiliation add com.example.org2 -H $baseDir/tlsadmin --force

echo "============== create orderer tls ============="
set -x
fabric-ca-client register --id.name Admin@example.com --id.secret "12345" --id.type client --id.affiliation "com.example" --csr.hosts "Admin@example.com" \
   --id.attrs '"hf.Registrar.Roles=client,orderer,peer,user","hf.Registrar.DelegateRoles=client,orderer,peer,user",hf.Registrar.Attributes=*,hf.GenCRL=true,hf.Revoker=true,hf.AffiliationMgr=true,hf.IntermediateCA=true,role=admin:ecert' \
   -u http://admin:adminpw@$CAUrl -H $baseDir/tlsadmin


fabric-ca-client enroll -d --enrollment.profile tls --csr.hosts "Admin@example.com" --csr.names "C=CN,O=example.com,OU=client" -u http://Admin@example.com:12345@$CAUrl -H $baseDir/tlsadmin/Admin@example.com
homeDir=$baseDir/ordererOrganizations/example.com/users/Admin@example.com
mkdir $homeDir/tls
cp $baseDir/tlsadmin/Admin@example.com/msp/signcerts/*.pem $homeDir/tls/client.crt
cp $baseDir/tlsadmin/Admin@example.com/msp/keystore/*_sk  $homeDir/tls/client.key
cp $baseDir/tlsadmin/Admin@example.com/msp/tlscacerts/*.pem $homeDir/tls/ca.crt
cp -r $baseDir/tlsadmin/Admin@example.com/msp/tlscacerts $baseDir/ordererOrganizations/example.com/msp
cp -r $baseDir/tlsadmin/Admin@example.com/msp/tlscacerts $homeDir/msp
set +x


set -x
fabric-ca-client register --id.name orderer.example.com --id.secret "12345" --id.type orderer --id.affiliation "com.example" --csr.hosts "orderer.example.com" \
   --id.attrs "role=orderer:ecert" -u http://admin:adminpw@$CAUrl -H $baseDir/tlsadmin/Admin@example.com

fabric-ca-client enroll -d --enrollment.profile tls --csr.hosts "orderer.example.com" --csr.names "C=CN,O=example.com,OU=orderer" -u http://orderer.example.com:12345@$CAUrl -H $baseDir/tlsadmin/orderer.example.com
homeDir=$baseDir/ordererOrganizations/example.com/orderers/orderer.example.com
mkdir $homeDir/tls
cp $baseDir/tlsadmin/orderer.example.com/msp/signcerts/*.pem $homeDir/tls/server.crt
cp $baseDir/tlsadmin/orderer.example.com/msp/keystore/*_sk  $homeDir/tls/server.key
cp $baseDir/tlsadmin/orderer.example.com/msp/tlscacerts/*.pem $homeDir/tls/ca.crt
cp -r $baseDir/tlsadmin/orderer.example.com/msp/tlscacerts $homeDir/msp
set +x


echo "============== create org1 tls ============="
set -x
fabric-ca-client register --id.name Admin@org1.example.com --id.secret "12345" --id.type client --id.affiliation "com.example.org1" --csr.hosts "Admin@org1.example.com" \
   --id.attrs '"hf.Registrar.Roles=client,orderer,peer,user","hf.Registrar.DelegateRoles=client,orderer,peer,user",hf.Registrar.Attributes=*,hf.GenCRL=true,hf.Revoker=true,hf.AffiliationMgr=true,hf.IntermediateCA=true,role=admin:ecert' \
   -u http://admin:adminpw@$CAUrl -H $baseDir/tlsadmin

fabric-ca-client enroll -d --enrollment.profile tls --csr.hosts "Admin@org1.example.com" --csr.names "C=CN,O=org1.example.com,OU=client" -u http://Admin@org1.example.com:12345@$CAUrl -H $baseDir/tlsadmin/Admin@org1.example.com
homeDir=$baseDir/peerOrganizations/org1.example.com/users/Admin@org1.example.com
mkdir $homeDir/tls
cp $baseDir/tlsadmin/Admin@org1.example.com/msp/signcerts/*.pem $homeDir/tls/client.crt
cp $baseDir/tlsadmin/Admin@org1.example.com/msp/keystore/*_sk  $homeDir/tls/client.key
cp $baseDir/tlsadmin/Admin@org1.example.com/msp/tlscacerts/*.pem $homeDir/tls/ca.crt
cp -r $baseDir/tlsadmin/Admin@org1.example.com/msp/tlscacerts $baseDir/peerOrganizations/org1.example.com/msp
cp -r $baseDir/tlsadmin/Admin@org1.example.com/msp/tlscacerts $homeDir/msp
set +x


set -x
fabric-ca-client register --id.name peer0.org1.example.com --id.secret "12345" --id.type peer --id.affiliation "com.example.org1" --csr.hosts "peer0.org1.example.com" \
   --id.attrs "role=peer:ecert" -u http://admin:adminpw@$CAUrl -H $baseDir/tlsadmin/Admin@org1.example.com

fabric-ca-client enroll -d --enrollment.profile tls --csr.hosts "peer0.org1.example.com" --csr.names "C=CN,O=org1.example.com,OU=peer" -u http://peer0.org1.example.com:12345@$CAUrl -H $baseDir/tlsadmin/peer0.org1.example.com
homeDir=$baseDir/peerOrganizations/org1.example.com/peers/peer0.org1.example.com
mkdir $homeDir/tls
cp $baseDir/tlsadmin/peer0.org1.example.com/msp/signcerts/*.pem $homeDir/tls/server.crt
cp $baseDir/tlsadmin/peer0.org1.example.com/msp/keystore/*_sk  $homeDir/tls/server.key
cp $baseDir/tlsadmin/peer0.org1.example.com/msp/tlscacerts/*.pem $homeDir/tls/ca.crt
cp -r $baseDir/tlsadmin/peer0.org1.example.com/msp/tlscacerts $homeDir/msp
set +x



echo "============== create org2 tls ============="
set -x
fabric-ca-client register --id.name Admin@org2.example.com --id.secret "12345" --id.type client --id.affiliation "com.example.org2" --csr.hosts "Admin@org2.example.com" \
   --id.attrs '"hf.Registrar.Roles=client,orderer,peer,user","hf.Registrar.DelegateRoles=client,orderer,peer,user",hf.Registrar.Attributes=*,hf.GenCRL=true,hf.Revoker=true,hf.AffiliationMgr=true,hf.IntermediateCA=true,role=admin:ecert' \
   -u http://admin:adminpw@$CAUrl -H $baseDir/tlsadmin

fabric-ca-client enroll -d --enrollment.profile tls --csr.hosts "Admin@org2.example.com" --csr.names "C=CN,O=org2.example.com,OU=client" -u http://Admin@org2.example.com:12345@$CAUrl -H $baseDir/tlsadmin/Admin@org2.example.com
homeDir=$baseDir/peerOrganizations/org2.example.com/users/Admin@org2.example.com
mkdir $homeDir/tls
cp $baseDir/tlsadmin/Admin@org2.example.com/msp/signcerts/*.pem $homeDir/tls/client.crt
cp $baseDir/tlsadmin/Admin@org2.example.com/msp/keystore/*_sk  $homeDir/tls/client.key
cp $baseDir/tlsadmin/Admin@org2.example.com/msp/tlscacerts/*.pem $homeDir/tls/ca.crt
cp -r $baseDir/tlsadmin/Admin@org2.example.com/msp/tlscacerts $baseDir/peerOrganizations/org2.example.com/msp
cp -r $baseDir/tlsadmin/Admin@org2.example.com/msp/tlscacerts $homeDir/msp
set +x


set -x
fabric-ca-client register --id.name peer0.org2.example.com --id.secret "12345" --id.type peer --id.affiliation "com.example.org2" --csr.hosts "peer0.org2.example.com" \
   --id.attrs "role=peer:ecert" -u http://admin:adminpw@$CAUrl -H $baseDir/tlsadmin/Admin@org2.example.com

fabric-ca-client enroll -d --enrollment.profile tls --csr.hosts "peer0.org2.example.com" --csr.names "C=CN,O=org2.example.com,OU=peer" -u http://peer0.org2.example.com:12345@$CAUrl -H $baseDir/tlsadmin/peer0.org2.example.com
homeDir=$baseDir/peerOrganizations/org2.example.com/peers/peer0.org2.example.com
mkdir $homeDir/tls
cp $baseDir/tlsadmin/peer0.org2.example.com/msp/signcerts/*.pem $homeDir/tls/server.crt
cp $baseDir/tlsadmin/peer0.org2.example.com/msp/keystore/*_sk  $homeDir/tls/server.key
cp $baseDir/tlsadmin/peer0.org2.example.com/msp/tlscacerts/*.pem $homeDir/tls/ca.crt
cp -r $baseDir/tlsadmin/peer0.org2.example.com/msp/tlscacerts $homeDir/msp
set +x

