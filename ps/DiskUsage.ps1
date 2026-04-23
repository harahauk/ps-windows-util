##
# DiskUsage.ps1 - A PowerShell script to analyze disk usage in a specified directory.
# 
# Parameters:
# -Path: The path to analyze (optional, default: "./")
# 
# @author Harald Hauknes <harald at hauknes dot org>
##
param (
    [Parameter(Mandatory = $false)]
    [string]$Path = "."
)

# Validate path
if (-not (Test-Path $Path)) {
    Write-Error "Path does not exist: $Path"
    exit 1
}

Write-Host "Scanning path: $Path ..." -ForegroundColor Cyan

# Collect file data
$files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue |
    Select-Object FullName,
                  @{Name = "SizeGB"; Expression = { [math]::Round($_.Length / 1GB, 4) }}

# Sort ascending (largest at bottom)
$sorted = $files | Sort-Object SizeGB

# Output to console
$sorted | Format-Table -AutoSize

# Optional: export to CSV
# $sorted | Export-Csv -Path "file_sizes.csv" -NoTypeInformation

#Write-Host "Completed." -ForegroundColor Green