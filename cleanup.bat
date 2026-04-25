@echo off
REM ============================================================================
REM Mini SOC Cleanup Script (Windows)
REM ============================================================================
REM Purpose: Stop and clean up all Mini SOC services on Windows
REM Usage: cleanup.bat
REM ============================================================================

setlocal

echo ===================================================================
echo   Mini SOC - Cleanup Script (Windows)
echo ===================================================================
echo.

set /p confirm="Are you sure you want to stop all containers? (y/N): "
if /i "%confirm%"=="y" (
    echo [*] Stopping all services...
    call docker-compose down
    echo [+] Services stopped
    echo.
    
    set /p remove_volumes="Remove Docker volumes as well? (y/N): "
    if /i "%remove_volumes%"=="y" (
        echo [*] Removing volumes...
        call docker-compose down -v
        echo [+] Volumes removed
    )
    
    echo.
    echo [+] Cleanup completed
    echo.
    echo To restart services later, run: start.bat
) else (
    echo [*] Cleanup cancelled
)

pause
