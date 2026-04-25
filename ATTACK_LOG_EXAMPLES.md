# Mini SOC - LIVE Demo & Log Examples

Contoh real dari attack testing dan apa yang Anda akan lihat di logs.

---

## 🎬 LIVE Attack Demo Just Executed!

### Attack #1: SQL Injection
```
Payload: admin' OR '1'='1
URL: http://localhost:8080/vulnerabilities/sqli/?id=admin%27%20OR%20%271%27%3D%271
Status: ✅ 200 OK (Attack Successful)
```

---

## 📊 What You'd See in Each Log

### 1️⃣ Nginx Access Log
**File**: `/var/log/nginx/access.log`
**View Command**:
```bash
docker compose logs -f nginx
```

**Log Output Example**:
```
127.0.0.1 - - [25/Apr/2026:05:06:38 +0000] "GET /vulnerabilities/sqli/?id=admin%27%20OR%20%271%27%3D%271 HTTP/1.1" 200 1523
```

**What This Means**:
- `127.0.0.1` = Attack source (your machine)
- `GET /vulnerabilities/sqli/?id=` = Vulnerable endpoint
- `admin%27%20OR%20%271%27%3D%271` = URL-encoded SQLi payload
- `200` = HTTP status (successful request)
- `1523` = Response size in bytes

---

### 2️⃣ Wazuh Manager Log
**File**: `/var/ossec/logs/ossec.log`
**View Command**:
```bash
docker compose logs -f wazuh-manager
```

**Log Output Example** (Alert Generation):
```
2026-04-25 05:06:40 wazuh-analysisd: INFO: Rule ID 100100 matched: SQL Injection Attack Detected
2026-04-25 05:06:40 wazuh-analysisd: INFO: (1307) Following branch: 100100
2026-04-25 05:06:40 wazuh-analysisd: INFO: Generated alert: (Rule: 100100) Level: 10, Description: SQL Injection Attack Detected
```

**What This Means**:
- `Rule ID 100100` = SQLi detection rule matched
- `Level: 10` = CRITICAL severity
- Detection happened on Nginx access log

---

### 3️⃣ Wazuh Alerts (JSON)
**File**: `/var/ossec/logs/alerts/alerts.json`
**View Command**:
```bash
docker compose exec wazuh-manager tail -f /var/ossec/logs/alerts/alerts.json
```

**Log Output Example** (Structured Alert):
```json
{
  "timestamp": "2026-04-25T05:06:40.123+0000",
  "rule": {
    "id": 100100,
    "level": 10,
    "description": "SQL Injection Attack Detected",
    "groups": ["webapp", "sql_injection", "attack"]
  },
  "agent": {
    "id": "000",
    "name": "wazuh-manager"
  },
  "manager": {
    "name": "wazuh-manager"
  },
  "id": "1234567890.1234",
  "full_log": "127.0.0.1 - - [25/Apr/2026:05:06:38 +0000] \"GET /vulnerabilities/sqli/?id=admin%27%20OR%20%271%27%3D%271 HTTP/1.1\" 200 1523",
  "classification": {
    "description": "Malicious Code Detected"
  }
}
```

**What This Means**:
- Structured JSON format for programmatic access
- Contains all details: timestamp, rule ID, full original log
- Severity level: 10 (CRITICAL)
- Can be imported to dashboards/SIEMs

---

### 4️⃣ Filebeat Log
**File**: `/var/log/filebeat/filebeat`
**View Command**:
```bash
docker compose logs -f filebeat
```

**Log Output Example**:
```
2026-04-25T05:06:38.500Z       INFO    log/harvester.go:302   Harvester started for file: /var/log/nginx/access.log
2026-04-25T05:06:39.123Z       INFO    [publisher_pipeline_output] Starting processing...
2026-04-25T05:06:40.000Z       INFO    [publisher] Sent event to Elasticsearch
```

**What This Means**:
- Filebeat is reading logs from Nginx
- Events are being sent to Elasticsearch/Wazuh
- Connection status to Wazuh Manager

---

## 🔍 Complete Log Flow Diagram

```
ATTACK EXECUTION (Your Command)
    ↓ (HTTP Request)
NGINX Receives & Logs
    ↓ (Log File Written)
/var/log/nginx/access.log
    ↓ (Filebeat Reads)
FILEBEAT Collects
    ↓ (Sends on Port 1514)
WAZUH MANAGER Receives
    ↓ (Analyzes Against Rules)
/var/ossec/logs/ossec.log (Processing)
    ↓ (Rule Match!)
ALERT GENERATED
    ↓ (JSON Format)
/var/ossec/logs/alerts/alerts.json
    ↓ (Filebeat Ships)
ELASTICSEARCH Indexed
    ↓ (Data Available)
WAZUH DASHBOARD Visible
```

---

## 📈 Timeline Example: Single SQLi Attack

```
T+0s   You execute: Invoke-WebRequest http://localhost:8080/vulnerabilities/sqli/...
       ↓
T+1s   Nginx receives HTTP GET request
       ├─ Processes request
       └─ Returns 200 OK
       ↓
T+2s   Nginx writes to /var/log/nginx/access.log:
       127.0.0.1 - - [25/Apr/2026:05:06:38] "GET /vulnerabilities/sqli/?id=admin%27%20OR%20%271%27%3D%271" 200
       ↓
T+3s   Filebeat scans nginx log directory
       └─ Detects new log entry
       ↓
T+4s   Filebeat sends log to Wazuh Manager (port 1514)
       ↓
T+5s   Wazuh receives and parses log
       └─ Extracts: source IP, URL, payload
       ↓
T+6s   Wazuh analyzes with rule 100100 (SQLi Detection)
       └─ Pattern match: "' OR '1'='1" = SQLi signature
       ↓
T+7s   ALERT GENERATED! Level 10 (CRITICAL)
       └─ Written to /var/ossec/logs/alerts/alerts.json
       ↓
T+8s   Filebeat picks up alert from alerts.json
       ↓
T+9s   Alert sent to Elasticsearch
       ↓
T+10s  Alert indexed and queryable
       ↓
T+11s  VISIBLE in Wazuh Dashboard! 🎉
```

---

## 🧪 Multi-Attack Scenario

### Scenario: 3 SQLi + 2 XSS + 5 Brute Force attempts

**What You'd See in Nginx Log**:
```
127.0.0.1 - - [25/Apr/2026:05:07:00] "GET /vulnerabilities/sqli/?id=admin%27%20OR%20%271%27%3D%271" 200
127.0.0.1 - - [25/Apr/2026:05:07:03] "GET /vulnerabilities/sqli/?id=1%27%20UNION%20SELECT%20user%28%29" 200
127.0.0.1 - - [25/Apr/2026:05:07:06] "GET /vulnerabilities/xss_reflected/?name=%3Cscript%3Ealert" 200
127.0.0.1 - - [25/Apr/2026:05:07:09] "GET /vulnerabilities/xss_reflected/?name=%3Cimg%20onerror" 200
127.0.0.1 - - [25/Apr/2026:05:07:12] "POST /vulnerabilities/brute/ HTTP/1.1" 401
127.0.0.1 - - [25/Apr/2026:05:07:14] "POST /vulnerabilities/brute/ HTTP/1.1" 401
```

**What You'd See in Wazuh Manager Log**:
```
2026-04-25 05:07:01 wazuh-analysisd: INFO: Generated alert: (Rule: 100100) SQL Injection Attack
2026-04-25 05:07:04 wazuh-analysisd: INFO: Generated alert: (Rule: 100100) SQL Injection Attack
2026-04-25 05:07:07 wazuh-analysisd: INFO: Generated alert: (Rule: 100200) XSS Attack Detected
2026-04-25 05:07:10 wazuh-analysisd: INFO: Generated alert: (Rule: 100200) XSS Attack Detected
2026-04-25 05:07:13 wazuh-analysisd: INFO: Generated alert: (Rule: 100300) Brute Force Attempt
```

**What You'd See in Dashboard**:
```
Alert Count by Type:
├─ SQL Injection: 3 alerts (Rule 100100)
├─ XSS: 2 alerts (Rule 100200)
└─ Brute Force: 5 alerts (Rule 100300)

Attack Timeline:
├─ 05:07:00 - SQLi (Severity: 10)
├─ 05:07:03 - SQLi (Severity: 10)
├─ 05:07:06 - XSS (Severity: 9)
├─ 05:07:09 - XSS (Severity: 9)
└─ 05:07:12-20 - Multiple Brute Force (Severity: 7-8)

Summary:
- Source IP: 127.0.0.1
- Total Alerts: 10
- Duration: 20 seconds
- Attack Pattern: Multi-vector attack detected
```

---

## 🎓 How to Interpret Different Severity Levels

### Severity Level Mapping

| Level | Severity | What It Means | Example |
|-------|----------|--------------|---------|
| 1-3 | LOW | Informational, not urgent | Failed login, policy violation |
| 4-6 | MEDIUM | Should investigate | Suspicious pattern, multiple attempts |
| 7-8 | HIGH | Investigate within 30 min | Brute force, unclear malicious activity |
| 9 | VERY HIGH | Immediate investigation | Confirmed attack signature match |
| 10 | CRITICAL | Immediate action required | SQL Injection, RCE, data exfiltration |

### Rule ID Reference

| Rule ID | Attack Type | Severity | Description |
|---------|-------------|----------|-------------|
| 100100 | SQL Injection | 10 | Detects SQL metacharacters |
| 100200 | XSS | 9 | Detects script tags & event handlers |
| 100300 | Brute Force | 8 | Multiple failed auth attempts |
| 100400 | File Upload | 9-10 | Suspicious file extensions uploaded |
| 100500 | Directory Traversal | 9 | Path traversal attempts detected |

---

## 💻 Quick Copy-Paste Commands

### Run 5 Different SQL Injection Payloads
```powershell
$payloads = @(
    "admin' OR '1'='1",
    "1' UNION SELECT user(),database() --",
    "1' AND 1=2 UNION SELECT user(),database(),database() --",
    "' OR 'a'='a",
    "1 OR 1=1 --"
)

foreach ($payload in $payloads) {
    $encoded = [System.Web.HttpUtility]::UrlEncode($payload)
    Invoke-WebRequest "http://localhost:8080/vulnerabilities/sqli/?id=$encoded" -UseBasicParsing -ErrorAction SilentlyContinue | Out-Null
    Write-Host "✅ Executed: $payload"
    Start-Sleep -Seconds 2
}
```

### Monitor All 3 Key Logs Simultaneously
**Terminal 1**:
```bash
docker compose logs -f nginx
```

**Terminal 2**:
```bash
docker compose logs -f wazuh-manager
```

**Terminal 3**:
```bash
# Ready to execute attacks
```

### View Final Alert Count
```bash
docker compose exec wazuh-manager bash -c "wc -l /var/ossec/logs/alerts/alerts.json"
```

---

## 📋 Checklist: Verifying Attack Detection Works

After running attack, verify:

- [ ] HTTP request appears in Nginx logs
  ```bash
  docker compose logs nginx | grep getaway
  ```

- [ ] Wazuh processes the log
  ```bash
  docker compose logs wazuh-manager | grep "Generated alert"
  ```

- [ ] Alert is written to alerts.json
  ```bash
  docker compose exec wazuh-manager tail -5 /var/ossec/logs/alerts/alerts.json
  ```

- [ ] Filebeat successfully sends data
  ```bash
  docker compose logs filebeat | grep "Sent event"
  ```

- [ ] Dashboard has the alert (when ready)
  - Open: http://localhost:5601
  - Go to: Security Events
  - Should see alert with same timestamp

---

## 🚨 If Logs Are Missing Attacks

### Troubleshooting Steps

1. **Check Nginx received the request**:
   ```bash
   docker compose logs nginx --tail 20
   ```

2. **Check Wazuh Manager is running**:
   ```bash
   docker compose exec wazuh-manager ps aux | grep wazuh
   # Should see multiple wazuh processes
   ```

3. **Manually verify alert file exists**:
   ```bash
   docker compose exec wazuh-manager ls -lh /var/ossec/logs/alerts/
   # Should see alerts.json with recent timestamp
   ```

4. **Check Filebeat connectivity**:
   ```bash
   docker compose logs filebeat | grep "ERROR\|connection"
   ```

5. **Force Wazuh to reload alerts**:
   ```bash
   docker compose exec wazuh-manager /var/ossec/bin/wazuh-control restart
   ```

---

## 🎯 Common Issues & Solutions

### Issue: Alerts Not Appearing in Dashboard

**Cause**: Elasticsearch/Indexer not fully initialized yet

**Solution**:
```bash
# Wait 5-10 minutes and try again
# OR restart the dashboard
docker compose restart wazuh-dashboard
```

### Issue: Nginx Not Logging Attacks

**Cause**: Log file not accessible or permissions issue

**Solution**:
```bash
# Check nginx log location
docker compose exec nginx ls -lh /var/log/nginx/

# Re-enable logging
docker compose restart nginx
```

### Issue: Wazuh Manager Can't Connect to Indexer

**Cause**: Indexer not ready, network issue

**Solution**:
```bash
# Check indexer status
docker compose logs wazuh-indexer | tail 20

# Restart manager
docker compose restart wazuh-manager
```

---

## 📊 The Complete SOC Workflow

```
1. Attacker sends malicious HTTP request
          ↓
2. Web server (DVWA) processes request
          ↓
3. Nginx reverse proxy logs the request
          ↓
4. Filebeat reads log file
          ↓
5. Log sent to Wazuh Manager (SIEM)
          ↓
6. Wazuh analyzes log against detection rules
          ↓
7. Rule matches! Alert generated
          ↓
8. Alert stored in JSON format
          ↓
9. Alert indexed to Elasticsearch
          ↓
10. Security analyst views alert in Dashboard
           ↓
11. Analyst investigates and responds
```

**You've just implemented a complete Security Operations Center! 🛡️**

---

**Next Steps**: 
1. Run the PowerShell attack script: `.\attack-windows.ps1`
2. Watch all 3 logs in parallel
3. See alerts appear in Dashboard
4. Analyze the patterns and correlations

**Happy hunting! 🔍**
