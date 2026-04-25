# Log Collection Architecture - Mini SOC

Dokumentasi lengkap tentang bagaimana log dikumpulkan dari DVWA dan berbagai sources lainnya menuju Wazuh SIEM.

## 1. Log Sources Overview

Mini SOC mengumpulkan log dari berbagai source:

| Source | Location | Format | Use Case |
|--------|----------|--------|----------|
| **Nginx Access Logs** | `/var/log/nginx/access.log` | Combined/Detailed | Web request monitoring |
| **Nginx Error Logs** | `/var/log/nginx/error.log` | Custom | Error tracking |
| **DVWA Application** | Inside container | HTTP access | Attack detection |
| **Docker Host** | Host OS | Syslog | System events |

## 2. Log Collection Flow

```
┌──────────────────────────────────────────────────────────┐
│                    LOG SOURCES                           │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  DVWA Container        →  Nginx Container               │
│  (App logs)               (access.log, error.log)       │
│                                                          │
│  Database logs         →  Host System logs              │
│  (MySQL/MariaDB)           (syslog)                     │
│                                                          │
└────────────────┬─────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────┐
│              FILEBEAT (Log Forwarder)                    │
│                                                          │
│  - Watches: /var/log/nginx/access.log                   │
│  - Parses: Log lines                                     │
│  - Enriches: Adds metadata                              │
│  - Filters: Removes noise                               │
│                                                          │
└────────────────┬─────────────────────────────────────────┘
                 │
                 ▼
        ┌────────────────┐
        │  Network (TCP) │
        │   Port 5000    │
        └────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────┐
│         WAZUH MANAGER (Log Receiver)                     │
│                                                          │
│  - Receives log events via Logstash input                │
│  - Port 5000 (Logstash pipeline)                        │
│  - Port 1514 (Wazuh agent default)                      │
│  - Rules matching engine                                │
│                                                          │
└────────────────┬─────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────┐
│       WAZUH INDEXER (Elasticsearch/OpenSearch)           │
│                                                          │
│  - Index: wazuh-alerts-*                                │
│  - Stores: Processed alerts & events                     │
│  - Provides: Search & analytics capabilities             │
│                                                          │
└────────────────┬─────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────┐
│    WAZUH DASHBOARD (Visualization & Analysis)            │
│                                                          │
│  - Displays: Real-time alerts                            │
│  - Dashboards: Attack patterns, statistics               │
│  - Drill-down: Log details per incident                  │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

## 3. Nginx Log Format

### Detailed Log Format (digunakan di project ini)

```nginx
log_format detailed '$remote_addr - $remote_user [$time_local] '
                    '"$request_method $uri $server_protocol" '
                    '$status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent" '
                    '"$http_x_forwarded_for" '
                    'rt=$request_time uct="$upstream_connect_time" '
                    'uht="$upstream_header_time" urt="$upstream_response_time"';
```

### Log Entry Example

**Raw Log:**
```
127.0.0.1 - - [25/Apr/2026:10:30:45 +0000] "GET /vulnerabilities/sqli/?id=admin%27%20OR%20%271%27%3D%271 HTTP/1.1" 200 1234 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" "-" rt=0.123 uct="0.001" uht="0.050" urt="0.120"
```

### Parsed Fields

| Field | Value | Purpose |
|-------|-------|---------|
| `remote_addr` | 127.0.0.1 | Attacker IP |
| `time_local` | 25/Apr/2026:10:30:45 +0000 | Timestamp |
| `request_method` | GET | HTTP method |
| `uri` | /vulnerabilities/sqli/?id=admin%27... | Full request path |
| `status` | 200 | HTTP response code |
| `bytes_sent` | 1234 | Response size |
| `http_user_agent` | Mozilla/5.0 | Browser/Client info |
| `request_time` | 0.123 | Request processing time |

## 4. Filebeat Configuration Details

### filebeat.yml Structure

```yaml
# 1. INPUT CONFIGURATION
filebeat.inputs:
  - type: log
    enabled: true
    paths:
      - /var/log/nginx/access.log    # Source file
    fields:
      source_type: nginx              # Metadata
      app: dvwa
    
# 2. OUTPUT CONFIGURATION
output.logstash:
    enabled: true
    hosts: ["wazuh-manager:5000"]     # Destination
    
# 3. PROCESSORS (Enrichment)
processors:
  - add_docker_metadata: ~             # Add container info
  - add_host_metadata: ~               # Add host info
```

### Log Processing Pipeline

1. **Input Phase**
   - Filebeat monitors `/var/log/nginx/access.log`
   - Reads new lines as they're written
   - Detects multiline logs

2. **Parsing Phase**
   - Splits log by newline
   - Extracts timestamp, IP, request, etc.
   - Validates log format

3. **Enrichment Phase**
   - Adds Docker container ID
   - Adds hostname
   - Adds Kubernetes metadata (if applicable)

4. **Output Phase**
   - Sends to Wazuh Manager via port 5000
   - Uses Logstash protocol
   - Includes metadata fields

## 5. Wazuh Log Reception

### Wazuh Manager Input Configuration

```xml
<!-- Logstash input for Filebeat -->
<logstash_format>true</logstash_format>
<input_type>MULTI_LINE</input_type>
```

### Log Processing in Wazuh Manager

```
┌─────────────────────────────────────────┐
│ Receive from Filebeat (Port 5000)      │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│ 1. Input Decoder                       │
│    - Parse JSON/raw format             │
│    - Extract fields                    │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│ 2. Alert Decoder                       │
│    - web-accesslog decoder             │
│    - HTTP field extraction             │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│ 3. Rule Matching                       │
│    - Load custom_rules.xml             │
│    - Check each rule                   │
│    - Pattern matching (SQLi, XSS, etc) │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│ 4. Alert Generation                    │
│    - Create alert event                │
│    - Assign severity (7-10)            │
│    - Add context data                  │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│ 5. Send to Indexer                     │
│    - HTTP to Elasticsearch             │
│    - Index: wazuh-alerts-*             │
│    - Timestamp-based indices           │
└─────────────────────────────────────────┘
```

## 6. Data Flow Example: SQLi Attack

### Request Phase
```
Attacker:  HTTP GET /vulnerabilities/sqli/?id=admin' OR '1'='1
           ↓
Nginx:     Log entry created in access.log with full payload
           "GET /vulnerabilities/sqli/?id=admin%27%20OR%20%271%27%3D%271"
```

### Log Collection Phase
```
Filebeat:  Reads new line from access.log
           Extracts: IP, method, URI, status, user_agent
           Adds metadata: docker_id, hostname
           Sends JSON to Wazuh Manager
```

### Processing Phase
```
Wazuh:     Receives JSON event
           Decodes: web-accesslog
           Checks: custom_rules.xml
           Matches: rule id=100100 (SQLi detection)
           Severity: 10 (CRITICAL)
```

### Output Phase
```
Indexer:   Stores alert with full context
           Index: wazuh-alerts-4.x.0-2026.04.25
           
Dashboard: Displays alert
           Shows: SQLi attempt, source IP, timestamp, payload
           Analyst: Reviews & responds
```

## 7. Log Volume & Performance

### Expected Log Volume
- **Per request**: ~500 bytes (average)
- **DVWA requests/hour**: 100-200 (during testing)
- **Daily volume**: ~1-5 MB
- **Storage**: 30 days = 30-150 MB (minimal)

### Wazuh Resource Usage
```
Disk Space:
  - Manager: 2-5 GB
  - Indexer: 5-10 GB (30 days retention)
  - Total: 7-15 GB

Memory:
  - Manager: 512 MB - 1 GB
  - Indexer: 512 MB - 2 GB
  - Dashboard: 256 MB - 512 MB
  - Total: 1.5-3.5 GB
```

## 8. Log Retention & Cleanup

### Wazuh Index Lifecycle

```
Index Creation: wazuh-alerts-4.x.0-2026.04.25
├─ Day 1-29: HOT index (active writes)
├─ Day 30-90: WARM index (searchable, no writes)
└─ Day 90+: DELETE (removed from storage)
```

### Manual Log Cleanup

```bash
# Remove old indices (older than 30 days)
curl -u admin:SecurePassword123! -X DELETE \
  https://localhost:9200/wazuh-alerts-4.x.0-2026.03.* \
  -k

# Reindex for optimization
curl -u admin:SecurePassword123! -X POST \
  https://localhost:9200/_reindex \
  -k
```

## 9. Troubleshooting Log Collection

### Filebeat not sending logs

```bash
# Check Filebeat status
docker-compose exec filebeat curl localhost:5066

# View Filebeat logs
docker-compose logs filebeat

# Test connection to Wazuh Manager
docker-compose exec filebeat nc -zv wazuh-manager 5000
```

### Wazuh not receiving logs

```bash
# Check Wazuh Manager Logstash input
docker-compose exec wazuh-manager cat /var/ossec/etc/ossec.conf | grep -A 10 "logstash"

# View Wazuh Manager logs
docker-compose exec wazuh-manager tail -f /var/ossec/logs/alerts/alerts.json

# Check network connectivity
docker-compose exec wazuh-manager nc -zv filebeat 5000
```

### Logs in Wazuh but no alerts

```bash
# Verify custom rules are loaded
docker-compose exec wazuh-manager cat /var/ossec/etc/rules/custom_rules.xml

# Check rule syntax
docker-compose exec wazuh-manager /var/ossec/bin/wazuh-control info

# View rule matching logs
docker-compose exec wazuh-manager grep "SQLi\|XSS" /var/ossec/logs/alerts/alerts.json
```

## 10. Security Considerations

### Log Preservation
- [ ] Enable immutable storage for logs
- [ ] Implement log rotation (7-30 days)
- [ ] Backup critical alerts to external storage
- [ ] Hash logs for integrity verification

### Access Control
- [ ] Restrict access to Wazuh Dashboard (Auth required)
- [ ] Limit API access (IP whitelist)
- [ ] Audit who accessed what logs
- [ ] Encrypt logs in transit (TLS)

### Compliance
- [ ] Log retention policy (typically 90 days)
- [ ] PII removal from logs if required
- [ ] Audit trail for log access
- [ ] Change management for rules

---

**Last Updated**: 2026-04-25
