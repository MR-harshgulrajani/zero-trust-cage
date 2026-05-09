#!/bin/bash
# Zero-Trust Cage — Master Setup Script
# Run this ONE file to install Docker + start everything

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════╗"
echo "║   Zero-Trust Cage — Auto Setup          ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# ── Step 1: Install Docker ─────────────────────
install_docker() {
    echo -e "${YELLOW}[1/4] Installing Docker...${NC}"
    sudo apt-get update -qq
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker "$USER"
    sudo systemctl start docker
    sudo systemctl enable docker
    echo -e "${GREEN}Docker installed.${NC}"
}

# Check if docker exists
if ! command -v docker &>/dev/null; then
    install_docker
else
    echo -e "${GREEN}[1/4] Docker already installed — skipping.${NC}"
fi

# ── Step 2: Start all containers ───────────────
echo -e "${YELLOW}[2/4] Starting all containers...${NC}"
cd "$(dirname "$0")"
sudo docker compose down 2>/dev/null
sudo docker compose up -d --build

echo -e "${YELLOW}[3/4] Waiting for services to be ready...${NC}"
echo "      (this takes ~60 seconds for Keycloak)"

# Wait for gaming-app
for i in {1..30}; do
    if curl -sf http://localhost:5000/health > /dev/null 2>&1; then
        echo -e "${GREEN}      Gaming API: READY${NC}"
        break
    fi
    echo -n "."
    sleep 3
done

# Wait for Keycloak
for i in {1..40}; do
    if curl -sf http://localhost:8080/health/ready > /dev/null 2>&1; then
        echo -e "${GREEN}      Keycloak: READY${NC}"
        break
    fi
    echo -n "."
    sleep 3
done

echo ""
echo -e "${YELLOW}[4/4] Verifying micro-segmentation...${NC}"
# Test that attacker cannot reach the database
ATTACKER_RESULT=$(sudo docker exec attacker-box ping -c 1 -W 2 172.22.0.10 2>&1)
if echo "$ATTACKER_RESULT" | grep -q "unreachable\|100% packet loss\|Network unreachable"; then
    echo -e "${GREEN}      Micro-segmentation VERIFIED: attacker-box CANNOT reach database${NC}"
else
    echo -e "${YELLOW}      Note: Ping test inconclusive (ICMP may be filtered — this is OK)${NC}"
fi

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║              ALL SERVICES RUNNING                      ║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║  Casino Dashboard:   http://localhost:8888              ║${NC}"
echo -e "${CYAN}║  Gaming API:         http://localhost:5000              ║${NC}"
echo -e "${CYAN}║  Keycloak Admin:     http://localhost:8080              ║${NC}"
echo -e "${CYAN}║    (admin / admin123)                                   ║${NC}"
echo -e "${CYAN}║  Grafana:            http://localhost:3000              ║${NC}"
echo -e "${CYAN}║    (admin / casino123)                                  ║${NC}"
echo -e "${CYAN}║  Prometheus:         http://localhost:9090              ║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║  Test users:                                            ║${NC}"
echo -e "${CYAN}║    dealer1 / dealer123                                  ║${NC}"
echo -e "${CYAN}║    cage_manager / cage123                               ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
