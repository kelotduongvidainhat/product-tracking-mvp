#!/bin/bash
set -e

# Ensure we are in the project root (The script is in scripts/)
cd "$(dirname "$0")/.."

# Package the chaincode
cd chaincode/packaging


tar -czf code.tar.gz connection.json
tar -czf product_cc.tar.gz code.tar.gz metadata.json
mv product_cc.tar.gz ../../infrastructure/fabric/
cd ../..
