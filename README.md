# Zero-Trust Cage — Quick Reference

## ONE COMMAND TO START EVERYTHING
```bash
chmod +x setup.sh && bash setup.sh
```
That's it. Docker installs itself, all containers start, Keycloak auto-configures.

---

## WHAT RUNS WHERE
| Service         | URL                        | Login              |
|----------------|----------------------------|--------------------|
| Casino Dashboard| http://localhost:8888      | —                  |
| Gaming API      | http://localhost:5000      | —                  |
| Keycloak Admin  | http://localhost:8080      | admin / admin123   |
| Grafana         | http://localhost:3000      | admin / casino123  |
| Prometheus      | http://localhost:9090      | —                  |

## TEST USERS (for API login)
| Username       | Password   | Role         |
|---------------|------------|--------------|
| dealer1        | dealer123  | Dealer       |
| cage_manager   | cage123    | Cage Manager |

---

## MANUAL DOCKER COMMANDS
```bash
# Start
docker compose up -d --build

# Stop
docker compose down

# See logs
docker compose logs -f gaming-app
docker compose logs -f keycloak

# Check running containers
docker compose ps
```

## DEMO TEST COMMANDS (for viva)
```bash
# Run all tests automatically
bash demo-test.sh

# Test 1: No auth → should get 401
curl http://localhost:5000/api/players

# Test 2: Fake token → should get 403
curl -H "Authorization: Bearer fake123" http://localhost:5000/api/players

# Test 3: Get real token
curl -X POST http://localhost:5000/auth/token \
  -d "username=dealer1&password=dealer123"

# Test 4: Use real token (paste token from above)
curl -H "Authorization: Bearer TOKEN_HERE" http://localhost:5000/api/players

# Test 5: Prove attacker can't reach database
docker exec attacker-box ping -c 2 172.22.0.10

# Test 6: Quarantine a container
bash quarantine-controller/quarantine.sh quarantine web-server
bash quarantine-controller/quarantine.sh release web-server
bash quarantine-controller/quarantine.sh status
```

---

## ZERO TRUST CONCEPTS DEMONSTRATED
1. **Never Trust, Always Verify** — every API call checks token with Keycloak
2. **Micro-segmentation** — 6 isolated Docker networks, cage has `internal: true`
3. **Least Privilege** — attacker-box only on DMZ, cannot reach database
4. **Fail Closed** — if Keycloak is down, ALL access is denied (not allowed)
5. **Audit Logging** — every access attempt logged to database
6. **Dynamic Quarantine** — compromised containers isolated in real time

---

## FILE STRUCTURE
```
zero-trust-cage/
├── docker-compose.yml        ← all containers + networks
├── db-init.sql               ← casino database schema + data
├── setup.sh                  ← ONE COMMAND SETUP
├── demo-test.sh              ← automated viva demo
├── gaming-app/
│   ├── app.py                ← Flask API (zero trust enforcement)
│   ├── requirements.txt
│   └── Dockerfile
├── web/
│   ├── nginx.conf            ← DMZ web server
│   └── index.html            ← casino dashboard UI
├── keycloak/
│   └── casino-realm.json     ← auto-imported realm + users
├── monitoring/
│   ├── prometheus.yml
│   └── provisioning/...      ← Grafana auto-config
└── quarantine-controller/
    └── quarantine.sh         ← dynamic isolation script
```
