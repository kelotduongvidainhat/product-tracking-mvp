# Blockchain "Lego" Guide: Modifying the Blocks

This guide explains how to swap or modify pieces of the Blockchain Layer, treating them like Lego blocks. It covers two main scenarios: Infrastructure Changes and Logic Changes.

## 🧱 Scenario A: Infrastructure Changes
*Replacing the foundation without changing the house.*

**Examples:** Adding a new Peer, changing an Organization's name, rotating expired certificates, or moving nodes to different servers.

### 1. Update Configuration
Modify `infrastructure/fabric/configtx.yaml` or `crypto-config.yaml` to reflect the changes.

### 2. Regenerate Artifacts
If you changed identity (MSP) or network structure, you must regenerate certificates and the genesis block.
```bash
./scripts/generate_certs.sh
```
*⚠️ Warning: This resets the entire blockchain history in a dev environment.*

### 3. Restart the Network
Apply the new infrastructure configurations by restarting Docker containers.
```bash
docker-compose -f infrastructure/fabric/docker-compose.yaml up -d --force-recreate
```

### 4. Update the Worker Service
The Worker Service connects to the blockchain using crypto materials (certificates). If these changed:
*   Ensure the volume mount in `backend/docker-compose-app.yaml` points to the new `crypto-config` folder.
*   Restart the Worker Service:
    ```bash
    make app-down && make app-up
    ```

### 🌟 Example Walkthrough: Adding a New Peer (peer1)
*Goal: Add a second peer node to Org1 for redundancy.*

1.  **Modify `infrastructure/fabric/crypto-config.yaml`:**
    Increment the peer count for Org1.
    ```yaml
    PeerOrgs:
      - Name: Org1
        Template:
          Count: 2 # Changed from 1 to 2
    ```

2.  **Regenerate Crypto Material:**
    ```bash
    ./scripts/generate_certs.sh
    ```
    *This generates specific certificates for the new node: `peer1.org1.example.com`.*

3.  **Update `infrastructure/fabric/docker-compose.yaml`:**
    Copy the `peer0` service definition and paste it to create `peer1`.
    *   Change Service Name: `peer1.org1.example.com`
    *   Change Port Mappings: Map `8051:7051` (Host:Container) to avoid conflict with peer0.
    *   Update Environment: `CORE_PEER_ID=peer1.org1.example.com` and `CORE_PEER_ADDRESS=peer1.org1.example.com:7051`.

4.  **Start and Join:**
    ```bash
    docker-compose -f infrastructure/fabric/docker-compose.yaml up -d
    # Enter CLI and join peer1 to channel
    docker exec -it cli bash
    # (Inside CLI) Export Peer1 variables
    export CORE_PEER_ADDRESS=peer1.org1.example.com:7051
    export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt
    # Join
    peer channel join -b mychannel.block
    ```

---

## 🧩 Scenario B: Chaincode (Logic) Changes
*Remodeling the interior rooms.*

**Examples:** Adding a `Price` field to a Product, renaming `CreateProduct` to `MintProduct`, or adding a new validation rule.

### 1. Update Chaincode Source
Modify `chaincode/smartcontract.go`.
*   Example: Add `Price string` to the `Product` struct.

### 2. Version Bump & Redeploy (Lifecycle Upgrade)
Hyperledger Fabric requires a version upgrade for new logic to take effect. You CANNOT just restart the container.

**Steps using `scripts/deploy_chaincode.sh`:**
1.  Open `scripts/deploy_chaincode.sh`.
2.  Increment the `CC_SEQUENCE` variable (e.g., from `1` to `2`).
3.  (Optional) Update `CC_VERSION` (e.g., to `1.1`).
4.  Run the script:
    ```bash
    ./scripts/deploy_chaincode.sh
    ```
    *This will package, install, approve, and commit the NEW code to the existing channel.*

### 3. Propagate Changes Upstream
Since the smart contract signature changed, you must update the calling layers.

*   **Worker Service (Go):**
    *   Update `backend/worker-service/main.go` to pass the new argument (e.g., `Price`) in the `EvaluateTransaction` or `SubmitTransaction` call.
    *   Rebuild the Worker: `make app-up`.

*   **API Service (Go):**
    *   Update the `Product` struct in `backend/api-service/main.go`.
    *   Update the `DB` schema (if you want to persist the new field off-chain).
    *   Rebuild.

*   **Frontend (Flutter):**
    *   Update the UI to allow inputting the new field.

---

## ⚠️ Important Note on "Lego" Compatibility
While the architecture is modular, the **Data Model** acts as the glue.
If you change the shape of the Lego block (Data Model in Chaincode), you **must** carve out space in the connecting blocks (Worker -> API -> Frontend) to make them fit again.
