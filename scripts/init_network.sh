#!/bin/bash
# Script to initialize the network (Create Channel, Join Peer)

export CHANNEL_NAME=mychannel
export DOCKER_CMD=/usr/bin/docker

# Navigate to the infrastructure directory
cd "$(dirname "$0")/../infrastructure/fabric"

echo "Creating channel..."
$DOCKER_CMD exec cli peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

echo "Joining peer to channel..."
$DOCKER_CMD exec cli peer channel join -b mychannel.block

# echo "Updating anchor peers..."
# $DOCKER_CMD exec cli peer channel update -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./Org1MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

echo "Network initialized!"
