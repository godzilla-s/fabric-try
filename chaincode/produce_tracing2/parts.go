package main

// 参与方: 养殖场
type Farm struct {}

func (f Farm) Class() string {
	return "participant.Farm"
}

func (f Farm) MspID() string {
	return "Org1MSP"
}

// 参与方: 屠宰场
type Slaught struct {}

func (f Slaught) Class() string {
	return "participant.Slaughter"
}

func (f Slaught) MspID() string {
	return "Org2MSP"
}