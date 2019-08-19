## 常见问题 

1. 加入通道，实例化链码过程中，报错：
```
isn't eligible for channel mychannel : Failed to reach implicit threshold of 1 sub-policies, required 1 remaining
github.com/hyperledger/fabric/gossip/gossip/channel.NewGossipChannel.func5
	/opt/gopath/src/github.com/hyperledger/fabric/gossip/gossip/channel/channel.go:249
github.com/hyperledger/fabric/gossip/gossip/channel.(*stateInfoCache).Add
	/opt/gopath/src/github.com/hyperledger/fabric/gossip/gossip/channel/channel.go:932
github.com/hyperledger/fabric/gossip/gossip/channel.(*gossipChannel).handleStateInfSnapshot
	/opt/gopath/src/github.com/hyperledger/fabric/gossip/gossip/channel/channel.go:692
github.com/hyperledger/fabric/gossip/gossip/channel.(*gossipChannel).HandleMessage
	/opt/gopath/src/github.com/hyperledger/fabric/gossip/gossip/channel/channel.go:548
github.com/hyperledger/fabric/gossip/gossip.(*gossipServiceImpl).handleMessage
	/opt/gopath/src/github.com/hyperledger/fabric/gossip/gossip/gossip_impl.go:377
github.com/hyperledger/fabric/gossip/gossip.(*gossipServiceImpl).acceptMessages
	/opt/gopath/src/github.com/hyperledger/fabric/gossip/gossip/gossip_impl.go:331
runtime.goexit
	/opt/go/src/runtime/asm_amd64.s:2361
```
创建证书crypto.yaml中EnableNodeOUs未设置，应当设置为true

2. 创建通道，失败:
```
got unexpected status: BAD_REQUEST -- error authorizing update: error validating DeltaSet: policy for [Group]  /Channel/Application not satisfied: Failed to reach implicit threshold of 1 sub-policies, required 1 remaining
```
证书指定错误，可能是使用错误的证书，

3. 容器间服务连不通<br>
确认所有容器是否在同一网段 (network)

4. invoke链码
```
Error: error sending transaction for invoke: could not send: EOF - proposal response: version:1 response:<status:200 > payload:
```
tls是否开启， cafile是否指定，即 --tls --cafile xxx

5. invoke链码，存放私有数据时，
```
Error: endorsement failure during invoke. chaincode result: <nil>
```
collection-json:
```
{
    "name": "collectionData1",
    "policy": "OR('Org1MSP.member', 'Org2MSP.member')",
    "requiredPeerCount": 2,
    "maxPeerCount": 3,
    "blockToLive":1000000
},
```
可能原因： 组织没有更新锚点，anchor peer，

6. 实例化链码时，报错
```
Error: could not assemble transaction, err Proposal response was not successful, error code 500, msg instantiation policy violation: signature set did not satisfy policy
```
与链码打包时指定策略要求的实例化的组织不符。

7. 组织更新锚点， 报错（fabric v1.4）:
```
Could not connect to Endpoint: peer0.org2.example.com:9051, InternalEndpoint: peer0.org2.example.com:9051, PKI-ID: <nil>, Metadata:  : context deadline exceeded
```
//

8. 加入通道失败， 报错信息
```
2019-07-15 08:17:57.172 UTC [ConnProducer] DisableEndpoint -> WARN 03e Only 1 endpoint remained, will not black-list it
2019-07-15 08:17:57.187 UTC [blocksProvider] DeliverBlocks -> ERRO 03f [mychannel] Got error &{FORBIDDEN}
```
组织msp下添加配置文件 config.yaml: 
```
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca.org1.example.com-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca.org1.example.com-cert.pem
    OrganizationalUnitIdentifier: peer
```