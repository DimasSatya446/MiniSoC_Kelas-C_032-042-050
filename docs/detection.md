# Detection Rules & Strategy - Mini SOC

Dokumentasi lengkap tentang strategi deteksi, rules yang digunakan, dan cara mengoptimalkannya.

## 1. Detection Strategy Overview

### Detection Methodology

```
┌──────────────────────────────────────────────────────┐
│ Log Input (from Nginx)                              │
├──────────────────────────────────────────────────────┤
│ Example: GET /vulnerabilities/sqli/?id=admin'OR'1... │
└────────────┬─────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────┐
│ Rule Matching Engine                                │
├──────────────────────────────────────────────────────┤
│ Check against each rule in custom_rules.xml         │
└────────────┬─────────────────────────────────────────┘
             │
             ▼
        ┌─────────────────┐
        │ Pattern Match?  │
        └─────────────────┘
          ├─ NO  → No alert
          │
          └─ YES ▼
            ┌──────────────────────────────┐
            │ Extract Context              │
            │ - Source IP                  │
            │ - Timestamp                  │
            │ - Full request               │
            │ - Response code              │
            └────────────┬─────────────────┘
                         │
                         ▼
            ┌──────────────────────────────┐
            │ Assign Severity (7-10)       │
            │ - Based on rule level        │
            └────────────┬─────────────────┘
                         │
                         ▼
            ┌──────────────────────────────┐
            │ Create Alert Event           │
            │ - Rule ID, Description       │
            │ - Full log context           │
            └────────────┬─────────────────┘
                         │
                         ▼
            ┌──────────────────────────────┐
            │ Send to Indexer              │
            │ (Elasticsearch/OpenSearch)   │
            └────────────┬─────────────────┘
                         │
                         ▼
            ┌──────────────────────────────┐
            │ Dashboard Alert Appears      │
            │ - Analyst sees alert         │
            │ - Can drill down for details │
            └──────────────────────────────┘
```

## 2. Detection Rules

Semua rules didefinisikan dalam `wazuh/rules/custom_rules.xml`

### Rule Structure

```xml
<rule id="100100" level="10">
  <decoded_as>web-accesslog</decoded_as>
  <match>UNION|SELECT|union|select</match>
  <description>Possible SQL Injection attempt on DVWA</description>
</rule>
```

#### Rule Attributes

| Attribute | Example | Description |
|-----------|---------|-------------|
| `id` | 100100 | Unique rule identifier |
| `level` | 10 | Severity (0-15, 7+ triggers alert) |
| `decoded_as` | web-accesslog | Log type decoder |
| `match` | UNION\|SELECT | Pattern regex to match |
| `description` | Possible SQL Injection | Alert message |

### Rule Severity Levels

| Level | Classification | Action |
|-------|-----------------|--------|
| 7 | Medium | Document & investigate |
| 8 | Medium-High | Escalate to team |
| 9 | High | Immediate action required |
| 10 | Critical | Block, investigate, incident report |

---

## 3. Custom Rules - Detailed Analysis

### Rule 100100: SQL Injection Detection

**Rule Definition:**
```xml
<rule id="100100" level="10">
  <decoded_as>web-accesslog</decoded_as>
  <match>UNION|SELECT|union|select</match>
  <description>Possible SQL Injection attempt on DVWA</description>
</rule>
```

**Detection Method:** Pattern Matching

**Keywords Detected:**
- `UNION` - UNION-based SQLi
- `SELECT` - Query manipulation
- `union` - Case-insensitive variant
- `select` - Case-insensitive variant

**Example Matching Payloads:**
```
1' UNION SELECT user(),database() --
admin' OR '1'='1' SELECT * FROM users --
'); DROP TABLE users; SELECT * FROM (('1
```

**Log Examples:**
```
127.0.0.1 - - [25/Apr/2026:10:30:45 +0000] "GET /vulnerabilities/sqli/?id=1%20UNION%20SELECT%20user() HTTP/1.1" 200
127.0.0.1 - - [25/Apr/2026:10:30:46 +0000] "GET /vulnerabilities/sqli/?id=admin%27%20OR%20%271%27%3D%271%20SELECT HTTP/1.1" 200
```

**Alert Generated:**
```json
{
  "rule": {
    "id": "100100",
    "level": 10,
    "description": "Possible SQL Injection attempt on DVWA",
    "groups": ["webapp", "dvwa", "attack"]
  },
  "agent": {
    "name": "dvwa",
    "id": "000"
  },
  "manager": {
    "name": "wazuh-manager"
  },
  "id": "1234567890.123456",
  "timestamp": "2026-04-25T10:30:45+0000",
  "source": {
    "ip": "127.0.0.1",
    "port": 12345
  },
  "http": {
    "request": {
      "method": "GET",
      "path": "/vulnerabilities/sqli/?id=1%20UNION%20SELECT%20user()",
      "code": "200"
    }
  },
  "full_log": "127.0.0.1 - - [25/Apr/2026:10:30:45 +0000] \"GET /vulnerabilities/sqli/?id=1%20UNION%20SELECT%20user() HTTP/1.1\" 200 ..."
}
```

---

### Rule 100101: Cross-Site Scripting (XSS) Detection

**Rule Definition:**
```xml
<rule id="100101" level="10">
  <decoded_as>web-accesslog</decoded_as>
  <match>&lt;script&gt;|%3Cscript%3E</match>
  <description>Possible XSS attempt on DVWA</description>
</rule>
```

**Detection Method:** Pattern Matching (HTML entities)

**Keywords Detected:**
- `<script>` - Script tag (decoded)
- `%3Cscript%3E` - URL-encoded script tag
- HTML entities: `&lt;`, `&gt;`

**Example Matching Payloads:**
```
<script>alert('XSS')</script>
%3Cscript%3Ealert('XSS')%3C/script%3E
<img src=x onerror="alert('XSS')">
javascript:alert('XSS')
```

**Log Examples:**
```
127.0.0.1 - - [25/Apr/2026:10:30:50 +0000] "GET /vulnerabilities/xss_reflected/?name=%3Cscript%3Ealert%28%27XSS%27%29%3C%2Fscript%3E HTTP/1.1" 200
127.0.0.1 - - [25/Apr/2026:10:30:51 +0000] "GET /vulnerabilities/xss_reflected/?name=<script>alert HTTP/1.1" 200
```

**Alert Characteristics:**
- Severity: CRITICAL (Level 10)
- Immediate escalation required
- May affect other users if stored XSS

---

### Rule 100102: Suspicious PHP File Access/Upload

**Rule Definition:**
```xml
<rule id="100102" level="7">
  <decoded_as>web-accesslog</decoded_as>
  <match>.php</match>
  <description>Possible suspicious PHP file upload/access attempt</description>
</rule>
```

**Detection Method:** File Extension Pattern Matching

**Keywords Detected:**
- `.php` - PHP file extension
- `.php5`, `.phtml`, `.phar` - PHP variants

**Example Matching Scenarios:**
```
POST /vulnerabilities/upload/ (upload shell.php)
GET /uploads/shell.php?cmd=whoami
GET /vulnerabilities/upload/shell.php
GET /files/backdoor.php
```

**Log Examples:**
```
127.0.0.1 - - [25/Apr/2026:10:31:10 +0000] "POST /vulnerabilities/upload/ HTTP/1.1" 200 [Content includes: shell.php]
127.0.0.1 - - [25/Apr/2026:10:31:12 +0000] "GET /uploads/shell.php?cmd=whoami HTTP/1.1" 200
```

**Alert Characteristics:**
- Severity: MEDIUM (Level 7)
- Might be false positive (legitimate .php access)
- Should be context-based

---

## 4. Rule Optimization & Tuning

### Issue: False Positives

**Problem:** Legitimate PHP file access triggers alerts

**Solution 1: Add Exception Rules**
```xml
<!-- Whitelist legitimate PHP files -->
<rule id="100103" level="0">
  <if_sid>100102</if_sid>
  <match>.php</match>
  <url>/index.php|/login.php|/dashboard.php</url>
  <description>Legitimate PHP access - whitelisted</description>
</rule>
```

**Solution 2: Context-Based Rules**
```xml
<rule id="100104" level="10">
  <if_sid>100102</if_sid>
  <match>.php</match>
  <!-- Only alert if response code is 200 (successful upload/execution) -->
  <status>200</status>
  <description>Successful PHP file upload/access - CRITICAL</description>
</rule>
```

### Issue: Evasion Techniques

**Problem:** Attacker uses encoding/obfuscation

**Solution: Enhanced Pattern Matching**
```xml
<!-- Detect double-encoded SQL injection -->
<rule id="100105" level="10">
  <decoded_as>web-accesslog</decoded_as>
  <match>%25\d{2}|&#x[0-9a-fA-F]{2}</match>
  <description>Possible encoded SQL Injection attempt</description>
</rule>

<!-- Detect case variations -->
<rule id="100106" level="10">
  <decoded_as>web-accesslog</decoded_as>
  <match>(?i)union.*select|select.*from.*where</match>
  <description>Possible SQL Injection (case-insensitive)</description>
</rule>
```

---

## 5. Advanced Detection Techniques

### Frequency-Based Detection (Brute Force)

```xml
<!-- Detect multiple failed login attempts -->
<rule id="100200" level="7">
  <decoded_as>web-accesslog</decoded_as>
  <match>/vulnerabilities/brute/</match>
  <status>401|403</status>
  <frequency>5 in 5m</frequency>
  <timeframe>300</timeframe>
  <description>Possible brute force attack detected</description>
</rule>
```

**How it works:**
- Watches for 5 failed login attempts (401/403)
- Within 5-minute window
- From same source IP
- Triggers alert on 5th failure

### Threshold-Based Detection

```xml
<!-- Alert on excessive request volume -->
<rule id="100201" level="8">
  <decoded_as>web-accesslog</decoded_as>
  <frequency>50 in 1m</frequency>
  <timeframe>60</timeframe>
  <description>Possible DoS/scanning activity detected</description>
</rule>
```

### Composite Rules (Rule Chains)

```xml
<!-- Detect attack pattern: SQLi followed by data exfiltration -->
<rule id="100300" level="10">
  <if_sid>100100</if_sid>
  <same_source_ip>yes</same_source_ip>
  <timeframe>10</timeframe>
  <match>SELECT|UNION</match>
  <description>SQLi followed by data extraction attempt</description>
</rule>
```

---

## 6. Rule Deployment & Testing

### Adding New Rules

1. **Edit custom_rules.xml:**
```bash
cd wazuh/rules/
nano custom_rules.xml
```

2. **Add new rule:**
```xml
<rule id="100400" level="10">
  <decoded_as>web-accesslog</decoded_as>
  <match>new_pattern_here</match>
  <description>New attack detection</description>
</rule>
```

3. **Restart Wazuh:**
```bash
docker-compose restart wazuh-manager
```

### Testing Rules

**Method 1: Direct Log Injection**
```bash
# Send test log to Wazuh
docker-compose exec wazuh-manager bash
echo '127.0.0.1 - - [25/Apr/2026:10:30:45 +0000] "GET /vulnerabilities/sqli/?id=1 UNION SELECT user() HTTP/1.1" 200' | \
  /var/ossec/bin/wazuh-control rule-test
```

**Method 2: Simulate Attack**
```bash
# Execute actual attack and verify alert appears in dashboard
curl "http://localhost:8080/vulnerabilities/sqli/?id=1 UNION SELECT user()"
# Wait 30 seconds for log processing
# Check Wazuh Dashboard for alert
```

---

## 7. Dashboard Alert Analysis

### Alert Drill-Down

In Wazuh Dashboard:

1. **Security Events** → View all alerts
2. **Filter by Rule ID** → 100100, 100101, 100102
3. **Drill-down** → See full request context
4. **Timeline** → See attack pattern over time

### Key Metrics to Monitor

| Metric | Threshold | Action |
|--------|-----------|--------|
| SQLi attempts | > 5/hour | Investigate source |
| XSS attempts | > 3/hour | Block IP |
| Failed logins | > 10/hour | Account lockout |
| PHP uploads | > 1 | Immediate investigation |

### Creating Custom Dashboards

**SQLi Monitoring:**
- Count of SQLi alerts per day
- Top source IPs with SQLi attempts
- Target endpoints (most attacked)
- Success/failure ratio

**XSS Monitoring:**
- XSS alert frequency
- Payload patterns
- User agents of attackers
- Geographic distribution

---

## 8. Rules.xml Reference

Current rules in `wazuh/rules/custom_rules.xml`:

```xml
<group name="webapp,dvwa,attack,">

  <!-- Rule 100100: SQL Injection Detection -->
  <rule id="100100" level="10">
    <decoded_as>web-accesslog</decoded_as>
    <match>UNION|SELECT|union|select</match>
    <description>Possible SQL Injection attempt on DVWA</description>
  </rule>

  <!-- Rule 100101: XSS Detection -->
  <rule id="100101" level="10">
    <decoded_as>web-accesslog</decoded_as>
    <match>&lt;script&gt;|%3Cscript%3E</match>
    <description>Possible XSS attempt on DVWA</description>
  </rule>

  <!-- Rule 100102: PHP File Access/Upload -->
  <rule id="100102" level="7">
    <decoded_as>web-accesslog</decoded_as>
    <match>.php</match>
    <description>Possible suspicious PHP file upload/access attempt</description>
  </rule>

</group>
```

---

## 9. Troubleshooting Detection

### Rules Not Triggering

**Check 1: Verify rule syntax**
```bash
docker-compose exec wazuh-manager wazuh-control info
```

**Check 2: Test rule manually**
```bash
docker-compose logs wazuh-manager | grep "custom_rules"
```

**Check 3: Enable debug mode**
```bash
docker-compose exec wazuh-manager bash
echo "debug" > /var/ossec/etc/local_internal_options.conf
/var/ossec/bin/wazuh-control restart
```

### Too Many False Positives

**Increase specificity:**
```xml
<!-- Before: Too broad -->
<match>select</match>

<!-- After: More specific -->
<match>select.*from|union.*select</match>
```

**Add context:**
```xml
<rule id="100100" level="10">
  <decoded_as>web-accesslog</decoded_as>
  <match>UNION|SELECT|union|select</match>
  <status>200</status>  <!-- Only 200 OK responses -->
  <url>/vulnerabilities/sqli</url>  <!-- Only specific endpoint -->
  <description>Possible SQL Injection attempt on DVWA</description>
</rule>
```

---

## References

- [Wazuh Rule Documentation](https://documentation.wazuh.com/current/user-manual/ruleset/rules-group.html)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
- [MITRE ATT&CK](https://attack.mitre.org/)

**Last Updated**: 2026-04-25
