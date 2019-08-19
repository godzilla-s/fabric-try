// need fabric v1.3 above
// system chaincode plugin
package main

import (
	"bytes"
	"fmt"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

func New() shim.Chaincode {
	return &scc{}
}

type scc struct{}

func (s *scc) Init(stub shim.ChaincodeStubInterface) pb.Response {
	return shim.Success(nil)
}

func (s *scc) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	fcn, args := stub.GetFunctionAndParameters()
	switch fcn {
	case "set":
		return set(stub, args)
	case "get":
		return get(stub, args)
	}
	return shim.Error("undefined function " + fcn)
}

func set(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 2 {
		return shim.Error(fmt.Sprintf("argument invalid, need %d, actual id %d", 2, len(args)))
	}

	value, err := stub.GetState(args[0])
	if err != nil {
		return shim.Error("fail to get state of " + args[0] + " with error:" + err.Error())
	} else if value != nil {
		return shim.Error("key " + args[0] + "exist")
	}
	stub.PutState(args[0], []byte(args[1]))
	return shim.Success(nil)
}

func get(stub shim.ChaincodeStubInterface, args []string) pb.Response {
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

func main() {}
