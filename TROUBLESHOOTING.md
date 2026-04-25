# Troubleshooting Guide - Mini SOC

Panduan untuk mengatasi masalah umum yang mungkin terjadi.

## ❌ Docker Images Pull Issues

### Error: "pull access denied for wazuh/wazuh, repository does not exist"

**Penyebab:**
- Image `wazuh/wazuh` deprecated atau tidak tersedia
- Network connectivity issues
- Docker repository access denied

**Solusi:**

1. **Update docker-compose.yml** (sudah dilakukan)
   - Gunakan `wazuh/wazuh-manager-single:4.7.0`
   - Gunakan `wazuh/wazuh-indexer-single:4.7.0`
   - Gunakan `wazuh/wazuh-dashboard-single:4.7.0`

2. **Bersihkan dan retry**
   ```bash
   docker-compose down
   docker system prune -a
   docker-compose up -d
   ```

3. **Jika masih gagal, coba:**
   ```bash
   docker pull wazuh/wazuh-manager-single:4.7.0
   docker pull wazuh/wazuh-indexer-single:4.7.0
   docker pull wazuh/wazuh-dashboard-single:4.7.0
   ```

### Error: "version is obsolete"

**Solusi:**
- ✅ Sudah diperbaiki - `version` field dihapus dari docker-compose.yml

---

## ⚠️ Service Startup Issues

### Containers Keep Restarting

```bash
# Check logs
docker-compose logs wazuh-manager
docker-compose logs wazuh-indexer
```

**Jika Indexer error:**
```bash
# Indexer butuh waktu lebih lama untuk start (3-5 menit)
docker-compose logs -f wazuh-indexer
# Tunggu sampai: "cluster initialized" atau "Node started"
```

### Manager Can't Connect to Indexer

**Error:** `Elasticsearch security configuration error`

**Solusi:**
1. Ensure wazuh-indexer sudah fully started
2. Restart wazuh-manager:
   ```bash
   docker-compose restart wazuh-manager
   ```

3. Verify connection:
   ```bash
   docker-compose exec wazuh-manager curl -u admin:SecurePassword123! \
     https://wazuh-indexer:9200 -k
   ```

### Dashboard Can't Access Manager/Indexer

**Error:** `Failed to fetch from Wazuh API`

**Solusi:**
1. Verify Manager is healthy:
   ```bash
   docker-compose exec wazuh-manager curl -u wazuh:wazuh \
     https://localhost:55000/version -k
   ```

2. Verify Indexer is healthy:
   ```bash
   docker-compose exec wazuh-indexer curl -u admin:SecurePassword123! \
     https://localhost:9200 -k
   ```

3. Wait longer (first startup takes 5-10 minutes)

4. Restart Dashboard:
   ```bash
   docker-compose restart wazuh-dashboard
   ```

---

## 🔐 Authentication Issues

### Can't Login to Wazuh Dashboard

**Credentials:**
- Username: `admin`
- Password: `SecurePassword123!`

**Jika masih gagal:**
1. Verify container is running:
   ```bash
   docker-compose ps wazuh-dashboard
   ```

2. Check logs:
   ```bash
   docker-compose logs wazuh-dashboard
   ```

3. Restart and wait:
   ```bash
   docker-compose restart wazuh-dashboard
   sleep 30
   ```

4. Try again with fresh browser session (clear cache)

### Wazuh API Authentication Failed

**Command test:**
```bash
docker-compose exec wazuh-manager curl -u wazuh:wazuh \
  https://localhost:55000/version -k
```

**Response expected:**
```json
{"version":"4.7.0"}
```

If not, restart manager:
```bash
docker-compose restart wazuh-manager
```

---

## 📊 Log Collection Issues

### Logs Not Appearing in Wazuh

**Checklist:**

1. Verify Nginx logs exist:
   ```bash
   docker-compose exec nginx tail -f /var/log/nginx/access.log
   
   # Generate log by making request
   curl http://localhost:8080
   ```

2. Verify Filebeat is running:
   ```bash
   docker-compose logs -f filebeat
   ```

3. Verify Filebeat can connect to Manager:
   ```bash
   docker-compose exec filebeat nc -zv wazuh-manager 5000
   ```

4. Restart Filebeat:
   ```bash
   docker-compose restart filebeat
   ```

5. Check Manager is listening on port 5000:
   ```bash
   docker-compose exec wazuh-manager netstat -tlnp | grep 5000
   ```

### Custom Rules Not Loading

**Verify rules are mounted:**
```bash
docker-compose exec wazuh-manager \
  cat /var/ossec/etc/rules/custom_rules.xml | head -20
```

**If empty or not showing:**

1. Verify file exists locally:
   ```bash
   ls -la wazuh/rules/custom_rules.xml
   ```

2. Check file path in docker-compose.yml is correct

3. Restart Manager:
   ```bash
   docker-compose restart wazuh-manager
   ```

4. Verify rules loaded:
   ```bash
   docker-compose exec wazuh-manager \
     grep -c "rule id=" /var/ossec/etc/rules/custom_rules.xml
   ```

---

## 🔥 DVWA Accessibility Issues

### Can't Access DVWA

**Check if running:**
```bash
docker-compose exec dvwa curl http://localhost/login.php
```

**Check health:**
```bash
curl http://localhost:8080
```

**If failing:**
```bash
# Check logs
docker-compose logs dvwa

# Restart
docker-compose restart dvwa

# Test again
curl http://localhost:8080
```

### Nginx Health Check Failing

**Test:**
```bash
curl http://localhost/health
```

**Expected response:** `healthy`

**If failing:**
```bash
docker-compose logs nginx
docker-compose restart nginx
```

---

## 🧹 Complete Reset

Jika semua tidak berfungsi, lakukan complete reset:

```bash
# Stop everything
docker-compose down

# Remove volumes
docker-compose down -v

# Remove all Wazuh images
docker rmi wazuh/wazuh-manager-single:4.7.0
docker rmi wazuh/wazuh-indexer-single:4.7.0
docker rmi wazuh/wazuh-dashboard-single:4.7.0

# Clean system
docker system prune -a

# Start fresh
docker-compose up -d
```

**Expected timeline for full startup:**
- First 1-2 minutes: Containers starting
- 2-5 minutes: Services initializing (Indexer, Manager)
- 5-10 minutes: Dashboard ready

---

## ✅ Verification Checklist

**Semua services running:**
```bash
docker-compose ps

# Expected output:
# soc-dvwa          Up
# soc-nginx         Up
# soc-filebeat      Up
# wazuh-manager     Up
# wazuh-indexer     Up
# wazuh-dashboard   Up
```

**Network connectivity:**
```bash
# Test DVWA
curl http://localhost:8080

# Test Nginx health
curl http://localhost/health

# Test Wazuh API
docker-compose exec wazuh-manager curl -u wazuh:wazuh \
  https://localhost:55000/version -k

# Test Indexer
docker-compose exec wazuh-indexer curl -u admin:SecurePassword123! \
  https://localhost:9200 -k
```

**Dashboard access:**
```
https://localhost:5601
Username: admin
Password: SecurePassword123!
```

---

## 📞 Common Commands Reference

```bash
# View all logs
docker-compose logs -f

# View specific service
docker-compose logs -f wazuh-manager
docker-compose logs -f wazuh-indexer
docker-compose logs -f wazuh-dashboard
docker-compose logs -f filebeat

# Restart services
docker-compose restart
docker-compose restart wazuh-manager

# Stop all
docker-compose down

# Full reset with volumes
docker-compose down -v

# Rebuild from scratch
docker-compose up -d --build

# Check status
docker-compose ps

# Execute command in container
docker-compose exec wazuh-manager bash
docker-compose exec nginx bash
```

---

## 🆘 Still Having Issues?

1. **Check logs carefully:**
   ```bash
   docker-compose logs | grep -i error
   ```

2. **Google the error message** - most common Docker + Wazuh issues have solutions

3. **Try basic troubleshooting:**
   - Ensure Docker is running
   - Ensure ports are available (8080, 5601, 1514-1516)
   - Ensure sufficient RAM (min 4GB)
   - Ensure internet connection for image pulls

4. **Nuclear option (Complete Reset):**
   ```bash
   # Stop everything
   docker-compose down -v
   
   # Clean up
   docker system prune -a
   
   # Start fresh
   docker-compose up -d
   ```

---

**Last Updated**: 2026-04-25
