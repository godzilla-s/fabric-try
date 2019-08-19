package main

import "github.com/hyperledger/fabric/protos/peer"

type Asset interface {
	// 资产的类名
	Class() string
	// 资产所属
	Ownership() map[string]string
	// 方法调用
	Invoke(params Parameter) peer.Response
}
