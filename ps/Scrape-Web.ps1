##
# Scrape-Web.ps1 - A PowerShell script to recursively scrape images from a given URL and save them to a specified directory.
# 
# Parameters:
# -Uri: The base URL to start scraping from (required)
# -Dest: The destination directory to save the files (optional, default: "./scraped-images")
# -FileTypes: A regex pattern of file extensions to match for downloading (optional, default: 'jpg|jpeg|png|gif|webp')
# 
# @author Harald Hauknes <harald at hauknes dot org>
##
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Uri,

    [Parameter(Mandatory = $false, Position = 1)]
    [string]$Dest = "./scraped-images",

    [Parameter(Mandatory = $false)]
    [string]$FileTypes = 'jpg|jpeg|png|gif|webp'
)

# Normalize destination
# Not valid in older PS # $Dest = (Resolve-Path -Path $Dest -ErrorAction SilentlyContinue) ?? (New-Item -ItemType Directory -Path $Dest -Force).FullName
if (-not (Resolve-Path -Path $Dest -ErrorAction SilentlyContinue)) {
    $null = New-Item -ItemType Directory -Path $Dest -Force
}
$Dest = (Resolve-Path -Path $Dest).Path

# Track visited URLs to avoid loops
$visited = [System.Collections.Generic.HashSet[string]]::new()

function Get-ImagesRecursive {
    param (
        [string]$CurrentUrl
    )
    if ($visited.Contains($CurrentUrl)) {
        return
    }
    $visited.Add($CurrentUrl) | Out-Null
    Write-Debug "Visited: $visited"

    try {
        Write-Host "Processing: $CurrentUrl"
        $response = Invoke-WebRequest -UseBasicParsing -Uri $CurrentUrl -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to access $CurrentUrl"
        return
    }

    #Write-Debug "$response"
    Write-Debug "Count of links found: $($response.Links.Count). Looping through them.."
    Write-Debug "All links: $($response.Links | ForEach-Object { $_.href })"
    $count = 1
    foreach ($link in $response.Links) {
      Write-Debug "Processing link number $($count)/$($response.Links.Count): $($link.href)"
      $count += 1

      if (-not $link.href) {
        Write-Debug "Skipping link with empty 'href'.." 
        continue 
      }
      $href = $link.href.Trim()
      
      if ($href.StartsWith('?')) {
        Write-Debug "Skipping query link: $href"
        continue
      }

      if ($href -eq "../") {
        Write-Debug "Skipping parent directory link '../'"
        continue 
      }

      try {
        $resolvedUrl = [System.Uri]::new($CurrentUrl, $href).AbsoluteUri
      } catch {
        continue
      }

      Write-Debug "Discovered: $resolvedUrl"
      Write-Debug "Value of href: $href"

      # DIRECTORY FIRST
      if ($href.EndsWith('/')) {
        # TODO: Parent directory links like 'this_is_the_problem/my_path/' are not ignored properly
        Write-Debug "This is a directory, recursing into directory: $resolvedUrl"
        Write-Host "Found directory: $href, recursing into it.."
        Get-ImagesRecursive -CurrentUrl $resolvedUrl
        Write-Host "Leaving directory: $href, going back to parent.."
        continue
      }

      # Match file types
      #if ($resolvedUrl -match "\.($FileTypes)$")      
      #if ($resolvedUrl -imatch "\.($FileTypes)(\?|$)")
      #$fileName = Split-Path $resolvedUrl -Leaf
      $fileName = $href
      Write-Debug "Resolved URL: $resolvedUrl, File Name: $fileName"
      if ($fileName -imatch "\.($FileTypes)$") {
        #$fileName = Split-Path $resolvedUrl -Leaf
        $outputPath = Join-Path $Dest $fileName
        $fullURL = $resolvedUrl + $fileName

        if (-not (Test-Path $outputPath)) {
          try {
                    Write-Host "Downloading: $fileName"
                    Invoke-WebRequest -Uri $fullURL -OutFile $outputPath -ErrorAction Stop
          }
                catch {
                    Write-Warning "Failed to download $fullURL"
                }
        } else {
          Write-Host "'$outputPath' already exists, skipping download."
        }
      }
    } # End of foreach loop
}

# Start recursion
Get-ImagesRecursive -CurrentUrl $Uri