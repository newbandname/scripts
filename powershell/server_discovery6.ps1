# Set output directory and filename
$outputDir = "$env:USERPROFILE\Desktop"
$outputFile = "system_info.html"

# Define function to retrieve system information
function Get-SystemInfo {
    $computerName = $env:COMPUTERNAME
    
    # Get OS information
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber, OSArchitecture
    
    # Get RAM information in GB
    $ramInfo = Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | Select-Object @{Name='RAM (GB)';Expression={$_.Sum / 1GB}}, Count
    
    # Get CPU information
    $cpuInfo = Get-CimInstance -ClassName Win32_Processor | Select-Object Name, MaxClockSpeed, Caption, NumberOfCores, NumberOfLogicalProcessors
    
    # Get logical disk information in GB
    $diskInfo = Get-CimInstance -ClassName Win32_LogicalDisk | Select-Object DeviceID, MediaType, @{Name='Size (GB)';Expression={$_.Size / 1GB}}, @{Name='FreeSpace (GB)';Expression={$_.FreeSpace / 1GB}}
    
    # Get file share information
    $shareInfo = Get-SmbShare
    
    # Get page file information in GB
    $pageFileInfo = Get-CimInstance -ClassName Win32_PageFileUsage | Select-Object Name, @{Name='CurrentUsage (GB)';Expression={$_.CurrentUsage / 1GB}}
    
    # Get network interface information
    $netInfo = Get-NetAdapter | Select-Object Name, InterfaceDescription, Status
    
    # Get IP configuration
    $ipConfig = Get-NetIPAddress -AddressFamily IPv4
    
    # Get installed software
    $software = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher
    
    # Get installed services
    $services = Get-Service
    
    # Get installed roles and features
    $roles = Get-WindowsFeature | Where-Object {$_.Installed -eq $True} | Select-Object Name, DisplayName, Installed, Parent, SubFeatures
    
    # Get IIS site configurations
    $iisConfig = Get-WebConfiguration -Filter "/system.applicationHost/sites/site" | Select-Object Name, PhysicalPath, Bindings
    
    # Get scheduled tasks
    $scheduledTasks = Get-ScheduledTask | Select-Object TaskName, TaskPath, State, LastRunTime, NextRunTime, Status
    
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
        ScheduledTasks = $scheduledTasks
    }
    
    return $systemInfo
}

# Create HTML table for OS information
$osTable = $systemInfo.OSInfo | ConvertTo-Html -Fragment -As Table -Property Caption, Version, BuildNumber, OSArchitecture

# Create HTML table for RAM information
$ramTable = $systemInfo.RAMInfo | ConvertTo-Html -Fragment -As Table -Property 'RAM (GB)', Count

# Create HTML table for CPU information
$cpuTable = $systemInfo.CPUInfo | ConvertTo-Html -Fragment -As Table -Property Name, MaxClockSpeed, Caption, NumberOfCores, NumberOfLogicalProcessors

# Create HTML table for logical disk information
$diskTable = $systemInfo.DiskInfo | ConvertTo-Html -Fragment -As Table -Property DeviceID, MediaType, 'Size (GB)', 'FreeSpace (GB)'

# Create HTML table for file share information
$shareTable = $systemInfo.ShareInfo | ConvertTo-Html -Fragment -As Table -Property Name, Path, Description, FullAccess, ReadAccess, ChangeAccess

# Create HTML table for page file information
$pageFileTable = $systemInfo.PageFileInfo | ConvertTo-Html -Fragment -As Table -Property Name, 'CurrentUsage (GB)'

# Create HTML table for ethernet interface information
$ethernetTable = $systemInfo.EthernetInfo | ConvertTo-Html -Fragment -As Table -Property Name, MacAddress, LinkSpeed, Duplex, Status

# Create HTML table for IP configuration information
$ipConfigTable = $systemInfo.IPConfig | ConvertTo-Html -Fragment -As Table -Property IPAddress, InterfaceAlias, InterfaceIndex, AddressFamily, Type, PrefixLength

# Create HTML table for installed roles and features information and export to CSV
$rolesTable = $systemInfo.InstalledRoles | ConvertTo-Html -Fragment -As Table -Property Name, DisplayName, Installed, Parent, SubFeatures
$rolesPath = Join-Path $outputDir $rolesFile
$systemInfo.InstalledRoles | Export-Csv -Path $rolesPath -NoTypeInformation

# Create HTML table for installed software information
$softwareTable = $systemInfo.InstalledSoftware | ConvertTo-Html -Fragment -As Table -Property DisplayName, DisplayVersion, Publisher

# Create HTML table for installed services information
$servicesTable = $systemInfo.InstalledServices | ConvertTo-Html -Fragment -As Table -Property Name, DisplayName, Status, StartType, ServiceType, PathName, Description

# Create HTML table for schedule tasks information
$scheduledTasksTable = $systemInfo.ScheduledTasks | ConvertTo-Html -Fragment -As Table -Property TaskName, TaskPath, State, LastRunTime, NextRunTime, Status

# Create HTML file
$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>System Information</title>
    <style>
        table {
            border-collapse: collapse;
            width: 100%;
        }
        th, td {
            text-align: left;
            padding: 8px;
            border: 1px solid black;
        }
        th {
            background-color: #4CAF50;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
    </style>
</head>
<body>
    <h1>System Information</h1>
    <h2>General Information</h2>
    <table>
        <tr>
            <th>Computer Name</th>
            <th>Value</th>
        </tr>
        <tr>
            <td>Computer Name</td>
            <td>$($systemInfo.ComputerName)</td>
        </tr>
    </table>

    $osTable
    $ramTable
    $cpuTable
    $diskTable
    $shareTable
    $pageFileTable
    $netTable
    $ipConfigTable
    $rolesTable
    $softwareTable
    $servicesTable
    $scheduledTasksTable

</body>
</html>
"@

# Save HTML file
$htmlPath = Join-Path $outputDir $outputFile
$html | Out-File $htmlPath

# Output file location to console
Write-Host "System information saved to $($htmlPath)"
