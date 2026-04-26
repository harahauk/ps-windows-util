## Enable-Remote-Desktop.ps1
# This script enables Remote Desktop on a Windows machine and allows it through the firewall.

# Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\' -Name "fDenyTSConnections" -Value 0

# Enable RDP through the firewall
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Start-Service -Name "TermService" -ErrorAction SilentlyContinue
Write-Host "Remote Desktop has been enabled. You can connect to this machine using Remote Desktop Connection (mstsc.exe)." -ForegroundColor Green