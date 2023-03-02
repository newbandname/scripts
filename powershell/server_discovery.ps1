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
    $ipConfig = Get-NetIPAddress -AddressFamily IPv4 | Select-Object InterfaceAlias, IPAddress, PrefixLength, AddressState
    
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

# Create HTML table for OS information
$osTable = $systemInfo.OSInfo | ConvertTo-Html -Fragment -As Table -Property Caption, Version, BuildNumber, OSArchitecture

# Create HTML table for RAM information
$ramTable = $systemInfo.RAMInfo | ConvertTo-Html -Fragment -As Table -Property RAM, Count

# Create HTML table for CPU information
$cpuTable = $systemInfo.CPUInfo | ConvertTo-Html -Fragment -As Table -Property Name, MaxClockSpeed, Caption, NumberOfCores, NumberOfLogicalProcessors

# Create HTML table for logical disk information
$diskTable = $systemInfo.DiskInfo | ConvertTo-Html -Fragment -As Table -Property DeviceID, MediaType, Size, FreeSpace

# Create HTML table for file share information
$shareTable = $systemInfo.ShareInfo | ConvertTo-Html -Fragment -As Table -Property Name, Path, Description, CurrentUsers, ShareState

# Create HTML table for page file information
$pageFileTable = $systemInfo.PageFileInfo | ConvertTo-Html -Fragment -As Table -Property Name, CurrentUsage

# Create HTML table for network interface information
$netTable = $systemInfo.NetInfo | ConvertTo-Html -Fragment -As Table -Property Name, InterfaceDescription, Status

# Create HTML table for IP configuration information
$ipTable = $systemInfo.IPConfig | ConvertTo-Html -Fragment -As Table -Property InterfaceAlias, IPAddress, PrefixLength, AddressState

# Create HTML table for installed software
$softwareTable = $systemInfo.InstalledSoftware | ConvertTo-Html -Fragment -As Table -Property Name, Version

# Create HTML table for installed services
$servicesTable = $systemInfo.InstalledServices | ConvertTo-Html -Fragment -As Table -Property Name, DisplayName, Status, StartType, Description

# Create HTML table for installed roles
$rolesTable = $systemInfo.InstalledRoles | ConvertTo-Html -Fragment -As Table -Property Name, InstallState

# Create HTML table for IIS site configurations
$iisTable = $systemInfo.IISConfig | ConvertTo-Html -Fragment -As Table -Property Name, PhysicalPath, Bindings

# Combine HTML tables into final report
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
    <h2>Computer Information</h2>
    <table>
        <tr><th>Computer Name</th><td>$($systemInfo.ComputerName)</td></tr>
    </table>
    <h2>Operating System Information</h2>
    $osTable
    <h2>RAM Information</h2>
    $ramTable
    <h2>CPU Information</h2>
    $cpuTable
    <h2>Logical Disk Information</h2>
    $diskTable
    <h2>File Share Information</h2>
    $shareTable
    <h2>Page File Information</h2>
    $pageFileTable
    <h2>Network Interface Information</h2>
    $netTable
    <h2>IP Configuration Information</h2>
    $ipTable
    <h2>Installed Software</h2>
    $softwareTable
    <h2>Installed Services</h2>
    $servicesTable
    <h2>Installed Roles</h2>
    $rolesTable
    <h2>IIS Site Configurations</h2>
    $iisTable
</body>
</html>
"@

# Save HTML report to file
$html | Out-File -FilePath "$outputDir\$outputFile"

# Display message to confirm report generation
Write-Host "System information report generated successfully at $outputDir\$outputFile"
