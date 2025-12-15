# Deployment Guide

This guide describes how to deploy the **Product Origin Authentication System** to a remote server (VPS, Cloud Instance, etc.).

## 1. Prerequisites (Remote Server)

Ensure your server is running a Linux distribution (e.g., Ubuntu 20.04/22.04 LTS).

### Install Docker & Docker Compose
```bash
# Update packages
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add current user to docker group (avoid sudo for docker commands)
sudo usermod -aG docker $USER
newgrp docker

# Verify
docker --version
docker compose version
```

## 2. Clone Repository

```bash
git clone https://github.com/kelotduongvidainhat/product-tracking-mvp.git
cd product-tracking-mvp
```

## 3. Configuration

### Environment Variables (.env)
Copy the example configuration:
```bash
cp .env.example .env
```
Typically, you don't need to change much here for a basic deployment, as the internal services talk to each other via Docker networks.

### Frontend Configuration
If you want the frontend (Next.js) to be accessible from the internet and talk to the backend, you need to ensure the **Public API URL** is correct.

By default, the `web_app` container is configured via `frontend/docker-compose.yaml`:
```yaml
environment:
  - NEXT_PUBLIC_API_URL=http://localhost:8081/products
```

**For Remote Deployment:**
You have two options:
1.  **Strict Client-Side Access:** If the user's browser needs to call the API directly, `NEXT_PUBLIC_API_URL` must be the **Public IP** or **Domain** of your server.
    *   Edit `frontend/docker-compose.yaml` or override it.
    *   Example: `NEXT_PUBLIC_API_URL=http://your-server-ip:8081/products`
2.  **Reverse Proxy (Recommended):** Use Nginx to serve the frontend on Port 80 and proxy `/api` requests to the backend. This avoids CORS issues and exposing port 8081 directly.

## 4. Firewall / Security Groups

Ensure the following ports are open (Inbound Rules) on your cloud provider's firewall:
*   `3000`: Frontend Web App
*   `8081`: Backend API
*   `8080`: Kafka UI (Optional, for monitoring)
*   `22`: SSH (Standard)

## 5. Deployment Steps

Run the automation scripts in order:

```bash
# 1. Clean previous state (if any)
sudo make network-clean

# 2. Generate Certs (Required for fresh install)
./scripts/generate_certs.sh

# 3. Start Infrastructure (Postgres, Kafka)
make infra-up

# 4. Start Blockchain Network
make network-up
# Wait 10-15 seconds for containers to stabilize...
./scripts/init_network.sh
./scripts/deploy_chaincode.sh

# 5. Start Backend Services
make app-up

# 6. Start Frontend
make frontend-up
```

## 6. Accessing the App

*   **Frontend:** `http://<YOUR_SERVER_IP>:3000`
*   **API:** `http://<YOUR_SERVER_IP>:8081`
*   **Kafka UI:** `http://<YOUR_SERVER_IP>:8080`

## 7. Troubleshooting Remote Access

*   **"Connection Refused"**: Check your AWS Security Groups / DigitalOcean Firewall to ensure port 3000/8081 is open to `0.0.0.0/0`.
*   **API Errors in Frontend**: Open Browser Console (F12). If you see `ERR_CONNECTION_REFUSED` for requests to `localhost:8081`, it's because the Next.js app running in the *user's browser* is trying to hit `localhost`. 
    *   **Fix:** You MUST update `NEXT_PUBLIC_API_URL` in `frontend/docker-compose.yaml` to be `http://<YOUR_SERVER_IP>:8081` and `make frontend-up` to rebuild.
