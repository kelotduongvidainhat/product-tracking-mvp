#!/bin/bash
# Script to clean up all generated artifacts (crypto materials, blocks, txs)

# Navigate to the infrastructure directory
cd "$(dirname "$0")/../infrastructure/fabric"

echo "Cleaning up generated files..."

# Remove Crypto Material
if [ -d "crypto-config" ]; then
    echo "Removing crypto-config..."
    rm -rf crypto-config
fi

# Remove Artifacts
echo "Removing artifacts..."
rm -f genesis.block
rm -f channel.tx
rm -f Org1MSPanchors.tx

# Remove Chaincode Packages
echo "Removing chaincode packages..."
rm -f product_cc.tar.gz

echo "Cleanup complete!"
