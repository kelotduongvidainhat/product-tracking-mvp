#!/bin/bash

# setup.sh - Check and setup environment for Product Tracking Project
# Automatically downloads and installs: Go, Node.js (via NVM) if missing.
# Installation guide: Docker (due to root/system requirements)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== START ENVIRONMENT CHECK ===${NC}"

# Check for root privileges
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}!!! WARNING: YOU ARE RUNNING THIS SCRIPT AS ROOT !!!${NC}"
    echo -e "${YELLOW}Node.js and Go are recommended to be installed as a normal user to avoid permission errors.${NC}"
    echo -e "${YELLOW}This script is designed to run as a normal user and will ask for sudo password when needed.${NC}"
    echo -e "If you continue, tools might verify incorrectly or behave unexpectedly."
    read -p "Are you sure you want to continue? (y/N): " confirm_root
    if [[ "$confirm_root" != "y" && "$confirm_root" != "Y" ]]; then
        echo -e "${GREEN}Cancelled. Please run the script WITHOUT sudo (e.g., ./scripts/setup.sh)${NC}"
        exit 1
    fi
fi

# Function to check command
check_cmd() {
    if command -v "$1" >/dev/null 2>&1; then
        echo -e "${GREEN}✔ $1 is installed: $( $1 --version | head -n 1 )${NC}"
        return 0
    else
        echo -e "${YELLOW}✘ $1 is NOT installed.${NC}"
        return 1
    fi
}

# 1. Check basic system tools (curl, git, make, tar, unzip)
echo -e "\n${BLUE}[1/4] Checking basic system tools...${NC}"
REQUIRED_SYS_TOOLS=("curl" "git" "make" "tar" "unzip")
MISSING_SYS_TOOLS=()

for tool in "${REQUIRED_SYS_TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        MISSING_SYS_TOOLS+=("$tool")
    else
        echo -e "${GREEN}✔ $tool OK${NC}"
    fi
done

if [ ${#MISSING_SYS_TOOLS[@]} -ne 0 ]; then
    echo -e "${RED}Missing basic tools: ${MISSING_SYS_TOOLS[*]}. Attempting to install via apt-get (sudo required)...${NC}"
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y "${MISSING_SYS_TOOLS[@]}"
    else
        echo -e "${RED}apt-get not found. Please install manually: ${MISSING_SYS_TOOLS[*]}${NC}"
        exit 1
    fi
fi

# 2. Check Docker
echo -e "\n${BLUE}[2/4] Checking Docker...${NC}"
if check_cmd "docker"; then
    echo "Docker is ready."
else
    echo -e "${YELLOW}Downloading automatic Docker installation script...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    echo -e "${YELLOW}Please run the following command to install Docker (requires root):${NC}"
    echo -e "  sudo sh get-docker.sh"
    echo -e "${YELLOW}Then add your current user to the docker group:${NC}"
    echo -e "  sudo usermod -aG docker \$USER && newgrp docker"
fi

# 3. Check Golang
echo -e "\n${BLUE}[3/4] Checking Golang...${NC}"
GO_VERSION="1.21.5"
GO_TAR="go$GO_VERSION.linux-amd64.tar.gz"
INSTALL_DIR="$HOME/.local/go"
if ! command -v go >/dev/null 2>&1; then
    echo -e "${YELLOW}Go missing. Automatically downloading version $GO_VERSION ...${NC}"
    cd /tmp
    curl -OL "https://go.dev/dl/$GO_TAR"
    
    echo -e "${YELLOW}Extracting to $INSTALL_DIR ...${NC}"
    mkdir -p "$HOME/.local"
    rm -rf "$INSTALL_DIR"
    tar -C "$HOME/.local" -xzf "$GO_TAR"
    # Note: go tarball usually contains 'go' directory, so it extracts to $HOME/.local/go
    
    # Setup temporary PATH for this script
    export PATH=$PATH:$INSTALL_DIR/bin
    
    # Configure shell profile
    SHELL_PROFILE="$HOME/.bashrc"
    if [ -n "$ZSH_VERSION" ]; then SHELL_PROFILE="$HOME/.zshrc"; fi
    
    if ! grep -q "$INSTALL_DIR/bin" "$SHELL_PROFILE"; then
        echo -e "${GREEN}Updating PATH in $SHELL_PROFILE ...${NC}"
        echo "export PATH=\$PATH:$INSTALL_DIR/bin" >> "$SHELL_PROFILE"
        echo "export GOPATH=$HOME/go" >> "$SHELL_PROFILE"
        echo "export PATH=\$PATH:\$GOPATH/bin" >> "$SHELL_PROFILE"
    fi
    
    echo -e "${GREEN}Golang installed. Please run 'source $SHELL_PROFILE' after script finishes.${NC}"
    go version
else
    echo -e "${GREEN}✔ Go is installed: $(go version)${NC}"
fi

# 4. Check Node.js & npm (Frontend - Next.js)
echo -e "\n${BLUE}[4/4] Checking Node.js & npm...${NC}"
if ! command -v node >/dev/null 2>&1; then
    echo -e "${YELLOW}Node.js missing. Attempting to install NVM and Node.js LTS...${NC}"
    
    # Install NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # Load NVM immediately
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install Node LTS
    nvm install --lts
    nvm use --lts
    
    echo -e "${GREEN}Installed Node.js: $(node -v) and npm: $(npm -v)${NC}"
else
    echo -e "${GREEN}✔ Node.js is installed: $(node -v)${NC}"
    echo -e "${GREEN}✔ npm is installed: $(npm -v)${NC}"
fi

echo -e "\n${BLUE}=== COMPLETE ===${NC}"
echo -e "${YELLOW}Note: If you just installed Go or Node.js, run this to update env vars immediately:${NC}"
echo -e "  source ~/.bashrc  (or source ~/.zshrc)"
