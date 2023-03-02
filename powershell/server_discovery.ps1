# Set output directory and filename
$outputDir = "$env:USERPROFILE\Desktop"
$outputFile = "system_info.html"

# Define function to retrieve system information
function Get-SystemInfo {
    $computerName = $env:COMPUTERNAME
    
    # Get OS information
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber, OSArchitecture
    
    # Get RAM information
    $ramInfo = Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | Select-Object @{Name='RAM';Expression={$_.Sum / 1GB}}, Count
    
    # Get CPU information
    $cpuInfo = Get-CimInstance -ClassName Win32_Processor | Select-Object Name, MaxClockSpeed, Caption, NumberOfCores, NumberOfLogicalProcessors
    
    # Get logical disk information
    $diskInfo = Get-CimInstance -ClassName Win32_LogicalDisk | Select-Object DeviceID, MediaType, Size, FreeSpace
    
    # Get file share information
    $shareInfo = Get-SmbShare
    
    # Get page file information
    $pageFileInfo = Get-CimInstance -ClassName Win32_PageFileUsage | Select-Object Name, CurrentUsage
    
    # Get network interface information
    $netInfo = Get-NetAdapter | Select-Object Name, InterfaceDescription, Status
    
    # Get IP configuration
    $ipConfig = Get-NetIPAddress
    
    # Get installed software
    $software = Get-WmiObject -Class Win32_Product | Select-Object Name, Version
    
    # Get installed services
    $services = Get-Service
    
    # Get installed roles
    $roles = Get-WindowsFeature | Where-Object {$_.Installed -eq $True}
    
    # Get IIS site configurations
    $iisConfig = Get-WebConfiguration -Filter "/system.applicationHost/sites/site" | Select-Object Name, PhysicalPath, Bindings
    
    # Create custom object with system information
    $systemInfo = [PSCustomObject]@{
        ComputerName = $computerName
        OSInfo = $osInfo
        RAMInfo = $ramInfo
        CPUInfo = $cpuInfo
        DiskInfo = $diskInfo
        ShareInfo = $shareInfo
        PageFileInfo = $pageFileInfo
        NetInfo = $netInfo
        IPConfig = $ipConfig
        InstalledSoftware = $software
        InstalledServices = $services
        InstalledRoles = $roles
        IISConfig = $iisConfig
    }
    
    return $systemInfo
}

# Call the Get-SystemInfo function
$systemInfo = Get-SystemInfo

# Convert system information to HTML table
$table = $systemInfo | ConvertTo-Html -Fragment

# Create HTML template
$html = @"
<html>
<head>
    <style>
        table {
            border-collapse: collapse;
            width: 100%;
        }
        th, td {
            text-align: left;
            padding: 8px;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #4CAF50;
            color: white;
        }
        h1 {
            text-align: center;
        }
    </style>
</head>
<body>
    <h1>System Information Report</h1>
    $table
</body>
</html>
"@

# Save HTML report to file
$html | Out-File -FilePath "$outputDir\$outputFile"

# Display message to confirm report generation
Write-Host "System information report generated successfully at $outputDir\$outputFile"
