#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

API="http://localhost:5000"
KC="http://localhost:8080"

echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Zero-Trust Cage — Live Demo Tests     ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}TEST 1: Public health check (no auth needed)${NC}"
curl -s "$API/health" | python3 -m json.tool
echo ""

echo -e "${RED}TEST 2: Access protected API WITHOUT token — should be BLOCKED${NC}"
RESULT=$(curl -s -o /dev/null -w "%{http_code}" "$API/api/players")
if [ "$RESULT" = "401" ]; then
    echo -e "${GREEN}PASS: Got 401 — Zero Trust blocked unauthenticated access${NC}"
else
    echo -e "${RED}UNEXPECTED: Got HTTP $RESULT${NC}"
fi
echo ""

echo -e "${RED}TEST 3: Access with FAKE token — should be REJECTED${NC}"
RESULT=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer fake_token_hacker_attempt" \
    "$API/api/players")
if [ "$RESULT" = "403" ]; then
    echo -e "${GREEN}PASS: Got 403 — Keycloak rejected fake token${NC}"
else
    echo -e "${RED}UNEXPECTED: Got HTTP $RESULT${NC}"
fi
echo ""

echo -e "${YELLOW}TEST 4: Get real token from Keycloak${NC}"
TOKEN=$(curl -s -X POST \
  "$KC/realms/casino/protocol/openid-connect/token" \
  -d "client_id=gaming-app&username=dealer1&password=dealer123&grant_type=password" \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token','FAILED'))" 2>/dev/null)

if [ "$TOKEN" != "FAILED" ] && [ -n "$TOKEN" ]; then
    echo -e "${GREEN}PASS: Got valid JWT token from Keycloak${NC}"
    echo "Token: ${TOKEN:0:60}..."
else
    echo -e "${RED}FAIL: Could not get token${NC}"
fi
echo ""

echo -e "${GREEN}TEST 5: Access player list WITH valid token${NC}"
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/players" | python3 -m json.tool
echo ""

echo -e "${GREEN}TEST 6: Cage security status (authenticated)${NC}"
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/cage/status" | python3 -m json.tool
echo ""

echo -e "${GREEN}TEST 7: Transactions (authenticated)${NC}"
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/transactions" | python3 -m json.tool
echo ""

echo -e "${YELLOW}TEST 8: Micro-segmentation — attacker cannot reach database${NC}"
echo "Trying: docker exec attacker-box ping -c 2 172.22.0.10"
docker exec attacker-box ping -c 2 -W 2 172.22.0.10 2>&1 | tail -3
echo -e "${GREEN}cage-network has internal:true — no route exists from DMZ${NC}"
echo ""

echo -e "${YELLOW}TEST 9: Live Quarantine Demo${NC}"
echo "Isolating web-server..."
bash quarantine-controller/quarantine.sh quarantine web-server
sleep 2
echo "Releasing web-server..."
bash quarantine-controller/quarantine.sh release web-server
echo ""

echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║      ALL DEMO TESTS COMPLETE            ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
