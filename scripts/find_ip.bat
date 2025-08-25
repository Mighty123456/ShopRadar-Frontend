@echo off
echo ========================================
echo    ShopRadar Network Configuration
echo ========================================
echo.
echo Finding your computer's IP address...
echo.

for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (
    set ip=%%a
    set ip=!ip: =!
    echo Found IP: !ip!
    echo.
    echo Use this IP in your network configuration:
    echo http://!ip!:3000
    echo.
    echo ========================================
    echo.
    pause
)
