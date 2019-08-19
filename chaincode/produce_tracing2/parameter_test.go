package main

import (
	"encoding/json"
	"fmt"
	"testing"
)

var args = `{
	"function":"save",
	"class":"asset.FarmPig",
	"args": {
		"id":"FP0001",
		"farmID":"FX0034",
		"name":"farm x store"
	}
}`
func TestParameter_Execute(t *testing.T) {
	type request struct {
		Class    string      `json:"class"`
		FuncName string      `json:"function"`
		Args     interface{} `json:"args"`
	}
	var req request
	err := json.Unmarshal([]byte(args), &req)
	if err != nil {
		t.Fatal(err)
	}

	var param Parameter
	param.args = req.Args
	param.funcName = req.FuncName
	param.className = req.Class

	id, err := param.GetString("id")
	if err != nil {
		t.Fatal(err)
	}

	fmt.Println(id)


}
