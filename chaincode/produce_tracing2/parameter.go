package main

import (
	"encoding/json"
	"fmt"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"github.com/hyperledger/fabric/core/chaincode/shim/ext/cid"
	"github.com/hyperledger/fabric/protos/peer"
	"strings"
)

type Decoder interface {
	Decode(data []byte) error
}

type Encoder interface {
	Encode() ([]byte, error)
}

type Parameter struct {
	stub      shim.ChaincodeStubInterface
	mspID     string                 // 客户端的组织ID
	className string                 // 类名：参与者或资产
	funcName  string                 // 执行方法
	ownership map[string]Participant // 资产所有者
	args      interface{}            // 参数
	asset     Asset
}

func NewParameter(stub shim.ChaincodeStubInterface, args []byte) (*Parameter, error) {
	if len(args) == 0 {
		return nil, fmt.Errorf("nil args")
	}
	type request struct {
		Class    string      `json:"class"`
		FuncName string      `json:"function"`
		Args     interface{} `json:"args"`
	}
	var req request
	err := json.Unmarshal(args, &req)
	if err != nil {
		return nil, err
	}

	clientId, err := cid.New(stub)
	if err != nil {
		return nil, err
	}
	mspId, err := clientId.GetMSPID()
	if err != nil {
		return nil, err
	}

	var params = new(Parameter)
	params.funcName = req.FuncName
	params.mspID = mspId
	params.stub = stub
	params.className = req.Class
	params.args = req.Args
	params.ownership = make(map[string]Participant)
	return params, nil
}

func (p Parameter) authKey(authID string) string {
	return "authority-" + p.asset.Class() + "-" + authID
}

func (p Parameter) isReadable(rw string) bool {
	return rw == "r" || rw == "rw"
}

func (p Parameter) isWritable(rw string) bool {
	return rw == "w" || rw == "rw"
}

func (p Parameter) GetStub() shim.ChaincodeStubInterface {
	return p.stub
}

// 资产所有者是否有读权限
func (p Parameter) IsOwnershipReadable() bool {
	prticipant, ok := p.ownership[p.mspID]
	if !ok {
		return false
	}
	ownership := p.asset.Ownership()
	rw, ok := ownership[prticipant.Class()]
	if !ok {
		return false
	}
	return p.isReadable(rw)
}

// 资产所有者是否有写权限
func (p Parameter) IsOwnershipWritable() bool {
	prticipant, ok := p.ownership[p.mspID]
	if !ok {
		return false
	}
	ownership := p.asset.Ownership()
	rw, ok := ownership[prticipant.Class()]
	if !ok {
		return false
	}
	return p.isWritable(rw)
}

// 是否有读授权
func (p Parameter) IsAuthReadable() bool {
	key := p.authKey(p.mspID)
	data, _ := p.stub.GetState(key)
	if len(data) == 0 {
		return false
	}
	return p.isReadable(string(data))
}

// 是否有写授权
func (p Parameter) IsAuthWritable() bool {
	key := p.authKey(p.mspID)
	data, _ := p.stub.GetState(key)
	if len(data) == 0 {
		return false
	}
	return p.isWritable(string(data))
}

// 授权
func (p Parameter) SetAuth(authID, rw string) error {
	key := p.authKey(authID)
	data, _ := p.stub.GetState(key)
	if len(data) > 0 {
		return fmt.Errorf("auth key does exist")
	}
	return p.stub.PutState(key, []byte(rw))
}

// 取消授权
func (p Parameter) UnsetAuth(authID string) error {
	key := p.authKey(authID)
	data, _ := p.stub.GetState(key)
	if len(data) == 0 {
		return fmt.Errorf("auth key not exist")
	}
	return p.stub.DelState(key)
}

// 解析对象
func (p Parameter) ParseObject(v interface{}) error {
	logger.Info("args: ", p.args)
	data, err := json.Marshal(p.args)
	if err != nil {
		return err
	}
	return json.Unmarshal(data, v)
}

// 存储数据
func (p Parameter) PutState(key string, encode Encoder) error {
	data, err := encode.Encode()
	if err != nil {
		return err
	}
	return p.stub.PutState(key, data)
}

// 查询数据
func (p Parameter) GetState(key string, decode Decoder) error {
	data, err := p.stub.GetState(key)
	if err != nil {
		return err
	}
	return decode.Decode(data)
}

func (p Parameter) ExistKey(key string) bool {
	data, _ := p.stub.GetState(key)
	if len(data) == 0 {
		return false
	}
	return true
}

// 执行链码方法
func (p Parameter) Execute(cc *Contract) peer.Response {
	if strings.HasPrefix(p.className, "participant.") {
		logger.Info("Participant invoke")
	} else if strings.HasPrefix(p.className, "asset.") {
		logger.Info("Asset invoke")
		asset, ok := cc.Assets[p.className]
		if !ok {
			return shim.Error("not found asset:" + p.className)
		}

		ownership := asset.Ownership()
		for participantName := range ownership {
			part, ok := cc.Participants[participantName]
			if !ok {
				return shim.Error("not found participant:" + participantName)
			}
			p.ownership[part.MspID()] = part
		}

		p.asset = asset
		return asset.Invoke(p)
	} else {
		return shim.Error("invalid class name")
	}
	return shim.Success(nil)
}

func (p Parameter) getValue(key string) (interface{}, error) {
	var dataVal map[string]interface{}
	err := p.ParseObject(&dataVal)
	if err != nil {
		return nil, err
	}
	val, ok := dataVal[key]
	if !ok {
		return nil, fmt.Errorf("key not exist")
	}
	return val, nil
}

// 根据key获取string类型数据
func (p Parameter) GetString(key string) (string, error) {
	v, err := p.getValue(key)
	if err != nil {
		return "", err
	}
	if s, ok := v.(string); ok {
		return s, nil
	}
	return "", fmt.Errorf("data type not map")
}

func (p Parameter) GetNumber(key string) (int64, error) {
	v, err := p.getValue(key)
	if err != nil {
		return 0, err
	}
	if i, ok := v.(int64); ok {
		return i, nil
	}
	return 0, fmt.Errorf("data type not map")
}