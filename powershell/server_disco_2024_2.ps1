$env:computername = $env:computername  

function Format-Table {
    param($Data)

    $result = "<table>"
    $result += "<thead><tr><th>Property</th><th>Value</th></tr></thead>"
    $result += "<tbody>"
    $Data | ForEach-Object {
        $result += "<tr>"
        $_.PSObject.Properties | ForEach-Object {
            $result += "<td>$($_.Name)</td><td>$($_.Value)</td>" 
        }
        $result += "</tr>" 
    }
    $result += "</tbody></table>"
    $result
}

# Get output file path
$desktopPath = [Environment]::GetFolderPath('Desktop')
$outputFilePath = Join-Path $desktopPath "server_discovery_results.html"

# Start HTML structure
$html = @"
<html>
<head>
<title>Server Discovery Report - $env:computername</title>
<style>
table, th, td { border: 1px solid black; border-collapse: collapse; }
th, td { padding: 5px; }
pre { font-family: monospace; } 
</style>
</head>
<body>
<h1>Server Discovery Report - $env:computername</h1>
"@

# System Information
$html += "<h2>System Information</h2>"
$html += Format-Table (Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber, OSArchitecture, Manufacturer, *)
$html += Format-Table (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Name, Manufacturer, Model, TotalPhysicalMemory, NumberOfLogicalProcessors, NumberOfCores)

# Logical Disks
$html += "<h2>Logical Disks</h2>"
$html += Format-Table (Get-CimInstance -ClassName Win32_LogicalDisk | Select-Object DeviceID, DriveType, FileSystem, FreeSpace, Size)

# File Shares
$html += "<h2>File Shares</h2>"
$html += Format-Table (Get-SmbShare) 

# Page File
$html += "<h2>Page File</h2>"
$html += Format-Table (Get-CimInstance -ClassName Win32_PageFileSetting) 

# Host File
$html += "<h2>Hosts File</h2>"
$html += "<pre>" 
$html += (Get-Content -Path C:\Windows\System32\drivers\etc\hosts) 
$html += "</pre>"

# NIC Configuration
$html += "<h2>Network Configuration</h2>"
$html += Format-Table (Get-NetAdapter | Select-Object Name, InterfaceDescription, Status, MacAddress, IPv4Address, IPv6Address, DefaultGateway)
$html += Format-Table (Get-DnsClientServerAddress)
$html += "<h3>IP Configuration</h3>"
$html += "<pre>" 
$html += (ipconfig /all | Out-String).Trim() 
$html += "</pre>"

# Roles and Features
$html += "<h2>Roles and Features</h2>"
$html += Format-Table (Get-WindowsFeature | Where-Object Installed -eq $true)

# IIS
$html += "<h2>IIS Configuration</h2>"
$html += Format-Table (Get-WebSite)

# Installed Software
$html += "<h2>Installed Software</h2>"
$html += Format-Table (Get-WmiObject -Class Win32_Product | Select-Object Name, Version, Vendor)

# Services
$html += "<h2>Services</h2>"
$html += Format-Table (Get-Service)

# Scheduled Tasks
$html += "<h2>Scheduled Tasks</h2>"
$html += Format-Table (Get-ScheduledTask | Where-Object {$_.State -ne "Disabled" })

# Close HTML 
$html += "</body></html>"

# Save to file 
$html | Out-File $outputFilePath