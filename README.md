# Product Origin Authentication & Anti-Counterfeiting System (MVP)

This project is a complete End-to-End product origin verification system, leveraging Blockchain (Hyperledger Fabric) to ensure data immutability, combined with a high-performance Backend (Go, Kafka) and a multi-platform Frontend (Flutter).

## 🌟 Key Features

*   **Blockchain Authentication:** Product data originating from the source is stored on Hyperledger Fabric and cannot be tampered with.
*   **Event-Driven Architecture:** Utilizes Kafka for asynchronous processing, ensuring the system remains responsive and is not blocked by Blockchain write latency.
*   **Multi-Platform:** The application runs smoothly on Android, iOS, and Web.
*   **User Experience:** Clear role separation (Producer/Consumer), supporting high-speed QR Code scanning.
*   **Easy Deployment:** The entire system is packaged and verified using Docker Compose.

## 🏗 System Architecture

The system consists of 4 main layers:

1.  **Blockchain Layer (Infrastructure):**
    *   **Hyperledger Fabric v2.5:** Enterprise-grade blockchain network.
    *   **Chaincode (Smart Contract):** Written in Golang, managing business logic (Create, Query products).
    *   **CCAAS (Chaincode as a Service):** Modern chaincode deployment model.

2.  **Backend Layer (Microservices):**
    *   **API Service (Golang + Gin):** RESTful gateway, handling authentication and fast queries (via DB Cache).
    *   **Worker Service (Golang + Fabric SDK):** Kafka consumer responsible for signing and submitting transactions to the Blockchain.
    *   **Message Queue (Kafka & Zookeeper):** Data buffering ensuring reliability and scalability.
    *   **Database (PostgreSQL):** Stores off-chain data for high-speed querying (CQRS pattern).

3.  **Frontend Layer (Mobile/Web):**
    *   **Flutter App:** Single codebase for both mobile and web.
    *   **Producer Mode:** Create new product batches.
    *   **Consumer Mode:** Scan QR codes or enter IDs to verify information and blockchain signatures.

4.  **DevOps:**
    *   **Docker & Docker Compose:** Container management.
    *   **Makefiles & Shell Scripts:** Automation for setup, testing, and deployment.

---
## ⚠️ Disclaimer

This project was created for **learning and research purposes**.
All feedback is welcome and much appreciated, including criticism and "brickbats" 🧱!

> **Note:** The AI built the MVP, while the "Monkey"🐒 (Human) is responsible for reviewing the design, disassembling, and fixing it.

## 🛠 Prerequisites

*   **Docker & Docker Compose** (Required)
*   **Go** (1.20+)
*   **Flutter** (3.0+)
*   **Make** (Standard on Linux/Mac, requires installation on Windows)

## 🚀 Getting Started

### 1. Start Infrastructure & Backend

Use the `Makefile` to spin up the entire system with a few commands:

```bash
# 1. Initialize Blockchain Network (Generate crypto material, channel, join peer, deploy chaincode)
make network-up

# 2. Start Backend (Postgres, Kafka, Zookeeper, API, Worker)
# Note: First run may take time to build Docker images
make infra-up
make app-up
```

*System endpoints:*
*   **API Service:** `http://localhost:8081`
*   **Kafka UI:** `http://localhost:8080` (To monitor messages)

### 2. Environment Configuration (.env)

The system uses a `.env` file for security management.
Copy the example file and modify if necessary:

```bash
cp .env.example .env
```

### 3. Run Client App (Flutter)

Open a new terminal:

```bash
cd frontend/mobile_app
flutter pub get

# Run on Chrome (Web)
flutter run -d chrome

# Or run on Android (requires connected device/emulator)
flutter run
```

## 🧪 Testing

The project comes with automated test scripts:

1.  **Blockchain Test (Chaincode):**
    ```bash
    make test
    ```
2.  **Integration Test (Full Flow):**
    ```bash
    ./scripts/test_integration.sh
    ```
    *This script simulates product creation via API -> Kafka -> Worker -> Blockchain -> DB and verifies the final state.*

## 📂 Project Structure

```
product-tracking/
├── backend/                # Backend Source Code
│   ├── api-service/        # API Server (Go)
│   ├── worker-service/     # Blockchain Worker (Go)
│   └── docker-compose-app.yaml
├── chaincode/              # Smart Contract (Go)
├── frontend/               # Frontend Source Code
│   └── mobile_app/         # Flutter App
├── infrastructure/         # Infrastructure Configuration
│   ├── fabric/             # Hyperledger Fabric Config
│   └── docker-compose-backend.yaml # Postgres & Kafka
├── scripts/                # Automation Scripts (bash)
├── Makefile                # Command Shortcuts
└── README.md               # Documentation
```

## 🛡 Security

*   Blockchain Private Keys are gitignored.
*   Database credentials are managed via environment variables (`.env`).
*   API supports CORS for secure browser execution.

## 🔮 Roadmap

*   [x] MVP: Create & Read Product (Blockchain + App).
*   [ ] User Authentication (Auth0 / JWT).
*   [ ] Ownership Transfer History.
*   [ ] IoT Sensor Integration for automatic status updates.

---


