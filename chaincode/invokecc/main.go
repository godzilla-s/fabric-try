package main

import (
	"fmt"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

type MyExample struct {
}

func (c *MyExample) Init(stub shim.ChaincodeStubInterface) pb.Response {
	return shim.Success(nil)
}

func (c *MyExample) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	fcn, args := stub.GetFunctionAndParameters()
	return c.invokeCC(stub, fcn, args)
}

func (c *MyExample) invokeCC(stub shim.ChaincodeStubInterface, ccName string, args []string) pb.Response {
	channel := args[0]

	fmt.Println("invoke chaincode: %s, channel: %s, args: %v", ccName, channel, args[1:])
	var ccArgs [][]byte
	for _, a := range args[1:] {
		ccArgs = append(ccArgs, []byte(a))
	}

	return stub.InvokeChaincode(ccName, ccArgs, channel)
}

func main() {
	err := shim.Start(new(MyExample))
	if err != nil {
		fmt.Printf("Error starting Simple chaincode: %s", err)
	}
}
