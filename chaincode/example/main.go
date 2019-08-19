package main

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"github.com/hyperledger/fabric/core/chaincode/shim/ext/cid"
	"github.com/hyperledger/fabric/core/chaincode/shim/ext/statebased"
	"github.com/hyperledger/fabric/protos/peer"
)

type Example struct {}

func (e *Example) Init(stub shim.ChaincodeStubInterface) peer.Response {
	return shim.Success(nil)
}

func (e *Example) Invoke(stub shim.ChaincodeStubInterface) peer.Response {
	f, args := stub.GetFunctionAndParameters()
	switch f {
	case "setkvs":
		return setKeyEndorsor(stub, args)
	case "delkvs":
		return delKeyEndorsor(stub, args)
	case "addorg":
		return addSVPOrgs(stub, args)
	case "delorg":
		return delSVPOrgs(stub, args)
	case "setAuth":
		return setAuth(stub, args)
	case "getAuth":
		return getAuth(stub, args)
	case "set":
		return setValue(stub, args)
	case "get":
		return getValue(stub, args)
	case "getinfo":
		return getInfo(stub)
	}
	return shim.Error("undefined function:" + f)
}

func setKeyEndorsor(stub shim.ChaincodeStubInterface, args []string ) peer.Response {
	key := args[0]
	stateEP, err := statebased.NewStateEP(nil)
	if err != nil {
		return shim.Error("new stateep:" + err.Error())
	}

	err = stateEP.AddOrgs(statebased.RoleTypePeer, args[1:]...)
	if err != nil {
		return shim.Error("add org:" + err.Error())
	}

	ep, err := stateEP.Policy()
	if err != nil {
		return shim.Error("policy:" + err.Error())
	}

	err = stub.SetStateValidationParameter(key, ep)
	if err != nil {
		return shim.Error("set state invalid fail:" + err.Error())
	}

	return shim.Success([]byte("set key endorsor ok") )
}

func delKeyEndorsor(stub shim.ChaincodeStubInterface, args []string) peer.Response {
	stateKey := args[0]
	_, err := stub.GetStateValidationParameter(stateKey)
	if err != nil {
		return shim.Error("get state key error:" + err.Error())
	}

	err = stub.SetStateValidationParameter(stateKey, nil)
	if err != nil {
		return shim.Error("set state key:" + err.Error())
	}
	return shim.Success(nil)
}

func addSVPOrgs(stub shim.ChaincodeStubInterface, args []string) peer.Response {
	stateKey := args[0]
	fmt.Println("state key:", stateKey)
	epBytes, err := stub.GetStateValidationParameter(stateKey)
	if err != nil {
		return shim.Error("get state key:" + err.Error())
	}

	stateEp, err := statebased.NewStateEP(epBytes)
	if err != nil {
		return shim.Error("new state ep:" + err.Error())
	}

	err = stateEp.AddOrgs(statebased.RoleTypePeer, args[1:]...)
	if err != nil {
		return shim.Error("add org:" + err.Error())
	}

	epBytes, err = stateEp.Policy()
	if err != nil {
		return shim.Error("after new policy:" + err.Error())
	}

	err = stub.SetStateValidationParameter(stateKey, epBytes)
	if err != nil {
		return shim.Error("update SVP :" + err.Error())
	}
	return shim.Success(epBytes)
}

func delSVPOrgs(stub shim.ChaincodeStubInterface, args []string) peer.Response {
	stateKey := args[0]
	epBytes, err := stub.GetStateValidationParameter(stateKey)
	if err != nil {
		return shim.Error("get state key:" + err.Error())
	}

	stateEp, err := statebased.NewStateEP(epBytes)
	if err != nil {
		return shim.Error("new state ep:" + err.Error())
	}

	stateEp.DelOrgs(args[1:]...)

	epBytes, err = stateEp.Policy()
	if err != nil {
		return shim.Error("after new policy:" + err.Error())
	}

	err = stub.SetStateValidationParameter(stateKey, epBytes)
	if err != nil {
		return shim.Error("update SVP :" + err.Error())
	}
	return shim.Success(nil)
}

func setAuth(stub shim.ChaincodeStubInterface, args []string) peer.Response {
	if len(args) < 2 {
		return shim.Error("args must more than 1")
	}
	stateKey := args[0]
	fmt.Println("stateKey:", stateKey)
	epBytes, err := stub.GetStateValidationParameter(stateKey)
	if err != nil {
		return shim.Error("get state key:" + err.Error())
	}

	stateEp, err := statebased.NewStateEP(epBytes)
	if err != nil {
		return shim.Error("new state ep:" + err.Error())
	}

	authEp := args[1:]
	err = stateEp.AddOrgs(statebased.RoleTypeMember, authEp...)
	if err != nil {
		return shim.Error("add org:"+err.Error())
	}

	epBytes, err = stateEp.Policy()
	if err != nil {
		return shim.Error("policy:" + err.Error())
	}

	err = stub.SetStateValidationParameter(stateKey, epBytes)
	if err != nil {
		return shim.Error("update SVP :" + err.Error())
	}

	return shim.Success(nil)
}

func getAuth(stub shim.ChaincodeStubInterface, args []string) peer.Response {
	stateKey := args[0]
	epBytes, err := stub.GetStateValidationParameter(stateKey)
	if err != nil {
		return shim.Error("get state key:" + err.Error())
	}

	stateEp, err := statebased.NewStateEP(epBytes)
	if err != nil {
		return shim.Error("get state error:" + err.Error())
	}

	orgs := stateEp.ListOrgs()
	bytes, _ := json.Marshal(orgs)
	return shim.Success(bytes)
}

func setValue(stub shim.ChaincodeStubInterface, args []string) peer.Response {
	key := args[0]
	value := args[1]

	err := stub.PutState(key, []byte(value))
	if err != nil {
		return shim.Error("put state fail:" + err.Error())
	}
	return shim.Success(nil)
}

func getValue(stub shim.ChaincodeStubInterface, args []string) peer.Response {
	key := args[0]
	value, err := stub.GetState(key)
	if err != nil {
		return shim.Error("get state:" + err.Error())
	}

	return shim.Success(value)
}

func getInfo(stub shim.ChaincodeStubInterface) peer.Response {
	clientId, err := cid.New(stub)
	if err != nil {
		return shim.Error("")
	}

	id, err := clientId.GetID()
	if err != nil {
		return shim.Error("fail to get ID:"+err.Error())
	}
	mspId, _ := clientId.GetMSPID()
	cert, _ := clientId.GetX509Certificate()
	creator, _ := stub.GetCreator()

	stub.GetCreator()

	proposal, _ := stub.GetSignedProposal()
	proposal.ProtoMessage()

	channelId := stub.GetChannelID()
	payload := new(bytes.Buffer)
	payload.WriteString("{")
	payload.WriteString("channeID:"+channelId)
	payload.WriteString(", Id:"+id)
	payload.WriteString(", creator:")
	payload.Write(creator)
	payload.WriteString(", mspId:"+mspId)
	payload.WriteString(", issuer:" + cert.Issuer.String())
	payload.WriteString(", cert:"+base64.StdEncoding.EncodeToString(cert.Raw))
	payload.WriteString("}")

	return shim.Success(payload.Bytes())
}

func main() {
	err := shim.Start(new(Example))
	if err != nil {
		fmt.Printf("Error starting Simple chaincode: %s", err)
	}
}
