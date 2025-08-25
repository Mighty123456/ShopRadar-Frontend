# ShopRadar IP Address Finder for Windows PowerShell
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    ShopRadar Network Configuration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Finding your computer's IP address..." -ForegroundColor Yellow
Write-Host ""

try {
    # Get network interfaces
    $interfaces = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
        $_.IPAddress -notlike "127.*" -and 
        $_.IPAddress -notlike "169.254.*" -and
        $_.IPAddress -notlike "10.0.2.*"
    }
    
    if ($interfaces) {
        Write-Host "Found IP addresses:" -ForegroundColor Green
        Write-Host ""
        
        foreach ($interface in $interfaces) {
            Write-Host "IP: $($interface.IPAddress)" -ForegroundColor White
            Write-Host "Interface: $($interface.InterfaceAlias)" -ForegroundColor Gray
            Write-Host "Backend URL: http://$($interface.IPAddress):3000" -ForegroundColor Cyan
            Write-Host ""
        }
        
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Use one of these IPs in your network configuration." -ForegroundColor Yellow
        Write-Host "Recommended: Use the IP from your WiFi adapter." -ForegroundColor Yellow
        Write-Host ""
        
    } else {
        Write-Host "No suitable IP addresses found." -ForegroundColor Red
    }
    
} catch {
    Write-Host "Error finding IP address: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
