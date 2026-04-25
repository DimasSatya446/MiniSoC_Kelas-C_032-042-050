@echo off
REM ============================================================================
REM Mini SOC Startup Script (Windows)
REM ============================================================================
REM Purpose: Initialize and start all Mini SOC services on Windows
REM Usage: start.bat
REM ============================================================================

setlocal enabledelayedexpansion

echo ===================================================================
echo   Mini SOC - Startup Script (Windows)
echo ===================================================================
echo.

REM Check if Docker is running
echo [*] Checking Docker daemon...
docker ps >nul 2>&1
if errorlevel 1 (
    echo [!] Docker is not running. Please start Docker Desktop first.
    pause
    exit /b 1
)
echo [+] Docker daemon is running

REM Check if docker-compose.yml exists
echo [*] Checking docker-compose.yml...
if not exist "docker-compose.yml" (
    echo [!] docker-compose.yml not found in current directory
    pause
    exit /b 1
)
echo [+] docker-compose.yml found

REM Start services
echo.
echo [*] Starting all services (this may take 2-3 minutes)...
call docker-compose up -d
if errorlevel 1 (
    echo [!] Failed to start services
    pause
    exit /b 1
)

REM Wait for services to be healthy
echo.
echo [*] Waiting for services to become healthy...
timeout /t 10 /nobreak

REM Display service status
echo.
echo [*] Checking service status...
echo.
call docker-compose ps

REM Display service URLs
echo.
echo ===================================================================
echo [+] All services started successfully!
echo ===================================================================
echo.
echo Services available at:
echo.
echo DVWA Application:
echo   URL: http://localhost:8080
echo   Username: admin
echo   Password: password
echo.
echo Wazuh Dashboard:
echo   URL: https://localhost:5601
echo   Username: admin
echo   Password: SecurePassword123!
echo   Note: Accept self-signed certificate warning
echo.
echo Nginx Health Check:
echo   URL: http://localhost/health
echo.
echo ===================================================================
echo.
echo Next steps:
echo   1. Access DVWA at http://localhost:8080
echo   2. Set security level (top-right menu) to 'Low' for testing
echo   3. Run attack scenarios (see docs\attack-scenario.md)
echo   4. Monitor in Wazuh Dashboard (https://localhost:5601)
echo.
echo Troubleshooting:
echo   View logs:           docker-compose logs -f
echo   Restart services:    docker-compose restart
echo   Stop services:       docker-compose down
echo   View specific logs:  docker-compose logs wazuh-manager
echo.
echo Documentation:
echo   README.md            - Project overview
echo   docs\attack-scenario.md     - Attack examples
echo   docs\demo-flow.md    - Full demonstration guide
echo   docs\detection.md    - Detection rules explanation
echo   docs\incident-response.md   - Response procedures
echo.
echo ===================================================================
echo.
pause
