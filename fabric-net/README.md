## fabric with solo 

### MSP 
组织(Organization)msp文件结构:  
admincert: 组织的管理员证书
cacert: 组织的root CA证书
tlscacerts: 包含组织的TLS root CA


节点(可理解为OrganizationsUnit)msp文件结构:  
admincert: 组织的管理员证书;
cacert: 组织的root CA证书
intermediatecerts: 中间证书,如果使用中间CA的话，这个里面保存的是中间CA，没有使用的话，就为空，或直接删除；
keystore: 节点私钥(可用于签名)
signcerts：节点的自签证书
tlscacerts: 包含组织的TLS root CA <br>

### 证书 
EnableNodeOUs: 设置为true，msp下会有个config.yaml文件，增加了peer，client两种角色的访问策略，默认情况下只有admin,member。<br>
Specs.Hostname: 设置节点名称（可定制）<br>
Specs.CommonName: 

x509 证书模板中有个字段OrganizationalUnitName即OU，在MSP中会被使用为一种身份类别，用于识别验证，在fabric MSP中，主要是`client`和`peer`两种类别：

### 启动fabric网络
1. 安装fabric镜像

2. 启动fabric网络
```
./start.sh  #启动网络
./exec.sh  #创建与加入通道
```

3. 初始化网络剧哦以及实例化链码 
```
./exec.sh
```

### 动态加入组织 
参考脚本`addorg.sh`

### 常用命令 
1. 查看通道信息 
```
peer channel getinfo -c $channelName
```

### 链码打包
使用`package`去打包链码时，注意其参数的配置：
-s: 创建了一个能被多个所有者签名的package;<br>
-S: 被定义的localMspid属性的值标识的MSP签名，也可以是CORE_PEER_LOCALMSPID指定的MSP，一般情况下，是指加入同一通道的组织可以签名这个package。<br>
-i: 指定实例化策略。允许哪些的组织管理员实例化链码。

### Gossip协议以及配置
gossip的选举模式分为两种，静态和动态：  
**静态**： 指定某个peer或者所有peer为leader，但是不建议所有peer设置为leader，这样会使所有peer都去链接orderer服务，占用有限的网络资源，导致效率低下。建议每个组织指定一个。
```
export CORE_PEER_GOSSIP_USELEADERELECTION=false
export CORE_PEER_GOSSIP_ORGLEADER=true
```
或
```
export CORE_PEER_GOSSIP_USELEADERELECTION=false
export CORE_PEER_GOSSIP_ORGLEADER=false
```
注意不要两个都设置为true，这样会导致错误。

**动态**： 组织内的peers会选举一个peer去链接orderer服务。每个组织的选举都是独立的。
```
export CORE_PEER_GOSSIP_USELEADERELECTION=true
export CORE_PEER_GOSSIP_ORGLEADER=false
```

### anchor peer 
锚点的作用是让不同的组织节点能够感知彼此的存在。

### 角色
组织内的角色有4种: `peer`, `client`, `admin`, `member`。 

### 策略
实例化默认策略是，通道配置中所有组织的member。一般实例化操作需要组织的admin权限。
OR('Org1MSP.admin','Org1MSP,admin')
OR('Org1MSP.member','Org2MSP.member')
OR('Org1MSP.peer','Org2MSP.peer') 

### 共识(排序)算法
solo: 一般测试用；
kafka： 生产使用，借助zookeeper + kafka
etcdraft: 1.3后新增的算法, (有个问题，目前raft算法对存储消耗蛮大的)

### 版本特征
1. 日志等级设置
1.4为`FABRIC_LOGGING_SPEC=INFO`， 1.2为`CORE_LOGGING_LEVEL=INFO`。

### 私有数据
fabric 1.2开始支持私有数据的存储。先了解配置:
```
{
    "name": "collectionData0",  # 存放私有数据的集合名称
    "policy": "OR('Org1MSP.member', 'Org2MSP.member')", # 策略，指定哪些节点可以共享改数据
    "requiredPeerCount": 0,  # 要求接受私有数据节点数，最好不要设置为0，以防数据丢失
    "maxPeerCount": 3,
    "blockToLive":1000000 # 数据的期限，区块高度，设置为0为永久存在
    "memberOnlyRead": true  # 1.4 支持
}
```
设置好配置，然后需要在实例化链码时，通过`--collections-config`加载配置实例化链码。

### 读写权限控制 
在configtx.yaml配置文件中，每个组织都有一个policy, 如下:
```
Policies:
    Readers:  # 读， 这里允许组织所有的成员进行写操作
        Type: Signature
        Rule: "OR('Org2MSP.admin', 'Org2MSP.peer', 'Org2MSP.client')"  
    Writers:  # 写， 只针对admin和client角色
        Type: Signature
        Rule: "OR('Org2MSP.admin', 'Org2MSP.client')"
    Admins:
        Type: Signature
        Rule: "OR('Org2MSP.admin')"
```
如果控制`写`的权限，可以修改Writers的rule, 例如只允许admin写的权限，那就去掉client：`Rule: "OR('Org2MSP.admin')"`。这样该组织在操作链码时，只能通过admin角色进行invoke，（有个问题，这时的普通用户查询的时候也不能进行？？）
