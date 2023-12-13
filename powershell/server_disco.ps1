# This script will pull the following info from a server, format to an html file and output it to the local desktop:
# OS information
# CPU core count
# Memory in GB 
# Logical Disk info (round to nearest 100th)
# File Share info
# Page file info
# Ethernet interface info
# Runs and displays output of ipconfig/all
# All installed roles
# IIS site, if it exists (empty results if no IIS site is configured)
# All installed software
# All Services installed
# All Scheduled Tasks details



# Define file path for HTML file
$htmlFilePath = "$($env:USERPROFILE)\Desktop\System-Info.html"

# Define function to convert bytes to GB
function Get-GB {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [int64]$Size
    )
    process {
        [math]::Round($Size / 1GB, 2)
    }
}

# Define table headers
$htmlTableHeaders = "<html><head><style>table { border-collapse: collapse; width: 100%; } th, td { text-align: left; padding: 8px; } th { background-color: #005587; color: white; } tr:nth-child(even) { background-color: #f2f2f2; }</style></head><body><h1>System Information</h1>"
$osHeader = "<h2>OS Information</h2>"
$osTableHeaders = "<tr><th>Caption</th><th>Version</th></tr>"

$memoryHeader = "<h2>Memory Information</h2>"
$memoryTableHeaders = "<tr><th>Total Memory (GB)</th></tr>"

$cpuHeader = "<h2>CPU Information</h2>"
$cpuTableHeaders = "<tr><th>Name</th><th>Number of Cores</th><th>Number of Logical Processors</th></tr>"

$diskHeader = "<h2>Logical Disk Information</h2>"
$diskTableHeaders = "<tr><th>Drive Letter</th><th>Total Size (GB)</th><th>Free Space (GB)</th></tr>"

$shareHeader = "<h2>File Share Information</h2>"
$shareTableHeaders = "<tr><th>Name</th><th>Path</th><th>Description</th></tr>"

$pagefileHeader = "<h2>Page File Information</h2>"
$pagefileTableHeaders = "<tr><th>Page File Size (GB)</th></tr>"

$ethernetHeader = "<h2>Ethernet Interface Information</h2>"
$ethernetTableHeaders = "<tr><th>Name</th><th>MAC Address</th><th>IPv4 Address</th><th>Subnet Mask</th><th>Default Gateway</th></tr>"

$ipconfigHeader = "<h2>IPConfig/All Information</h2>"

$rolesHeader = "<h2>Installed Roles and Features</h2>"
$rolesTableHeaders = "<tr><th>Name</th><th>Installed</th></tr>"

$iisHeader = "<h2>IIS Site Configurations</h2>"
$iisTableHeaders = "<tr><th>Name</th><th>ID</th><th>Physical Path</th><th>State</th></tr>"

$softwareHeader = "<h2>Installed Software</h2>"
$softwareTableHeaders = "<tr><th>Name</th><th>Version</th></tr>"

$servicesHeader = "<h2>Services Installed</h2>"
$servicesTableHeaders = "<tr><th>Name</th><th>Display Name</th><th>Start Type</th><th>Account</th></tr>"

$tasksHeader = "<h2>Scheduled Task Details</h2>"
$tasksTableHeaders = "<tr><th>Name</th><th>Path</th><th>State</th><th>Last Run Time</th><th>Next Run Time</th></tr>"

# Get system information
$os = Get-WmiObject -Class Win32_OperatingSystem
$memory = Get-WmiObject -Class Win32_ComputerSystem
$cpu = Get-WmiObject -Class Win32_Processor
$pagefile = Get-WmiObject -Class Win32_PageFileUsage

# Get disk information
$disks = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType = '3'"

# Get network adapter information
$ethernet = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled='True'"

# Get file share information
$shares = Get-WmiObject -Class Win32_Share

# Get installed roles and features
$roles = Get-WindowsFeature

# Get IIS site configurations
$iisSites = Get-ChildItem -Path IIS:\Sites | Select-Object Name, ID, PhysicalPath, State

# Get installed software
$software = Get-WmiObject -Class Win32_Product | Select-Object Name, Version

# Get services information
$services = Get-Service | Select-Object Name, DisplayName, StartType, @{Name="Account";Expression={$_.ServiceAccount}}

# Get scheduled task details
$tasks = Get-ScheduledTask | Select-Object TaskName, TaskPath, State, LastRunTime, NextRunTime

# Build HTML tables
$osTableRow = "<tr><td>$($os.Caption)</td><td>$($os.Version)</td></tr>"
$memoryTableRow = "<tr><td>$($memory.TotalPhysicalMemory | Get-GB)</td></tr>"
$cpuTableRow = "<tr><td>$($cpu.Name)</td><td>$($cpu.NumberOfCores)</td><td>$($cpu.NumberOfLogicalProcessors)</td></tr>"

$diskTableRows = ""
foreach ($disk in $disks) {
    $freeSpace = $disk.FreeSpace | Get-GB
    $totalSize = $disk.Size | Get-GB
    $diskTableRows += "<tr><td>$($disk.DeviceID)</td><td>$($totalSize)</td><td>$($freeSpace)</td></tr>"
}

$shareTableRows = ""
foreach ($share in $shares) {
    $shareTableRows += "<tr><td>$($share.Name)</td><td>$($share.Path)</td><td>$($share.Description)</td></tr>"
}

$pagefileTableRow = "<tr><td>$($pagefile.AllocatedBaseSize | Get-GB)</td></tr>"

$ethernetTableRows = ""
foreach ($adapter in $ethernet) {
    $ethernetTableRows += "<tr><td>$($adapter.Caption)</td><td>$($adapter.MACAddress)</td><td>$($adapter.IPAddress[0])</td><td>$($adapter.IPSubnet[0])</td><td>$($adapter.DefaultIPGateway[0])</td></tr>"
}

$ipconfigTableRow = "<tr><td>$(ipconfig /all)</td></tr>"

$rolesTableRows = ""
foreach ($role in $roles) {
    $rolesTableRows += "<tr><td>$($role.Name)</td><td>$($role.Installed)</td></tr>"
}

$iisTableRows = ""
foreach ($site in $iisSites) {
    $iisTableRows += "<tr><td>$($site.Name)</td><td>$($site.ID)</td><td>$($site.PhysicalPath)</td><td>$($site.State)</td></tr>"
}

$softwareTableRows = ""
foreach ($app in $software) {
    $softwareTableRows += "<tr><td>$($app.Name)</td><td>$($app.Version)</td></tr>"
}

$servicesTableRows = ""
foreach ($service in $services) {
    $servicesTableRows += "<tr><td>$($service.Name)</td><td>$($service.DisplayName)</td><td>$($service.StartType)</td><td>$($service.Account)</td></tr>"
}

$tasksTableRows = ""
foreach ($task in $tasks) {
    $tasksTableRows += "<tr><td>$($task.TaskName)</td><td>$($task.TaskPath)</td><td>$($task.State)</td><td>$($task.LastRunTime)</td><td>$($task.NextRunTime)</td></tr>"
}

# Build HTML file
$htmlOutput = $htmlTableHeaders

$htmlOutput += $osHeader
$htmlOutput += "<table>$osTableHeaders$osTableRow</table>"

$htmlOutput += $memoryHeader
$htmlOutput += "<table>$memoryTableHeaders$memoryTableRow</table>"

$htmlOutput += $cpuHeader
$htmlOutput += "<table>$cpuTableHeaders$cpuTableRow</table>"

$htmlOutput += $diskHeader
$htmlOutput += "<table>$diskTableHeaders$diskTableRows</table>"

$htmlOutput += $shareHeader
$htmlOutput += "<table>$shareTableHeaders$shareTableRows</table>"

$htmlOutput += $pagefileHeader
$htmlOutput += "<table>$pagefileTableHeaders$pagefileTableRow</table>"

$htmlOutput += $ethernetHeader
$htmlOutput += "<table>$ethernetTableHeaders$ethernetTableRows</table>"

$htmlOutput += $ipconfigHeader
$htmlOutput += "<pre>$(ipconfig /all)</pre>"

$htmlOutput += $rolesHeader
$htmlOutput += "<table>$rolesTableHeaders$rolesTableRows</table>"

$htmlOutput += $iisHeader
$htmlOutput += "<table>$iisTableHeaders$iisTableRows</table>"

$htmlOutput += $softwareHeader
$htmlOutput += "<table>$softwareTableHeaders$softwareTableRows</table>"

$htmlOutput += $servicesHeader
$htmlOutput += "<table>$servicesTableHeaders$servicesTableRows</table>"

$htmlOutput += $tasksHeader
$htmlOutput += "<table>$tasksTableHeaders$tasksTableRows</table>"

$htmlOutput += "</body></html>"

# Output HTML file
$htmlOutput | Out-File -FilePath $htmlFilePath