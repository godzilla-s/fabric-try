package main

import (
	"fmt"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"github.com/hyperledger/fabric/protos/peer"
)

type Contract struct {
	Participants map[string]Participant
	Assets map[string]Asset
}

var logger = shim.NewLogger("ProduceTracingCC")

func newContract() *Contract {
	return &Contract{
		Participants:make(map[string]Participant),
		Assets:make(map[string]Asset),
	}
}

func (cc *Contract) AddParticipant(p Participant) {
	cc.Participants[p.Class()] = p
}

func (cc *Contract) AddAsset(a Asset) {
	cc.Assets[a.Class()] = a
}

func (cc *Contract) Init(stub shim.ChaincodeStubInterface) peer.Response {
	// for test
	//cc.Participants = make(map[string]Participant)
	//cc.Assets = make(map[string]Asset)
	//
	//cc.RegisterParticipant(Farm{})
	//cc.RegisterParticipant(Slaughter{})

	return shim.Success(nil)
}

func (cc *Contract) Invoke(stub shim.ChaincodeStubInterface) peer.Response {
	args := stub.GetArgs()
	if len(args) != 1 {
		return shim.Error(fmt.Sprintf("argument number invalid:%d", len(args)))
	}

	params, err := NewParameter(stub, args[0])
	if err != nil {
		return shim.Error(err.Error())
	}

	logger.Info("params:", *params)
	return params.Execute(cc)
}

func main() {
	cc := newContract()

	cc.AddParticipant(Farm{})
	cc.AddParticipant(Slaught{})
	cc.AddAsset(FarmPig{})

	logger.Info("start chaincode ...")
	if err := shim.Start(cc); err != nil {
		fmt.Println("fail to start chaincode:", err)
	}
}
