# Mini SOC (Security Operations Center) - DVWA Monitoring Lab

Proyek ini membangun Mini SOC sederhana namun realistis untuk monitoring dan respons insiden pada web application vulnerabilities menggunakan DVWA (Damn Vulnerable Web Application). Konsep utama adalah **Attack-to-Alert Pipeline**: setiap serangan dapat dilihat alurnya dari aktivitas attacker → log → deteksi SIEM → alert → analisis → response.

## 📋 Project Overview

Mini SOC ini dirancang sebagai lab pembelajaran untuk memahami:
- **Proses SIEM**: Bagaimana security events dikumpulkan, dianalisis, dan ditindaklanjuti
- **Attack Detection**: Mendeteksi serangan web umum (SQL Injection, XSS, Brute Force, File Upload)
- **Incident Response**: Menganalisis alert dan melakukan response yang tepat
- **Log Collection**: Bagaimana log dari berbagai source dikumpulkan secara terpusat

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│         Attack Sources                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │   SQLi   │  │   XSS    │  │ Brute    │ ...  │
│  │          │  │          │  │ Force    │      │
│  └──────────┘  └──────────┘  └──────────┘      │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│  DVWA (Vulnerable Web App)                      │
│  Running in Docker Container                   │
│  ┌──────────────────────────────────────────┐  │
│  │ Vulnerable endpoints:                    │  │
│  │ - SQL Injection                          │  │
│  │ - XSS (Reflected/Stored)                 │  │
│  │ - File Upload                            │  │
│  │ - Brute Force                            │  │
│  └──────────────────────────────────────────┘  │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│  Nginx Reverse Proxy                            │
│  - Log collection point                         │
│  - Access log generation                        │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│  Log Collection & Analysis                      │
│  - Shared Volume (mount Nginx logs to Manager)  │
│  - Direct Ingestion by Wazuh Manager            │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│  Wazuh SIEM Stack                               │
│  ┌─────────────────────────────────────────┐   │
│  │ Manager: Rules & Analysis Engine        │   │
│  ├─────────────────────────────────────────┤   │
│  │ Indexer: Log Storage & Indexing         │   │
│  ├─────────────────────────────────────────┤   │
│  │ Dashboard: Visualization & Analysis     │   │
│  └─────────────────────────────────────────┘   │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│  Alert & Response                               │
│  - Alert notifications                          │
│  - Incident analysis                            │
│  - Mitigation actions                           │
└─────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- Minimum 4GB RAM available
- Port availability: 8080 (DVWA/Nginx), 443 (Dashboard), 1514-1516 (Wazuh)

### Setup & Run

1. **Clone repository**
```bash
git clone https://github.com/DimasSatya446/MiniSoC_Kelas-C_032-042-050.git
cd MiniSoC_Kelas-C_032-042-050
```

2. **Configure environment (optional)**
```bash
# Copy dan edit .env jika diperlukan
cp .env.example .env
```

3. **Start all services**
```bash
docker-compose up -d
```

4. **Wait for services to be ready** (2-3 minutes)
```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs -f wazuh-manager
```

5. **Access services**
- **DVWA**: http://localhost:8080
  - Username: `admin`
  - Password: `password`
- **Wazuh Dashboard**: https://localhost:443
  - Username: `admin`
  - Password: `SecretPassword`

## 📖 Project Structure

```
├── README.md                          # Dokumentasi utama (file ini)
├── docker-compose.yml                 # Container orchestration
├── .env.example                       # Environment variables template
│
├── docs/                              # Dokumentasi lengkap
│   ├── attack-scenario.md             # Detail skenario serangan
│   ├── demo-flow.md                   # Alur demonstrasi pipeline
│   ├── detection.md                   # Rule dan detection strategy
│   ├── log-collection.md              # Log collection architecture
│   └── incident-response.md           # Incident response procedures
│
├── dvwa/                              # DVWA configuration (jika ada)
│   └── .gitkeep
│
├── wazuh/                             # Wazuh configuration
│   └── rules/
│       └── custom_rules.xml           # Custom detection rules
│
├── logs/                              # Log directory (generated)
│   └── .gitkeep
│
└── screenshots/                       # Evidence screenshots
    └── .gitkeep
```

## 🎯 Fitur Utama

### 1. **Attack Scenarios**
- **SQL Injection (SQLi)**: Query manipulation untuk akses database
- **Cross-Site Scripting (XSS)**: Input script berbahaya
- **Brute Force**: Multiple login attempts
- **File Upload**: Upload file berbahaya

### 2. **Log Collection**
- Nginx access logs dikumpulkan
- Log dikirim ke Wazuh Manager
- Format log terstandar untuk parsing

### 3. **Detection & Rules**
- Rule untuk SQL Injection detection
- Rule untuk XSS detection  
- Rule untuk suspicious file access
- Severity level: 7-10 (Medium to High)

### 4. **Dashboard & Analysis**
- Alert visualization
- Log search & filtering
- Incident timeline
- Attack source tracking

### 5. **Response Actions**
- IP blocking recommendations
- Incident documentation
- Mitigation guidance
- Log preservation for forensics

## 📝 Usage Guide

### Menjalankan Attack

Lihat [docs/attack-scenario.md](docs/attack-scenario.md) untuk detail skenario serangan lengkap.

**Quick test - SQL Injection:**
```
URL: http://localhost:8080/vulnerabilities/sqli/
Payload: admin' OR '1'='1
```

**Quick test - XSS:**
```
URL: http://localhost:8080/vulnerabilities/xss_reflected/
Payload: <script>alert('XSS')</script>
```

### Monitor di Dashboard

1. Buka Wazuh Dashboard: https://localhost:443
2. Navigate ke "Security Events"
3. Filter by Rule: SQL Injection, XSS, File Upload
4. Analisis source IP, timestamp, payload

### Analyze & Respond

Lihat [docs/incident-response.md](docs/incident-response.md) untuk panduan lengkap.

## 🔍 Understanding the Pipeline

```
1. ATTACK EXECUTION
   └─> Attacker melakukan HTTP request dengan payload berbahaya ke DVWA

2. LOG GENERATION
   └─> Nginx mencatat request di access.log (complete URL dengan payload)

3. LOG TRANSMISSION
   └─> Log diakses langsung oleh Wazuh Manager melalui Shared Volume

4. RULE MATCHING
   └─> Wazuh engine mencocokkan log dengan custom rules
   └─> Match found (SQL Injection, XSS, etc.)

5. ALERT GENERATION
   └─> Alert dibuat dengan severity dan detail
   └─> Alert dikirim ke Indexer

6. DASHBOARD VISUALIZATION
   └─> Alert muncul di Wazuh Dashboard
   └─> SOC team bisa lihat: source IP, time, attack type, payload

7. ANALYSIS & RESPONSE
   └─> Analyst review alert
   └─> Identifikasi attacker dan impact
   └─> Execute response: block IP, document incident, recommend fix
```

## 🛠️ Configuration Files

### docker-compose.yml
Mendefinisikan semua services:
- DVWA container
- Nginx container
- Wazuh Manager, Indexer, Dashboard
- Volumes & networking

### wazuh/rules/custom_rules.xml
Custom detection rules untuk:
- SQL Injection detection
- XSS detection
- Suspicious file operations

## 📊 Key Metrics & Indicators

| Metric | Description |
|--------|-------------|
| Rule ID | Identifier untuk detection rule |
| Alert Level | Severity: 7-10 |
| Rule Match Count | Jumlah kali rule triggered |
| Top Attackers | Source IP dengan attack count tertinggi |
| Attack Types | SQL Injection, XSS, File Upload, Brute Force |
| Detection Rate | Time from attack to alert |

## 🔐 Security Notes

- **DVWA**: Intentionally vulnerable - gunakan HANYA di lab environment
- **No internet exposure**: Semua services running locally
- **Default credentials**: Ubah password Wazuh di production
- **Log retention**: Configure sesuai kebutuhan
- **Rule tuning**: Adjust sensitivity untuk reduce false positives

## 🐛 Troubleshooting

### Services tidak start
```bash
# Check logs
docker-compose logs

# Rebuild containers
docker-compose down
docker-compose up -d --build
```

### Wazuh Dashboard tidak accessible
```bash
# Check Wazuh Manager status
docker-compose exec wazuh-manager systemctl status wazuh-manager

# Check Indexer
docker-compose exec wazuh-indexer curl -u admin:SecretPassword https://localhost:9200 -k
```

### Logs tidak masuk ke Wazuh
```bash
# Verify Nginx is running
docker-compose exec nginx nginx -t

# Check Wazuh agent connectivity
docker-compose exec wazuh-manager wazuh-control info
```

## 📚 Documentation

Baca dokumentasi lengkap di folder `docs/`:
- [Attack Scenarios](docs/attack-scenario.md)
- [Log Collection Architecture](docs/log-collection.md)
- [Detection Rules](docs/detection.md)
- [Incident Response](docs/incident-response.md)
- [Demo Flow](docs/demo-flow.md)

## 👥 Team

Proyek Mini SOC Kelas C:
- Member 1: 032
- Member 2: 042
- Member 3: 050

## 📄 License

Educational purposes only. Based on DVWA and Wazuh open-source projects.

## 🔗 References

- [DVWA Documentation](http://www.dvwa.co.uk/)
- [Wazuh Documentation](https://documentation.wazuh.com/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

---

**Last Updated**: 2026-04-25  
**Status**: Active Development
