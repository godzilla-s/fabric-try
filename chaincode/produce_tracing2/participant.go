package main

// 参与者
type Participant interface {
	// 参与者名称
	Class() string
	// 组织MSP的ID
	MspID() string
}
