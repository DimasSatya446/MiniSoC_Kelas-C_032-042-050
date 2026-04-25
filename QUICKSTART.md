# Quick Start Guide - Mini SOC

Panduan cepat untuk mulai menggunakan Mini SOC dalam 5 menit.

## 🚀 Prerequisites

- Docker & Docker Compose installed
- At least 4GB RAM available
- Port 8080, 5601, 1514-1516 available
- (On Windows) Run terminal as Administrator

## ⚡ 5-Minute Setup

### 1. Navigate to Project Directory
```bash
cd c:\Users\Abiyyu\Documents\Coding\SOC\MiniSOC\MiniSoC_Kelas-C_032-042-050
```

### 2. Start All Services

**On Linux/Mac:**
```bash
chmod +x start.sh
./start.sh
```

**On Windows (cmd):**
```cmd
start.bat
```

**Or manually:**
```bash
docker-compose up -d
```

### 3. Wait 2-3 Minutes

Services are starting. You can check status:
```bash
docker-compose ps
```

All should show "Up" status.

### 4. Access Services

Open in browser:

1. **DVWA**: http://localhost:8080
   - Login: `admin` / `password`
   - Go to: Vulnerabilities menu

2. **Wazuh Dashboard**: https://localhost:5601
   - Login: `admin` / `SecurePassword123!`
   - Go to: Security Events

## 🎯 Run Your First Attack (5 minutes)

### Option A: Automated Attacks (Easiest)

**Linux/Mac:**
```bash
chmod +x attack.sh
./attack.sh
```

**Windows:**
```cmd
REM Run attacks one by one in PowerShell or Git Bash
curl "http://localhost:8080/vulnerabilities/sqli/?id=admin%27%20OR%20%271%27%3D%271"
```

### Option B: Manual Attack

1. Open DVWA: http://localhost:8080/vulnerabilities/sqli/
2. Type in "User ID" field: `admin' OR '1'='1`
3. Click submit
4. Database records appear (attack works!)

### Option C: One-Line Attack

```bash
curl "http://localhost:8080/vulnerabilities/sqli/?id=1%27%20UNION%20SELECT%20user%28%29%2Cdatabase%28%29%20--"
```

## 📊 See the Alert in Wazuh

1. Go to: https://localhost:5601
2. Click: **Security Events**
3. Look for alerts with:
   - Rule ID: 100100 (SQL Injection)
   - Severity: CRITICAL (10)
4. Click alert to see details

## 📚 Next Steps

- Read [docs/demo-flow.md](docs/demo-flow.md) for step-by-step demo
- Read [docs/attack-scenario.md](docs/attack-scenario.md) for more attack examples
- Read [docs/detection.md](docs/detection.md) to understand rules
- Read [docs/incident-response.md](docs/incident-response.md) for response procedures

## 🆘 Troubleshooting

### Services won't start
```bash
# Check Docker is running
docker ps

# View error logs
docker-compose logs

# Restart everything
docker-compose down
docker-compose up -d
```

### Can't access DVWA
```bash
# Check DVWA container is running
docker-compose ps dvwa

# View DVWA logs
docker-compose logs dvwa

# Test with curl
curl http://localhost:8080
```

### Can't access Wazuh Dashboard
```bash
# Check if Indexer is healthy
docker-compose exec wazuh-indexer curl -u admin:SecurePassword123! https://localhost:9200 -k

# Wait a bit more (takes 2-3 min to fully initialize)
```

### Logs not appearing in Wazuh
```bash
# Check filebeat is sending logs
docker-compose logs filebeat

# Check nginx logs exist
docker-compose exec nginx tail /var/log/nginx/access.log

# Restart filebeat
docker-compose restart filebeat
```

## 🛑 Stop Services

**Linux/Mac:**
```bash
./cleanup.sh
```

**Windows:**
```cmd
cleanup.bat
```

**Or manually:**
```bash
docker-compose down
```

## 📞 Common Commands

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f wazuh-manager

# Restart services
docker-compose restart

# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Rebuild containers
docker-compose up -d --build

# Execute command in container
docker-compose exec dvwa ls /var/www/html
```

## 🔑 Important URLs & Credentials

| Service | URL | Username | Password |
|---------|-----|----------|----------|
| DVWA | http://localhost:8080 | admin | password |
| Wazuh | https://localhost:5601 | admin | SecurePassword123! |
| Nginx Health | http://localhost/health | - | - |

## 📖 Documentation Structure

```
├── README.md                    # Full project documentation
├── QUICKSTART.md               # This file
├── docs/
│   ├── attack-scenario.md      # Attack examples & payloads
│   ├── demo-flow.md            # Step-by-step demo guide
│   ├── detection.md            # Detection rules explained
│   ├── incident-response.md    # Incident handling procedures
│   └── log-collection.md       # Log architecture explained
├── wazuh/rules/
│   └── custom_rules.xml        # Detection rules
├── nginx/
│   ├── nginx.conf              # Nginx main config
│   └── conf.d/default.conf     # DVWA proxy config
├── filebeat/
│   └── filebeat.yml            # Log forwarder config
└── scripts/
    ├── start.sh / start.bat     # Startup script
    ├── attack.sh               # Automated attacks
    └── cleanup.sh / cleanup.bat # Cleanup script
```

---

**Last Updated**: 2026-04-25

Happy hacking! 🛡️
