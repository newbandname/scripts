# Get computer name and operating system information
$computerName = $env:COMPUTERNAME
$osInfo = Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber, OSArchitecture, InstallDate

# Get memory information in GB
$memoryInfo = Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum | Select-Object @{Name='Memory (GB)';Expression={$_.Sum / 1GB}}

# Get CPU information
$cpuInfo = Get-CimInstance Win32_Processor | Select-Object Name, Manufacturer, MaxClockSpeed, NumberOfCores, NumberOfLogicalProcessors

# Get logical disk information in GB
$logicalDiskInfo = Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID, VolumeName, @{Name='Capacity (GB)';Expression={$_.Size / 1GB}}, @{Name='FreeSpace (GB)';Expression={$_.FreeSpace / 1GB}}

# Get file share information
$fileShareInfo = Get-SmbShare | Select-Object Name, Path, Description

# Get page file information in GB
$pageFileInfo = Get-CimInstance Win32_PageFileUsage | Select-Object @{Name='Page File (GB)';Expression={$_.AllocatedBaseSize / 1GB}}

# Get network interfaces information
$networkInfo = Get-NetAdapter | Select-Object Name, InterfaceDescription, @{Name='MAC Address';Expression={$_.MACAddress -replace ':','-'}}, Status, DriverVersion

# Get ipconfig/all information
$ipConfigInfo = ipconfig /all

# Get installed roles and features
$rolesAndFeatures = Get-WindowsFeature | Where-Object {$_.Installed -eq $true} | Select-Object Name, DisplayName

# Get IIS site configurations
$iisSites = Get-ChildItem IIS:\Sites | Select-Object Name, PhysicalPath, @{Name='Bindings';Expression={$_.bindings.Collection.BindingInformation}}

# Get installed software
$installedSoftware = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, InstallLocation | Sort-Object DisplayName

# Get installed services
$services = Get-Service | Select-Object Name, DisplayName, Status, StartType, @{Name='Description';Expression={$_.Description -replace '\r\n',' '}} | Sort-Object DisplayName

# Get scheduled tasks
$scheduledTasks = Get-ScheduledTask | Select-Object TaskName, TaskPath, @{Name='Next Run Time';Expression={$_.NextRunTime}}, Enabled, @{Name='Last Run Time';Expression={$_.LastRunTime}}, @{Name='Status';Expression={$_.State -replace 'TaskState',''}}

# Create HTML file and add headings and tables for each piece of information
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
        border: 1px solid black;
    }
    th {
        background-color: lightgray;
    }
</style>
</head>
<body>
<h1>System Information for $computerName</h1>
<h2>Operating System Information</h2>
$tableOs
<h2>Memory Information</h2>
$tableMemory
<h2>CPU Information</h2>
$tableCpu
<h2>Logical Disk Information</h2>
$tableLogicalDisk
<h2>File Share Information</h2>
$tableFileShare
<h2>Page File Information</h2>
$tablePageFile
<h2>NIC Information</h2>
$tableNetworkInfo
<h2>IP Configuration Information</h2>
<pre>$ipConfigInfo</pre>
<h2>Installed Roles and Features</h2>
$tableRolesAndFeatures
<h2>IIS Site Configurations</h2>
$tableIisSites
<h2>Installed Software</h2>
$tableInstalledSoftware
<h2>Installed Services</h2>
$tableServices
<h2>Scheduled Task Details</h2>
$tableScheduledTasks
</body>
</html>
"@

# Create HTML tables for each piece of information
$tableOs = $osInfo | ConvertTo-Html -As Table -Fragment
$tableMemory = $memoryInfo | ConvertTo-Html -As Table -Fragment
$tableCpu = $cpuInfo | ConvertTo-Html -As Table -Fragment
$tableLogicalDisk = $logicalDiskInfo | ConvertTo-Html -As Table -Fragment
$tableFileShare = $fileShareInfo | ConvertTo-Html -As Table -Fragment
$tablePageFile = $pageFileInfo | ConvertTo-Html -As Table -Fragment
$tableNetworkInfo = $networkInfo | ConvertTo-Html -As Table -Fragment
$tableRolesAndFeatures = $rolesAndFeatures | ConvertTo-Html -As Table -Fragment
$tableIisSites = $iisSites | ConvertTo-Html -As Table -Fragment
$tableInstalledSoftware = $installedSoftware | ConvertTo-Html -As Table -Fragment
$tableServices = $services | ConvertTo-Html -As Table -Fragment
$tableScheduledTasks = $scheduledTasks | ConvertTo-Html -As Table -Fragment

# Save HTML file to desktop
$htmlPath = "$env:USERPROFILE\Desktop\$computerName System Information.html"
$html | Out-File -FilePath $htmlPath -Encoding UTF8

Write-Output "System information has been exported to $htmlPath"

