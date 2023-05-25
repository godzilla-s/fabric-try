#!/bin/bash

PWD=$PWD 
CRYPTOGEN=$PWD/bin/cryptogen 


function generateCrypto() {
    $CRYPTOGEN generate --config=config/crypto.yaml
}

function generateGenenisBlock() {
    
}