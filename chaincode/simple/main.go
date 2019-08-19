package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"github.com/hyperledger/fabric/protos/peer"
)

type SimpleAsset struct {
}

func main() {
	if err := shim.Start(new(SimpleAsset)); err != nil {
		fmt.Println("fail to start chaincode:", err)
	}
}

func (s *SimpleAsset) Init(stub shim.ChaincodeStubInterface) peer.Response {
	return shim.Success(nil)
}

func (s *SimpleAsset) Invoke(stub shim.ChaincodeStubInterface) peer.Response {
	fcn, args := stub.GetFunctionAndParameters()
	switch fcn {
	case "set":
		return setValue(stub, args)
	case "setPrivate":
		return setPrivateValue(stub, args)
	case "get":
		return getValue(stub, args)
	case "getPrivate":
		return getPrivateValue(stub, args)
	case "delete":
		return deleteValue(stub, args)
	}
	return shim.Error("undefined function " + fcn)
}

func setValue(stub shim.ChaincodeStubInterface, args []string) peer.Response {
	if len(args) != 2 {
		return shim.Error(fmt.Sprintf("argument invalid, need %d, actual id %d", 2, len(args)))
	}
	fmt.Println("set value: ", args[0])
	value, err := stub.GetState(args[0])
	if err != nil {
		return shim.Error("fail to get state of " + args[0] + " with error:" + err.Error())
	} else if value != nil {
		return shim.Error("key " + args[0] + " exist")
	}
	stub.PutState(args[0], []byte(args[1]))
	return shim.Success(nil)
}

// need fabric 1.2 above
func setPrivateValue(stub shim.ChaincodeStubInterface, args []string) peer.Response {
	if len(args) != 3 {
		return shim.Error(fmt.Sprintf("argument invalid, need %d, actual id %d", 2, len(args)))
	}
	collName := args[0]
	fmt.Println("set collection name:", collName)
	value, err := stub.GetPrivateData(collName, args[1])
	if err != nil {
		return shim.Error("fail to get state of " + args[0] + " with error:" + err.Error())
	} else if value != nil {
		return shim.Error("key " + args[1] + "exist")
	}
	stub.PutPrivateData(collName, args[1], []byte(args[2]))
	return shim.Success(nil)
}

func getValue(stub shim.ChaincodeStubInterface, args []string) peer.Response {
	response := new(bytes.Buffer)
	bArrayMemberAlreadyWritten := false
	response.WriteString("[")
	for _, a := range args {
		val, err := stub.GetState(a)
		if err != nil {
			return shim.Error("key " + a + " does not exist")
		}
		if bArrayMemberAlreadyWritten == true {
			response.WriteString(",")
		}
		response.WriteString(a + ":" + string(val))
		bArrayMemberAlreadyWritten = true
	}
	response.WriteString("]")
	return shim.Success(response.Bytes())
}

// need fabric 1.2 above
func getPrivateValue(stub shim.ChaincodeStubInterface, args []string) peer.Response {
	if len(args) < 1 {
		return shim.Error("argument invalid, need at least 1")
	}
	response := new(bytes.Buffer)
	bArrayMemberAlreadyWritten := false
	collName := args[0]
	fmt.Println("get collection name:", collName)
	response.WriteString("[")
	for _, a := range args[1:] {
		val, err := stub.GetPrivateData(collName, a)
		if err != nil {
			//return shim.Error("key " + a + " does not exist")
			fmt.Println("key " + a + " does not exist")
			continue
		}
		if bArrayMemberAlreadyWritten == true {
			response.WriteString(", ")
		}
		response.WriteString(a + ":" + string(val))
		bArrayMemberAlreadyWritten = true
	}
	response.WriteString("]")
	return shim.Success(response.Bytes())
}

func deleteValue(stub shim.ChaincodeStubInterface, args []string) peer.Response {
	if len(args) < 1 {
		return shim.Error("argument invalid, need at least 1")
	}

	var resp []string
	for _, a := range args[1:] {
		err := stub.DelState(a)
		if err != nil {
			resp = append(resp, "delete key "+a+" fail with error:"+err.Error())
		}
	}
	if len(resp) == 0 {
		return shim.Success([]byte("delete ok"))
	}
	v, _ := json.Marshal(resp)
	return shim.Success(v)
}

