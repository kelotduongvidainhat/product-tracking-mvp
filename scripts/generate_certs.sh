#!/bin/bash
# Script to generate crypto material and channel artifacts using Docker

export FABRIC_TAG=2.5
export IMAGE_TAG="hyperledger/fabric-tools:$FABRIC_TAG"

# Navigate to the infrastructure directory
cd "$(dirname "$0")/../infrastructure/fabric"

echo "Using image: $IMAGE_TAG"

# 1. Generate Crypto Material
echo "Generating crypto material..."
docker run --rm -v $(pwd):/data $IMAGE_TAG cryptogen generate --config=/data/crypto-config.yaml --output=/data/crypto-config

# 2. Generate Genesis Block
echo "Generating genesis block..."
docker run --rm -v $(pwd):/data $IMAGE_TAG configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock /data/genesis.block -configPath /data

# 3. Generate Channel Transaction
echo "Generating channel transaction..."
docker run --rm -v $(pwd):/data $IMAGE_TAG configtxgen -profile TwoOrgsChannel -outputCreateChannelTx /data/channel.tx -channelID mychannel -configPath /data

# 4. Generate Anchor Peer Update (Optional but good practice)
echo "Generating anchor peer update..."
docker run --rm -v $(pwd):/data $IMAGE_TAG configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate /data/Org1MSPanchors.tx -channelID mychannel -asOrg Org1MSP -configPath /data

echo "Done!"
