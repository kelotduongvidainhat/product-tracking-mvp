#!/bin/bash

# Script to test the deployed chaincode

export CHANNEL_NAME="mychannel"
export CC_NAME="product_cc"
export DOCKER_CMD="/usr/bin/docker"
export ORDERER_ADDR="orderer.example.com:7050"
export ORDERER_CA="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

# Test Data
PRODUCT_ID="PROD-$(date +%s)"
PRODUCT_NAME="Vinamilk-Organic-500ml"
PRODUCER="Vinamilk-VN"
DATE=$(date -I)
HASH="sha256:example-hash-value-123456"

echo "----------------------------------------------------------------"
echo "TESTING CHAINCODE: $CC_NAME on Channel: $CHANNEL_NAME"
echo "----------------------------------------------------------------"

echo "1. Invoking CreateProduct..."
echo "   Product ID: $PRODUCT_ID"
echo "   Name: $PRODUCT_NAME"

$DOCKER_CMD exec cli peer chaincode invoke \
    -o $ORDERER_ADDR --tls --cafile $ORDERER_CA \
    -C $CHANNEL_NAME -n $CC_NAME \
    -c '{"function":"CreateProduct","Args":["'$PRODUCT_ID'", "'$PRODUCT_NAME'", "'$PRODUCER'", "'$DATE'", "'$HASH'"]}' \
    --waitForEvent

if [ $? -eq 0 ]; then
    echo "✅ CreateProduct Transaction Successful!"
else
    echo "❌ CreateProduct Failed!"
    exit 1
fi

echo "----------------------------------------------------------------"
echo "Waiting for block propagation..."
sleep 2

echo "2. Querying ReadProduct..."
QUERY_RESULT=$($DOCKER_CMD exec cli peer chaincode query \
    -C $CHANNEL_NAME -n $CC_NAME \
    -c '{"function":"ReadProduct","Args":["'$PRODUCT_ID'"]}')

echo "   Query Result: $QUERY_RESULT"

if [[ $QUERY_RESULT == *"$PRODUCT_ID"* ]]; then
    echo "✅ ReadProduct Query Successful! Data matches."
else
    echo "❌ ReadProduct Failed or mismatch!"
fi
echo "----------------------------------------------------------------"
