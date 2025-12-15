# Setup Guide & Environment Configuration

This document provides instructions on how to install the necessary tools to develop and run the **Product Origin Authentication & Anti-Counterfeiting System** (MVP).

## 1. System Requirements (Prerequisites)

To run the entire stack smoothly (especially Hyperledger Fabric), minimal configuration is recommended:
*   **OS:** Linux (Ubuntu 20.04+), macOS, or Windows 10/11 (using WSL2).
*   **RAM:** Minimum 8GB (16GB recommended).
*   **CPU:** 2 cores or more.

## 2. Installing Core Tools

### A. Docker & Docker Compose (Critical)
The system uses Docker to run Databases, Kafka, and the Blockchain network.
*   **Download:** [Docker Desktop](https://www.docker.com/products/docker-desktop/) or [Docker Engine](https://docs.docker.com/engine/install/) (for Linux).
*   **Verify Installation:**
    ```bash
    docker --version
    docker-compose --version
    ```
*   *Note for Windows users:* Ensure you have enabled WSL2 mode in Docker Desktop settings.

### B. Go Programming Language (Golang)
Used for Backend API, Worker, and Chaincode.
*   **Version:** 1.20 or higher.
*   **Download:** [Go Installation](https://go.dev/doc/install)
*   **Environment Setup (GOPATH):** Ensure `go/bin` is added to your PATH.
*   **Verify:**
    ```bash
    go version
    ```

### C. Node.js & npm (Next.js Frontend)
Used for the Web Client.
*   **Version:** Node 18 (LTS) or higher.
*   **Download:** [Node.js Download](https://nodejs.org/) or use **nvm** (recommended).
*   **Verify:**
    ```bash
    node -v
    npm -v
    ```

## 3. Additional Tools & Config

### A. Hyperledger Fabric Tools
To facilitate development and interaction with the local Fabric network, we primarily use Docker images wrapped in shell scripts. No extra binary installation is strictly required on the host system, but knowing `peer` commands is helpful.

### B. Database Client (Optional)
To view data in PostgreSQL easily:
*   **DBeaver** or **pgAdmin**.

## 4. Sanity Check

After installation, try running the following commands in the terminal to ensure everything is ready:

1.  **Git:** `git --version`
2.  **Docker:** `docker ps` (Should not report permission denied errors)
3.  **Go:** `go env`
4.  **Make:** `make --version` (Required to run automated Makefile scripts).
5.  **Node:** `node -v`

## 5. Quick Start (Summary)

*(Detailed steps are in the main README.md)*

1.  **Clone repository:**
    ```bash
    git clone <repo_url>
    cd product-tracking
    ```

2.  **Setup Automated Environment:**
    You can run the setup script to check and install missing tools:
    ```bash
    ./scripts/setup.sh
    ```

3.  **Start Infrastructure:**
    ```bash
    make infra-up
    make network-up
    ```

4.  **Run Backend:**
    ```bash
    make app-up
    ```

5.  **Run Frontend (Next.js):**
    ```bash
    cd frontend/web_app
    npm run dev
    ```
