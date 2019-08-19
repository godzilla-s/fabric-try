#!/bin/bash

ca=false
version=1.4.1
network=""
targetFile=.env
os=`uname -s`
configDir=v1.4
action=""
ordererType="solo"
couchdb=false

setImageTag() {
    if [ "$version" == "1.2.1" ] || [ "$version" == "1.2" ]; then 
        if [ "$os" == "Darwin" ]; then 
            sed -i "" "s/IMAGE_TAG=.*/IMAGE_TAG=1.2.1/g" $targetFile
            sed -i "" "s/CCENV_TAG=.*/CCENV_TAG=1.2.1/g" $targetFile
            sed -i "" "s/BASEOS_TAG=.*/BASEOS_TAG=0.4.10/g" $targetFile
            sed -i "" "s/KAFKA_TAG=.*/KAFKA_TAG=0.4.10/g" $targetFile
            sed -i "" "s/ZOOKEEPER_TAG=.*/ZOOKEEPER_TAG=0.4.10/g" $targetFile
        else 
            sed -i "s/IMAGE_TAG=.*/IMAGE_TAG=1.2.1/g" $targetFile
            sed -i "s/CCENV_TAG=.*/CCENV_TAG=1.2.1/g" $targetFile
            sed -i "s/BASEOS_TAG=.*/BASEOS_TAG=0.4.10/g" $targetFile
            sed -i "s/KAFKA_TAG=.*/KAFKA_TAG=0.4.10/g" $targetFile
            sed -i "s/ZOOKEEPER_TAG=.*/ZOOKEEPER_TAG=0.4.10/g" $targetFile
        fi 
        configDir=v1.2
    elif [ "$version" == "1.4" ] || [ "$version" == "1.4.1" ]; then 
        if [ "$os" == "Darwin" ]; then 
            sed -i "" "s/IMAGE_TAG=.*/IMAGE_TAG=1.4.1/g" $targetFile
            sed -i "" "s/CCENV_TAG=.*/CCENV_TAG=1.4.1/g" $targetFile
            sed -i "" "s/BASEOS_TAG=.*/BASEOS_TAG=0.4.15/g" $targetFile
            sed -i "" "s/KAFKA_TAG=.*/KAFKA_TAG=0.4.15/g" $targetFile
            sed -i "" "s/ZOOKEEPER_TAG=.*/ZOOKEEPER_TAG=0.4.15/g" $targetFile
        else 
            sed -i "s/IMAGE_TAG=.*/IMAGE_TAG=1.4.1/g" $targetFile
            sed -i "s/CCENV_TAG=.*/CCENV_TAG=1.4.1/g" $targetFile
            sed -i "s/BASEOS_TAG=.*/BASEOS_TAG=0.4.15/g" $targetFile
            sed -i "s/KAFKA_TAG=.*/KAFKA_TAG=0.4.15/g" $targetFile
            sed -i "s/ZOOKEEPER_TAG=.*/ZOOKEEPER_TAG=0.4.15/g" $targetFile
        fi 
        configDir=v1.4
    fi
}

setEnv() {
    if [ "$os" == "Darwin" ]; then 
        key=$1
        val=$2
        sed -i "" "s/$key=.*/$key=$val/g" $targetFile
    else 
        sed -i "s/$key=.*/$key=$val/g" $targetFile
    fi 
}

testFunc=""

parseArgs() {
    while [ $# -gt 0 ]; do 
        case $1 in 
            -ca)
                if [ "$2" == "true" ] || [ "$2" == "false" ]; then 
                    ca=$2
                else 
                    ca="true"
                fi 
                ;;
            -v)
                version=$2
                ;;
            -net) # network
                network=$2
                setEnv COMPOSE_PROJECT_NAME $network 
                ;;
            -t) # test
                ;;
            up)
                action="up"
                ;;
            down)
                action="down"
                ;;
            start)
                action="start"
                ;;
            -couchdb)
                echo "use couchdb"
                couchdb=true
                setEnv DBTYPE "CouchDB"
                ;;
            -o)
                ordererType=$2
                ;;
            -test)
                testFunc=$2
                ;;
        esac
        shift
    done

    if [ "$couchdb" == "false" ]; then 
        setEnv DBTYPE ""
    fi 
}

#parseArgs $@

