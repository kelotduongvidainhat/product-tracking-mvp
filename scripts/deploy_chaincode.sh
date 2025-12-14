#!/bin/bash
set -e

export CC_NAME="product_cc"
export CC_VERSION="1.0"
export CC_SEQUENCE="1"
export CHANNEL_NAME="mychannel"
export DOCKER_CMD="/usr/bin/docker"
export ORDERER_ADDR="orderer.example.com:7050"
export ORDERER_CA="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

# 0. Get Script Directory
SCRIPT_DIR="$(dirname "$0")"

# 1. Package Chaincode (Host side)
echo "Packaging chaincode..."
"$SCRIPT_DIR/package_ccaas.sh"

# Navigate to infra dir for the rest of operations
cd "$SCRIPT_DIR/../infrastructure/fabric"

# 2. Install Chaincode
echo "Installing chaincode on peer0.org1..."
# Copy the packaged chaincode into CLI container if needed, or use the volume mount
# We moved product_cc.tar.gz to infrastructure/fabric/, which implies it is in $(pwd) of this script.
# The CLI mounts the current dir to /opt/gopath/src/github.com/hyperledger/fabric/peer (via docker-compose working_dir?)
# Actually CLI mounts:
# - ./crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/
# but usually it mounts volumes differently.
# Let's verify CLI volumes in docker-compose.
# CLI mounts:
# - ./chaincode:/opt/gopath/src/github.com/chaincode
# - ../../chaincode:/opt/gopath/src/github.com/product-chaincode/
# - ./channel.tx ...
# It DOES NOT mount the current directory `infrastructure/fabric` to the working dir directly universally.
# We should copy the file or mount it.
# Simplest: `docker cp`

$DOCKER_CMD cp product_cc.tar.gz cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/product_cc.tar.gz

$DOCKER_CMD exec cli peer lifecycle chaincode install product_cc.tar.gz

echo "Querying installed chaincode ID..."
CC_PACKAGE_ID=$($DOCKER_CMD exec cli peer lifecycle chaincode queryinstalled | grep ${CC_NAME}_${CC_VERSION} | awk -F " " '{print $3}' | sed 's/,$//')
echo "Package ID: $CC_PACKAGE_ID"

# 3. Approve Chaincode
echo "Approving chaincode definition for Org1..."
$DOCKER_CMD exec cli peer lifecycle chaincode approveformyorg \
    -o $ORDERER_ADDR --tls --cafile $ORDERER_CA \
    --channelID $CHANNEL_NAME --name $CC_NAME --version $CC_VERSION \
    --package-id $CC_PACKAGE_ID --sequence $CC_SEQUENCE

# 4. Check Commit Readiness
echo "Checking commit readiness..."
$DOCKER_CMD exec cli peer lifecycle chaincode checkcommitreadiness \
    --channelID $CHANNEL_NAME --name $CC_NAME --version $CC_VERSION \
    --sequence $CC_SEQUENCE --output json

# 5. Commit Chaincode
echo "Committing chaincode definition..."
$DOCKER_CMD exec cli peer lifecycle chaincode commit \
    -o $ORDERER_ADDR --tls --cafile $ORDERER_CA \
    --channelID $CHANNEL_NAME --name $CC_NAME --version $CC_VERSION \
    --sequence $CC_SEQUENCE

# 6. Start Chaincode Container
echo "Starting Chaincode Container..."
# Build image first
$DOCKER_CMD build -t product_cc_server:1.0 ../../chaincode

# Remove existing container if any
$DOCKER_CMD rm -f chaincode-server || true

# Run container
$DOCKER_CMD run -d --name chaincode-server --network fabric_basic \
    -e CHAINCODE_SERVER_ADDRESS=0.0.0.0:9999 \
    -e CHAINCODE_ID=$CC_PACKAGE_ID \
    -e CORE_CHAINCODE_ID_NAME=$CC_PACKAGE_ID \
    product_cc_server:1.0

echo "Waiting for chaincode to start..."
sleep 5

# 7. Init Ledger
echo "Invoking InitLedger function..."
$DOCKER_CMD exec cli peer chaincode invoke \
    -o $ORDERER_ADDR --tls --cafile $ORDERER_CA \
    -C $CHANNEL_NAME -n $CC_NAME \
    -c '{"function":"InitLedger","Args":[]}' \
    --waitForEvent

echo "Chaincode deployed successfully!"
