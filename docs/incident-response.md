# Incident Response & Analysis - Mini SOC

Dokumentasi lengkap tentang proses analisis alert dan respons insiden setelah deteksi di Wazuh dashboard.

## 1. Incident Response Workflow

```
┌─────────────────────────────────────────────────┐
│ 1. ALERT NOTIFICATION                          │
│    - Alert muncul di Wazuh Dashboard            │
│    - Email notification (jika dikonfigurasi)    │
│    - Severity level displayed                   │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│ 2. ALERT TRIAGE & ANALYSIS                      │
│    - Determine if alert is true positive        │
│    - Assess severity and impact                 │
│    - Check for similar incidents                │
│    - Identify attack source and target          │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│ 3. INCIDENT INVESTIGATION                       │
│    - Gather additional context                  │
│    - Timeline construction                      │
│    - Evidence collection                        │
│    - Pattern analysis                           │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│ 4. INCIDENT CLASSIFICATION & SEVERITY           │
│    - Assign incident ID                         │
│    - Classify attack type                       │
│    - Determine business impact                  │
│    - Set priority level                         │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│ 5. RESPONSE ACTION                              │
│    - Execute immediate containment              │
│    - Block malicious IP (optional)              │
│    - Preserve evidence for forensics            │
│    - Notify relevant teams                      │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│ 6. DOCUMENTATION & REMEDIATION                  │
│    - Document all findings                      │
│    - Recommend security improvements            │
│    - Create incident report                     │
│    - Update security baseline                   │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│ 7. POST-INCIDENT REVIEW                         │
│    - Conduct lessons learned                    │
│    - Update detection rules if needed           │
│    - Improve response procedures                │
└─────────────────────────────────────────────────┘
```

## 2. Alert Analysis Framework

### Information to Gather

When an alert appears in Wazuh Dashboard, immediately gather:

```json
{
  "Alert_ID": "INC-2026-04-25-001",
  "Detection_Time": "2026-04-25T10:30:45+0000",
  
  "Attack_Details": {
    "Rule_ID": "100100",
    "Rule_Name": "Possible SQL Injection attempt on DVWA",
    "Severity": 10,
    "Attack_Type": "SQL Injection"
  },
  
  "Source_Information": {
    "Source_IP": "127.0.0.1",
    "Source_Port": "12345",
    "User_Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    "Geographic_Location": "Local"
  },
  
  "Target_Information": {
    "Target_URL": "http://localhost:8080/vulnerabilities/sqli/",
    "Target_Endpoint": "/vulnerabilities/sqli/",
    "HTTP_Method": "GET",
    "Query_Parameters": "id=admin' OR '1'='1",
    "Response_Code": 200,
    "Response_Size": "1234 bytes"
  },
  
  "Attack_Payload": {
    "Full_Payload": "admin' OR '1'='1",
    "Injected_Keyword": "OR",
    "Payload_Type": "Authentication Bypass"
  },
  
  "Context": {
    "Timestamp": "2026-04-25T10:30:45+0000",
    "Alert_Count_Today": 3,
    "Similar_Alerts": "2 in last hour",
    "Database_Response": "Multiple records returned (unauthorized)"
  }
}
```

---

## 3. Attack-Specific Analysis

### 3.1 SQL Injection Incident

**Alert Indicators:**
- Rule ID: 100100
- Severity: CRITICAL (10)
- Pattern: UNION, SELECT keywords in URL

**Analysis Steps:**

**Step 1: Confirm Exploitation**
```
Review SQL query:
- Was unauthorized data accessed?
- Were sensitive fields queried?
- Did query modify data (INSERT/UPDATE/DELETE)?

Check Response:
- Response code 200 = likely successful
- Large response size = data extracted
- Error messages = information disclosure
```

**Step 2: Assess Impact**
```
Questions to ask:
- What data was accessed?
- How many records were retrieved?
- Were credentials or PII exposed?
- Can the attack be reproduced?
```

**Step 3: Identify Attack Pattern**
```
Classification:
- Authentication Bypass: Bypassed login check
- Data Extraction: Extracted sensitive info
- Data Modification: Altered database content
- Privilege Escalation: Gained admin access
```

**Example Analysis:**

```
Alert: SQLi on /vulnerabilities/sqli/
Source: 127.0.0.1
Payload: admin' OR '1'='1'

Analysis:
✓ This is classic authentication bypass
✓ Payload breaks SQL logic with OR '1'='1'
✓ Response shows user successfully bypassed auth
✓ Attack appears to be reconnaissance/testing
✓ No evidence of data exfiltration yet

Severity Assessment:
- Immediate Risk: MEDIUM (auth bypass possible)
- Potential Risk: HIGH (data extraction possible)
- Overall Incident: MEDIUM-HIGH
```

### 3.2 XSS Incident

**Alert Indicators:**
- Rule ID: 100101
- Severity: CRITICAL (10)
- Pattern: <script> or %3Cscript%3E in URL

**Analysis Steps:**

**Step 1: Determine XSS Type**
```
Reflected XSS:
- Payload in URL parameter
- Appears in HTTP response
- Requires attacker to send victim the link

Stored XSS:
- Payload stored in database
- Displayed to all users viewing that page
- More dangerous (affects multiple users)
```

**Step 2: Check Payload Context**
```
Is payload:
- In reflected parameter? (user input)
- In form field? (stored)
- In comment section? (stored)
- In custom header? (reflects immediately)
```

**Step 3: Assess Attack Capability**
```
What can attacker do?
- Steal session cookies?
- Perform actions as victim?
- Redirect to phishing page?
- Inject malware?
```

**Example Analysis:**

```
Alert: XSS on /vulnerabilities/xss_reflected/
Source: 127.0.0.1
Payload: <script>alert('XSS')</script>

Analysis:
✓ Reflected XSS (in URL parameter)
✓ Payload successfully executed in response
✓ Could steal victim's session cookie
✓ Attack appears to be proof-of-concept
✓ Multiple payloads detected (same session)

Severity Assessment:
- Technical Risk: CRITICAL (script execution)
- Business Risk: MEDIUM (attack requires user click)
- Overall Incident: HIGH
```

### 3.3 File Upload Incident

**Alert Indicators:**
- Rule ID: 100102
- Severity: MEDIUM (7)
- Pattern: .php extension in POST request

**Analysis Steps:**

**Step 1: Determine Upload Location**
```
Where was file uploaded?
- Web-accessible directory? (executable)
- Restricted directory? (less dangerous)
- Outside web root? (safe)
```

**Step 2: Check File Type Restrictions**
```
Are restrictions in place?
- File extension validation?
- MIME type validation?
- File signature (magic bytes) check?
- Size restrictions?
```

**Step 3: Assess Damage Potential**
```
Can attacker:
- Execute arbitrary code?
- Access sensitive files?
- Modify application files?
- DoS the application?
```

**Example Analysis:**

```
Alert: PHP file upload attempt
Source: 127.0.0.1
File: shell.php (size: 1245 bytes)

Analysis:
✓ POST to /vulnerabilities/upload/
✓ File extension not validated
✓ File successfully uploaded (HTTP 200)
✓ File accessible at /uploads/shell.php
✓ PHP execution enabled in upload dir

Severity Assessment:
- Technical Risk: CRITICAL (RCE possible)
- Attack Status: SUCCESSFUL (shell uploaded)
- Exploitability: IMMEDIATE
- Overall Incident: CRITICAL
```

---

## 4. Incident Classification & Severity Matrix

### Severity Levels

| Level | Criteria | Response Time | Example |
|-------|----------|----------------|---------|
| **CRITICAL** | RCE, data breach, multiple systems affected | < 15 min | Active PHP upload, SQLi with admin account |
| **HIGH** | Potential system compromise, auth bypass | < 30 min | XSS on sensitive page, brute force admin |
| **MEDIUM** | Limited impact, isolated incident | < 2 hours | SQLi on non-critical field, failed upload |
| **LOW** | No immediate threat, informational | < 24 hours | Scanning activity, weak authentication test |

### Incident Classification

```
By Attack Type:
├─ Web Application Attack (SQLi, XSS, CSRF)
├─ Brute Force (Login, API)
├─ File Upload/Execution
├─ Information Disclosure
├─ Denial of Service
└─ Others

By Source:
├─ External (internet)
├─ Internal (network)
├─ Local (system)

By Status:
├─ Reconnaissance (probing)
├─ Attempted (failed)
├─ Successful (exploitation achieved)
└─ Post-exploitation (impact phase)
```

---

## 5. Response Actions

### 5.1 Immediate Containment

**Action 1: Alert Team**
```
Notify:
- Security Operations Center (SOC)
- Incident Commander
- System owners
- Management (if critical)

Medium:
- Slack/Teams alert
- Email notification
- Phone call (if critical)
```

**Action 2: Preserve Evidence**
```bash
# Download relevant logs
docker-compose exec wazuh-indexer curl -u admin:SecurePassword123! \
  "https://localhost:9200/wazuh-alerts-*/_search?q=rule_id:100100" \
  -k > evidence_sqli_attack.json

# Screenshot alert
# Save full request/response data
# Archive log files
```

**Action 3: Isolate Attack Source (Optional)**
```bash
# Add to Nginx blocklist
echo "127.0.0.1" >> nginx/blocked_ips.conf
docker-compose reload nginx

# Or update firewall rules
sudo ufw block 127.0.0.1
```

**Action 4: Patch Application**
```bash
# For SQLi: Update code to use prepared statements
# For XSS: Add input sanitization
# For Upload: Validate file types & extensions
# Apply changes and test
```

### 5.2 Post-Incident Actions

**Action 1: Conduct Full Investigation**
```
Timeline Construction:
- When did attack start? (First alert)
- How long did it continue? (Last alert)
- How many attempts? (Alert count)
- Attack evolution (escalation or reconnaissance)

Evidence Analysis:
- Full request body
- Response details
- Database queries executed
- Any successful commands
```

**Action 2: Create Incident Report**
```
Report Template:
├─ Incident ID & Date
├─ Executive Summary
├─ Attack Timeline
├─ Attack Details
│  ├─ Type of attack
│  ├─ Source IP
│  ├─ Target endpoint
│  └─ Payload used
├─ Impact Assessment
│  ├─ Data accessed/modified
│  ├─ Systems affected
│  └─ Business impact
├─ Response Actions Taken
├─ Root Cause Analysis
├─ Recommendations
└─ Lessons Learned
```

**Action 3: Recommend Remediation**
```
For SQL Injection:
- Use parameterized queries / prepared statements
- Input validation with whitelist approach
- WAF rules for SQLi patterns
- Database user with minimal privileges
- Regular security testing

For XSS:
- Output encoding
- Content Security Policy (CSP) headers
- Input sanitization
- HttpOnly flag on cookies
- Secure flag on cookies

For File Upload:
- Whitelist allowed extensions
- Validate MIME types
- Store uploads outside web root
- Disable script execution in upload dir
- Rename uploaded files
```

---

## 6. Response Playbooks

### Playbook 1: SQL Injection Response

```yaml
Incident_Type: SQL Injection
Rule_ID: 100100
Severity: CRITICAL

Discovery:
  1. Alert triggered on SQL keywords (UNION, SELECT)
  2. Check: Is this legitimate database query?
  3. Check: Is attacker extracting data?
  4. Verify: Database user privileges

Analysis:
  1. Examine full payload: id=?
  2. Determine injection point
  3. Identify exploited vulnerability
  4. Check database for unauthorized access

Response:
  1. [ ] Block source IP for 24 hours
  2. [ ] Review database access logs
  3. [ ] Check if data was exfiltrated
  4. [ ] Patch vulnerable code
  5. [ ] Update WAF rules
  6. [ ] Test patches
  7. [ ] Document incident

Recovery:
  1. Monitor for similar attacks
  2. Increase logging verbosity
  3. Deploy IDS signatures
  4. Train developers on secure coding
  5. Schedule security review

Communicate:
  - [ ] Notify management
  - [ ] Send incident report
  - [ ] Update security dashboard
```

### Playbook 2: XSS Response

```yaml
Incident_Type: Cross-Site Scripting
Rule_ID: 100101
Severity: CRITICAL

Discovery:
  1. Alert on <script> or %3Cscript%3E tags
  2. Determine XSS type (reflected vs stored)
  3. Identify affected users
  4. Check if session cookies compromised

Analysis:
  1. Extract payload: <script>?</script>
  2. Analyze malicious JavaScript
  3. Check if attacker accessed sensitive data
  4. Review user actions after attack

Response:
  1. [ ] If stored XSS: Remove payload from database
  2. [ ] If reflected: Add to Web Application Firewall
  3. [ ] Review user sessions for compromise
  4. [ ] Force password reset if needed
  5. [ ] Patch output encoding
  6. [ ] Implement CSP headers

Recovery:
  1. Monitor for session hijacking
  2. Alert affected users
  3. Review access logs for unauthorized actions
  4. Update security policies

Communicate:
  - [ ] Notify affected users
  - [ ] Incident report to management
  - [ ] Security update to team
```

### Playbook 3: Brute Force Response

```yaml
Incident_Type: Brute Force Attack
Rule_ID: 100200 (custom, if configured)
Severity: HIGH

Discovery:
  1. Multiple failed login attempts detected
  2. From same source IP
  3. Target: login endpoint

Analysis:
  1. Count failed attempts
  2. Identify target account
  3. Determine if any accounts compromised
  4. Check if MFA blocked attack

Response:
  1. [ ] Block source IP
  2. [ ] Temporarily lock target account
  3. [ ] Review login logs
  4. [ ] Check for successful login from that IP
  5. [ ] Implement rate limiting
  6. [ ] Enforce MFA

Recovery:
  1. Unlock account after verification
  2. Force password reset
  3. Monitor for account usage
  4. Review privileges

Communicate:
  - [ ] Notify account owner
  - [ ] Security team update
```

---

## 7. Incident Report Template

```markdown
# INCIDENT REPORT

## Header Information
- **Incident ID**: INC-2026-04-25-001
- **Report Date**: 2026-04-25
- **Report Author**: SOC Analyst
- **Severity**: CRITICAL / HIGH / MEDIUM / LOW
- **Status**: OPEN / INVESTIGATING / RESOLVED

## Executive Summary
Brief 2-3 sentence summary of incident

## Attack Timeline
```
10:30:45 - Alert triggered (SQL Injection detected)
10:30:46 - Analyst acknowledged alert
10:30:50 - Investigation started
10:31:00 - Attack contained (IP blocked)
10:35:00 - Root cause identified
```

## Attack Details

### Attack Information
- **Attack Type**: SQL Injection
- **Rule ID**: 100100
- **Source IP**: 127.0.0.1
- **Target URL**: http://localhost:8080/vulnerabilities/sqli/
- **Payload**: admin' OR '1'='1'
- **Attack Vector**: HTTP GET parameter

### Affected Systems
- DVWA (Vulnerable demo app)
- Database (potential data access)

## Analysis

### Technical Analysis
1. Attack mechanism explained
2. Vulnerability details
3. Impact assessment

### Impact Assessment
- **Data Compromised**: None / Potential / Confirmed
- **Systems Affected**: DVWA only
- **User Impact**: None / Limited / Widespread
- **Business Impact**: Low / Medium / High

## Response Actions Taken
1. [ ] Alert sent to SOC
2. [ ] Source IP blocked
3. [ ] Attacker identified
4. [ ] Logs preserved
5. [ ] Code patched
6. [ ] Testing completed

## Recommendations

### Immediate (0-24 hours)
1. Continue monitoring for similar attacks
2. Verify patch effectiveness

### Short-term (1-7 days)
1. Security awareness training
2. Update WAF rules

### Long-term (30+ days)
1. Regular penetration testing
2. Code review process
3. Security architecture review

## Lessons Learned
- What went well
- What could be improved
- Process improvements
- Tool effectiveness

---
**Approved By**: SOC Manager
**Signature**: _______________
**Date**: 2026-04-25
```

---

## 8. Escalation Procedures

### Escalation Matrix

```
Incident Level | Decision | Escalate To | Timeline
───────────────┼──────────┼─────────────┼──────────
CRITICAL       | Block IP | CISO        | Immediate
               | Notify   | Manager     |
───────────────┼──────────┼─────────────┼──────────
HIGH           | Monitor  | SOC Lead    | 30 min
               | Alert    | Dev Team    |
───────────────┼──────────┼─────────────┼──────────
MEDIUM         | Document | SOC         | 2 hours
               | Update   | Security    |
───────────────┼──────────┼─────────────┼──────────
LOW            | Track    | Analyst     | 24 hours
               | Archive  |             |
```

---

## 9. Communication Templates

### Alert Email Template

```
Subject: SECURITY ALERT - [ATTACK_TYPE] on [DATE]

Dear Team,

A security alert has been detected on our systems:

Attack Type: SQL Injection
Severity: CRITICAL
Source IP: 127.0.0.1
Target: DVWA Application
Time: 2026-04-25 10:30:45 UTC

Action Taken:
- Source IP blocked
- Incident ID: INC-2026-04-25-001
- Investigation in progress

Please monitor your systems for any suspicious activity.

Questions? Contact: SOC Team

---
This is an automated security alert
```

---

## 10. Post-Incident Review

### Questions to Ask

1. **Detection**: How quickly was the attack detected?
2. **Response**: Was response time adequate?
3. **Investigation**: Were all facts gathered?
4. **Remediation**: Was the fix effective?
5. **Communication**: Was all stakeholders informed?
6. **Prevention**: Can this attack be prevented in future?

### Improvement Areas

- Rule tuning (reduce false positives)
- Automation (faster response)
- Process updates
- Tool enhancements
- Team training

---

**Last Updated**: 2026-04-25
