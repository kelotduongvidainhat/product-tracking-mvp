# Building the Blockchain Layer (Hyperledger Fabric)

This document details the step-by-step process used to build the Blockchain Layer for the Product Tracking MVP system.

## 1. Theoretical Concepts

Before diving into implementation, it's essential to understand the core components of Hyperledger Fabric.

### Hyperledger Fabric
A private, permissioned blockchain framework for developing enterprise-grade solutions. Unlike public blockchains (like Bitcoin/Ethereum), Fabric requires participants to be authenticated.

### Core Components
*   **Peer Node:**
    *   Maintains a copy of the **Ledger**.
    *   Hosts and executes **Chaincode** (smart contracts).
    *   Anchors the network for an organization.
*   **Orderer Node:**
    *   Does NOT execute smart contracts or hold the ledger state.
    *   Packages transactions into blocks and distributes them to Peers.
    *   Ensures consistency and finality.
*   **MSP (Membership Service Provider):**
    *   Manages identities (Certificates) and authentication.
    *   Defines who is a member of the network (e.g., `Org1MSP`, `OrdererMSP`).
*   **Channel:**
    *   A private subnet communication between specific network members.
    *   Data on one channel is invisible to members not on that channel.
    *   In this MVP, we use one channel: `mychannel`.
*   **Chaincode (Smart Contract):**
    *   Business logic executed on the peer.
    *   Written in Go (for this project), Java, or Node.js.
    *   Interacts with the Ledger (GetState, PutState).
*   **Ledger:**
    *   **World State:** Current value of attributes (usually stored in LevelDB or CouchDB). Allows fast queries.
    *   **Blockchain:** Immutable history of all transaction logs.

### Transaction Flow
1.  **Proposal:** Client (our Backend Worker) sends a transaction proposal to Peers.
2.  **Execution:** Peers execute Chaincode to simulate the outcome (Read/Write set) and sign it.
3.  **Submission:** Client collects signatures and sends them to the Orderer.
4.  **Ordering:** Orderer creates a block of transactions.
5.  **Validation & Commit:** Orderer sends the block to Peers. Peers validate signatures and version conflicts, then commit to the Ledger.

---

## 2. Prerequisites Setup
Start by ensuring the environment has the necessary tools:
*   **Docker & Docker Compose:** Container orchestration.
*   **Go (Golang):** For writing Chaincode.
*   **Make:** For build automation.

## 3. Infrastructure Configuration
We use `infrastructure/fabric/` to hold all Fabric-related configs.

### A. Crypto Material Definition (`crypto-config.yaml`)
Defined the organization structure:
*   **Orderer Org:** `OrdererMSP` (1 Node: `orderer.example.com`).
*   **Peer Org:** `Org1MSP` (1 Node: `peer0.org1.example.com` + Users).

### B. Channel & Genesis Block (`configtx.yaml`)
Defined the channel profiles:
*   **Genesis Profile:** Used to create the Orderer Genesis Block.
*   **Channel Profile:** Used to create the application channel (`mychannel`).

### C. Docker Compose (`docker-compose.yaml`)
Orchestrated the network nodes:
*   **Orderer:** Shifts blocks and ensures consistency.
*   **Peer0:** Validation peer, holds the ledger.
*   **CLI:** Admin container to run peer commands (create channel, join peer, deploy CC).

## 4. Automation Scripts
Located in `scripts/`, these Bash scripts automate complex Fabric admin tasks.

*   `generate_certs.sh`:
    *   Uses `cryptogen` to generate keys/certs based on `crypto-config.yaml`.
    *   Uses `configtxgen` to create `genesis.block` and `channel.tx`.
*   `init_network.sh`:
    *   Starts the network (`docker-compose up`).
    *   Creates the channel (`peer channel create`).
    *   Joins the Peer to the channel (`peer channel join`).
*   `package_ccaas.sh`:
    *   Prepares the Chaincode for "Chaincode as a Service" deployment.
    *   Archives the connection JSON instead of full source code.

## 5. Chaincode Development
Located in `chaincode/`.

*   **Language:** Golang.
*   **Struct:** `Product` (ID, Name, ProducerID, CertHash, Status, ManufactureDate).
*   **Logic:**
    *   `CreateProduct`: Checks existence, creates distinct key-value pair.
    *   `ReadProduct`: Queries ledger by ID.
    *   `ProductExists`: Helper function.
*   **Deployment Model (CCAAS):**
    *   We built a dedicated Docker image for the chaincode (`chaincode/Dockerfile`).
    *   The chaincode runs as a standalone service alongside the Peer, not spawned by the Peer.

## 6. Deployment & Testing

### A. Deployment Script (`deploy_chaincode.sh`)
This script executes the lifecycle chaincode commands:
1.  **Package:** Packages the external chaincode definition.
2.  **Install:** Installs package on Peer.
3.  **Approve:** Org1 approves the definition.
4.  **Commit:** Commits the definition to the Channel.
5.  **Init:** Initializes the chaincode.

### B. Testing
*   **Manual Test:** Using `peer chaincode invoke` from the CLI container.
*   **Automated Test:** `scripts/test_chaincode.sh` runs an End-to-End valid transaction flow.

## 7. Integration
The final Blockchain layer exposes 2 main interaction points:
1.  **Fabric SDK (Go):** Used by the Backend Worker to submit transactions.
2.  **Ledger:** Stores the immutable record of all `CreateProduct` transactions.

---

## 8. Manual Execution Steps

If you want to run the setup manually (without using `make` or the provided scripts), follow these commands.
**Note:** Run these commands from the `infrastructure/fabric` directory.

### Step 1: Generate Certificates & Artifacts
```bash
export FABRIC_TAG=2.5
export IMAGE_TAG="hyperledger/fabric-tools:$FABRIC_TAG"
export PWD=$(pwd)

# 1. Generate Crypto Material
docker run --rm -v $PWD:/data $IMAGE_TAG cryptogen generate --config=/data/crypto-config.yaml --output=/data/crypto-config

# 2. Generate Genesis Block
docker run --rm -v $PWD:/data $IMAGE_TAG configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock /data/genesis.block -configPath /data

# 3. Generate Channel Transaction (mychannel)
docker run --rm -v $PWD:/data $IMAGE_TAG configtxgen -profile TwoOrgsChannel -outputCreateChannelTx /data/channel.tx -channelID mychannel -configPath /data

# 4. Generate Anchor Peer Update
docker run --rm -v $PWD:/data $IMAGE_TAG configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate /data/Org1MSPanchors.tx -channelID mychannel -asOrg Org1MSP -configPath /data
```

### Step 2: Start the Network
```bash
docker-compose up -d
```

### Step 3: Initialize Channel
Execute these commands *inside* the CLI container:
```bash
# 1. Create Channel
docker exec cli peer channel create -o orderer.example.com:7050 -c mychannel -f ./channel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# 2. Join Peer to Channel
docker exec cli peer channel join -b mychannel.block
```

### Step 4: Deploy Chaincode (CCaaS)
Run these commands from the project root or adjust paths accordingly.

**1. Package Chaincode (Host):**
```bash
./scripts/package_ccaas.sh
cp infrastructure/fabric/product_cc.tar.gz infrastructure/fabric/
```

**2. Install Chaincode (CLI):**
```bash
docker cp infrastructure/fabric/product_cc.tar.gz cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/product_cc.tar.gz
docker exec cli peer lifecycle chaincode install product_cc.tar.gz
```

**3. Get Package ID:**
```bash
export CC_PACKAGE_ID=$(docker exec cli peer lifecycle chaincode queryinstalled | grep product_cc_1.0 | awk -F " " '{print $3}' | sed 's/,$//')
echo "Package ID: $CC_PACKAGE_ID"
```

**4. Approve Chaincode:**
```bash
docker exec cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID mychannel --name product_cc --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1
```

**5. Commit Chaincode:**
```bash
docker exec cli peer lifecycle chaincode commit -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID mychannel --name product_cc --version 1.0 --sequence 1
```

**6. Start Chaincode Server (Docker):**
```bash
docker build -t product_cc_server:1.0 chaincode
docker run -d --name chaincode-server --network fabric_basic -e CHAINCODE_SERVER_ADDRESS=0.0.0.0:9999 -e CHAINCODE_ID=$CC_PACKAGE_ID -e CORE_CHAINCODE_ID_NAME=$CC_PACKAGE_ID product_cc_server:1.0
```

**7. Init Ledger:**
```bash
docker exec cli peer chaincode invoke -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n product_cc -c '{"function":"InitLedger","Args":[]}' --waitForEvent
```
