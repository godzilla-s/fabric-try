package main

import (
	"encoding/json"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"github.com/hyperledger/fabric/protos/peer"
)

// 生猪出栏信息
type FarmPig struct {
	ID  string  `json:"id"`
	Quantity int `json:"quantity"`
	QuarantineCert string `json:"quarantine"`
	PigTxDate string  `json:"txdate"`
}

func (fp FarmPig) Class() string {
	return "asset.FarmPig"
}

func (fp FarmPig) Ownership() map[string]string {
	return map[string]string{
		"participant.Farm":"rw",
		"participant.Slaughter": "r",
	}
}

func (fp FarmPig) Invoke(parameter Parameter) peer.Response {
	switch parameter.funcName {
	case "save":
		return fp.Save(parameter)
	case "query":
		return fp.Query(parameter)
	case "delete":
		return fp.Delete(parameter)
	case "update":
		return fp.Update( parameter)
	case "auth":
		return fp.Auth(parameter)
	case "unauth":
		return fp.Unauth(parameter)
	default:
		return shim.Error("not define function:" + parameter.funcName)
	}
}

func (fp FarmPig) Encode() ([]byte, error) {
	return json.Marshal(fp)
}

func (fp FarmPig) Decode(data []byte) error {
	return json.Unmarshal(data, &fp)
}

// 授权读写
func (fp FarmPig) Auth(params Parameter) peer.Response {
	if !params.IsOwnershipWritable() {
		return shim.Error("no authority to access write")
	}
	var authList map[string]string
	err := params.ParseObject(&authList)
	if err != nil {
		return shim.Error(err.Error())
	}

	for key, rw := range authList {
		err = params.SetAuth(key, rw)
		if err != nil {
			return shim.Error(err.Error())
		}
	}

	return shim.Success(nil)
}

// 取消读写授权
func (fp FarmPig) Unauth( params Parameter) peer.Response {
	// 权限判断
	if !params.IsOwnershipWritable() {
		return shim.Error("no authority to access write")
	}
	var unAuthList []string
	err := params.ParseObject(&unAuthList)
	if err != nil {
		return shim.Error(err.Error())
	}
	for _, key := range unAuthList {
		err = params.UnsetAuth(key)
		if err != nil {
			shim.Error(err.Error())
		}
	}
	return shim.Success(nil)
}

func (fp FarmPig) Save(params Parameter) peer.Response {
	logger.Info("invoke save function")
	if !params.IsOwnershipWritable() {
		logger.Info("no exist in onwership")
		if !params.IsAuthWritable() {
			return shim.Error("no authority to access write")
		}
	}

	var farmPig FarmPig
	err := params.ParseObject(&farmPig)
	if err != nil {
		return shim.Error("parse object error:" + err.Error())
	}
	logger.Info("farmPig:", farmPig)
	// TODO
	err = params.PutState(farmPig.ID, farmPig)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(nil)
}

func (fp FarmPig) Query(params Parameter) peer.Response {
	if !params.IsOwnershipReadable() {
		logger.Info("no exist in onwership")
		if !params.IsAuthReadable() {
			return shim.Error("no authority to access read")
		}
	}

	var farmPig FarmPig
	err := params.ParseObject(&farmPig)
	if err != nil {
		return shim.Error("parse object error:" + err.Error())
	}

	logger.Info("farmPig ID:", farmPig.ID)
	data, err := params.GetStub().GetState(farmPig.ID)
	if err != nil {
		return shim.Error(err.Error())
	}

	logger.Info(string(data))
	return shim.Success(data)
}

func (fp FarmPig) Delete( params Parameter) peer.Response {
	if !params.IsOwnershipReadable() {
		logger.Info("no exist in onwership")
		if !params.IsAuthWritable() {
			return shim.Error("no authority to access write")
		}
	}

	id, err := params.GetString("id")
	if err != nil {
		return shim.Error(err.Error())
	}

	err = params.GetStub().DelState(id)
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(nil)
}

func (fp FarmPig) Update(params Parameter) peer.Response {
	if !params.IsOwnershipReadable() {
		logger.Info("no exist in onwership")
		if !params.IsAuthWritable() {
			return shim.Error("no authority to access write")
		}
	}

	var farmPig FarmPig
	err := params.ParseObject(&farmPig)
	if err != nil {
		return shim.Error("parse object error:" + err.Error())
	}

	if !params.ExistKey(farmPig.ID) {
		return shim.Error("key not exist")
	}

	err = params.PutState(farmPig.ID, farmPig)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(nil)
}