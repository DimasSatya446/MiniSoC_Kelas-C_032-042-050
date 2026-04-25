# 🎬 Mini SOC - ATTACK TESTING QUICK START

**Copy & Paste these commands to start testing in the next 2 minutes!**

---

## ⚡ Ultra-Quick Start (2 minutes)

### Terminal 1: Open monitoring for Nginx logs
```powershell
docker compose logs -f nginx
```

### Terminal 2: Open monitoring for Wazuh alerts  
```powershell
docker compose logs -f wazuh-manager
```

### Terminal 3: Execute attacks
```powershell
cd C:\Users\danis\MiniSoC_Kelas-C_032-042-050
.\attack-windows.ps1
# Select: 1 (for SQL Injection)
# OR select: 5 (for All Attacks)
```

---

## 📊 What You'll See

**Terminal 1 Output** (Within 1 second):
```
soc-nginx | 127.0.0.1 - - [25/Apr/2026:05:06:38] "GET /vulnerabilities/sqli/?id=..." 200
```

**Terminal 2 Output** (Within 5 seconds):
```
wazuh-manager | 2026-04-25 05:06:40 wazuh-analysisd: INFO: Generated alert: (Rule: 100100)
```

**What happened**: Attack detected! ✅

---

## 🖥️ View Results in Dashboard

1. Open browser: **http://localhost:5601**
2. Login: **admin** / **SecurePassword123!**
3. Go to: **Security Events**
4. You'll see alerts with full details! 📊

---

## 📝 Sample Attacks (Copy-Paste Ready)

### Single SQL Injection Attack
```powershell
$p = "admin' OR '1'='1"
$e = [System.Web.HttpUtility]::UrlEncode($p)
Invoke-WebRequest "http://localhost:8080/vulnerabilities/sqli/?id=$e" -UseBasicParsing -ErrorAction SilentlyContinue
```

### 5 Different SQL Injection Payloads
```powershell
$payloads = @(
    "admin' OR '1'='1",
    "1' UNION SELECT user(),database() --",
    "1' AND 1=2 UNION SELECT NULL,NULL,NULL --",
    "' OR 'a'='a",
    "1 OR 1=1 --"
)
foreach ($payload in $payloads) {
    $e = [System.Web.HttpUtility]::UrlEncode($payload)
    Invoke-WebRequest "http://localhost:8080/vulnerabilities/sqli/?id=$e" -UseBasicParsing -ErrorAction SilentlyContinue
    Start-Sleep -s 2
}
```

### Quick Brute Force Test
```powershell
$passwords = @("password", "12345", "admin123", "letmein")
foreach ($pw in $passwords) {
    Invoke-WebRequest "http://localhost:8080/vulnerabilities/brute/" -Method POST `
      -Body "username=admin&password=$pw&Login=Login" -UseBasicParsing -ErrorAction SilentlyContinue
    Start-Sleep -s 2
}
```

---

## 🔍 Monitoring Commands

### View Latest Nginx Logs (Last 50 lines)
```powershell
docker compose logs nginx --tail 50
```

### View Latest Wazuh Alerts (Last 50 lines)
```powershell
docker compose logs wazuh-manager --tail 50
```

### View Actual Alert JSON
```powershell
docker compose exec wazuh-manager tail -100 /var/ossec/logs/alerts/alerts.json
```

### Watch Live Alert Generation
```powershell
docker compose exec wazuh-manager tail -f /var/ossec/logs/alerts/alerts.json
```

---

## ✅ Verification Checklist

After running attacks, check:

- [ ] Nginx logs show HTTP requests
  ```powershell
  docker compose logs nginx | Select-String "sqli"
  ```

- [ ] Wazuh Manager shows alerts
  ```powershell
  docker compose logs wazuh-manager | Select-String "Generated alert"
  ```

- [ ] Alert file has entries
  ```powershell
  docker compose exec wazuh-manager wc -l /var/ossec/logs/alerts/alerts.json
  ```

- [ ] Dashboard is accessible
  ```powershell
  Start-Process "http://localhost:5601"
  ```

---

## 📚 Documentation Map

| Need | Read This |
|------|-----------|
| Quick overview | START_HERE.md |
| Copy-paste ready | QUICK_ATTACK_REFERENCE.md |
| Complete guide | TESTING_GUIDE.md |
| Real log examples | ATTACK_LOG_EXAMPLES.md |
| What was fixed | SETUP_FIXED.md |

---

## 🚀 DO THIS RIGHT NOW (30 seconds)

1. **Copy this line:**
   ```powershell
   .\attack-windows.ps1
   ```

2. **Open PowerShell in project folder:**
   ```powershell
   cd C:\Users\danis\MiniSoC_Kelas-C_032-042-050
   ```

3. **Paste and run:**
   ```powershell
   .\attack-windows.ps1
   ```

4. **Select option: 1 or 5**

5. **Done! You're testing attacks now!** ✅

---

**All 7 containers are running and operational. You're ready to go! 🚀**
