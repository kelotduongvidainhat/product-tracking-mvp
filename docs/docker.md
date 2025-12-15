# Docker & Environment Variables Guide

This document explains the key environment variables used in the Docker Compose files for the Product Tracking system.

## 1. Hyperledger Fabric (`infrastructure/fabric/docker-compose.yaml`)

### Peer Configuration (`peer-base`)
*   `CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock`: Points to the Docker socket, allowing the Peer to spawn chaincode containers (though we use external builders, this is standard).
*   `CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=fabric_basic`: Ensures chaincode containers are attached to the correct Docker network.
*   `FABRIC_LOGGING_SPEC=INFO`: Sets logging level (INFO, DEBUG, ERROR).
*   `CORE_PEER_TLS_ENABLED=true`: Enables TLS for secure communication between nodes.
*   `CORE_PEER_ID=peer0.org1.example.com`: Unique identifier for the peer node.
*   `CORE_PEER_ADDRESS=peer0.org1.example.com:7051`: The address where this peer listens for requests from other peers and clients.
*   `CORE_PEER_LISTENADDRESS=0.0.0.0:7051`: Binds the listener to all interfaces inside the container.
*   `CORE_PEER_CHAINCODEADDRESS=peer0.org1.example.com:7052`: Address for chaincode logs/shim (Chaincode-Support).
*   `CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org1.example.com:7051`: Address advertised to other organizations for gossip (data dissemination).
*   `CORE_PEER_LOCALMSPID=Org1MSP`: ID of the MSP this peer belongs to.

### Orderer Configuration
*   `ORDERER_GENERAL_LISTENADDRESS=0.0.0.0`: Binds the orderer listener.
*   `ORDERER_GENERAL_GENESISMETHOD=file`: Tells the orderer to bootstrap from a genesis block file using the path specified in `ORDERER_GENERAL_GENESISFILE`.
*   `ORDERER_GENERAL_LOCALMSPID=OrdererMSP`: ID of the Orderer's MSP.

## 2. Backend Infrastructure (`infrastructure/docker-compose-backend.yaml`)

### PostgreSQL
*   `POSTGRES_USER`: Superuser name for the database (read from `.env`).
*   `POSTGRES_PASSWORD`: Password for the superuser (read from `.env`).
*   `POSTGRES_DB`: Name of the default database to create on startup (read from `.env`).

### Kafka & Zookeeper
*   `KAFKA_BROKER_ID`: Unique integer ID for the Kafka broker.
*   `KAFKA_ZOOKEEPER_CONNECT`: Address of the Zookeeper instance (`zookeeper:2181`).
*   `KAFKA_ADVERTISED_LISTENERS`: Addresses clients use to connect.
    *   `PLAINTEXT://kafka:29092`: Internal Docker network address (for Go services).
    *   `PLAINTEXT_HOST://localhost:9092`: External address (for host machine access).
*   `KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1`: Since we have only 1 broker, replication must be 1.

## 3. Application Services (`backend/docker-compose-app.yaml`)

### API Service & Worker Service
*   `DB_CONN_STR`: Connection string for PostgreSQL, constructed dynamically using `.env` variables (`postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}?sslmode=disable`).
*   `KAFKA_BROKER`: Address of the Kafka broker (`kafka:29092`).
*   `DISCOVERY_AS_LOCALHOST=false` (Worker only): Tells Fabric SDK that the peers are running in containers (hostname resolution), not on `localhost`.

---
**Note:** The system relies on a `.env` file at the root to supply sensitive credentials (DB User/Pass) to these compose files.
