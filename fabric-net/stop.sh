#!/bin/bash 

echo "----------- down fabric container -----------"
docker-compose -f docker-orderer-solo.yaml down 
docker-compose -f docker-orderer-raft.yaml down 
docker-compose -f docker-kafka.yaml down
docker-compose -f docker-orderer-kafka.yaml down 
docker-compose down --volumes

echo "----------- shutdown fabric-ca --------------"
docker-compose -f docker-ca.yaml down
sleep 0.5 
echo "----------- romve chaincode containers ------"
containers=`docker ps -a | grep dev-peer* | awk '{print $1}'`
for c in $containers; do  
    docker rm -f $c 
done
sleep 0.5
echo "----------- remove chaincode images --------"
images=`docker images | grep dev-peer* | awk '{print $3}'`
for i in $images; do 
    docker rmi -f $i
done 
sleep 0.5 
echo "----------- delete crypto config files -----"
rm -rf crypto-config
echo "done !"
sleep 0.5 
echo "----------- delete channel config files ----"
echo "done !"
rm -rf channel-config 
echo "----------- remove volume ------------------"
docker volume prune -f 
echo "done !"
rm -rf ./temp