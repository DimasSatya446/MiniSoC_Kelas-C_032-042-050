@echo off
echo ===================================================================
echo   Mini SOC - Generate SSL Certificates
echo ===================================================================
echo.
echo [*] Generating Wazuh SSL certificates...
echo     This only needs to be done ONCE.
echo.

REM Check if certs already exist
if exist "config\wazuh_indexer_ssl_certs\root-ca.pem" (
    echo [!] Certificates already exist. Skipping generation.
    echo     Delete the config\wazuh_indexer_ssl_certs\ folder to regenerate.
    goto :done
)

REM Run certificate generator
docker run --rm ^
  -v "%CD%\config\wazuh_indexer_ssl_certs\:/certificates/" ^
  -v "%CD%\config\certs.yml:/config/certs.yml" ^
  wazuh/wazuh-certs-generator:0.0.2

if %errorlevel% neq 0 (
    echo [-] Failed to generate certificates!
    pause
    exit /b 1
)

echo.
echo [+] Certificates generated successfully in config\wazuh_indexer_ssl_certs\
echo.

:done
echo [*] You can now run start.bat
echo.
pause
