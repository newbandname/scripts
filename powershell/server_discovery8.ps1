# Define variables
$htmlFilePath = "$env:UserProfile\Desktop\server-info.html"
$computerName = $env:COMPUTERNAME

# Define functions to get data
function Get-GB {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [int64]$Size
    )
    process {
        $gbSize = "{0:N2}" -f ($Size / 1GB)
        return $gbSize
    }
}

# Define HTML table headers
$htmlTableHeaders = @"
    <style>
        table {
            font-family: arial, sans-serif;
            border-collapse: collapse;
            width: 100%;
        }
        td, th {
            border: 1px solid #dddddd;
            text-align: left;
            padding: 8px;
        }
        tr:nth-child(even) {
            background-color: #dddddd;
        }
    </style>
    <h1>Server Information for $computerName</h1>
"@

# Define table headers
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

# Define table data
$osTableRow = "<tr><td>$($os.Caption)</td><td>$($os.Version)</td></tr>"
$memoryTableRow = "<tr><td>$(Get-GB -Size $($memory.TotalVisibleMemorySize))</td></tr>"
$cpuTableRow = "<tr><td>$($cpu.Name)</td><td>$($cpu.NumberOfCores)</td><td>$($cpu.NumberOfLogicalProcessors)</td></tr>"
$diskTableRow = ""
Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $driveLetter = $_.DeviceID
    $totalSize = Get-GB -Size $_.Size
    $freeSpace = Get-GB -Size $_.FreeSpace
    $diskTableRow += "<tr><td>$driveLetter</td><td>$totalSize</td><td>$freeSpace</td></tr>"
}

$shareTableRow = ""
Get-WmiObject Win32_Share | ForEach-Object {
    $name = $_.Name
    $path = $_.Path
    $description = $_.Description
    $shareTableRow += "<tr><td>$name</td><td>$path</td><td>$description</td></tr>"
}

$pagefileTableRow = "<tr><td>$(Get-GB -Size $($pagefile.InitialSize))</td></tr>"

$ethernetTableRow = ""
Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled='True'" | ForEach-Object {
    $name = $_.Caption
    $macAddress = $_.MACAddress
    $ipAddress = $_.IPAddress[0]
    $subnetMask = $_.IPSubnet[0]
    $defaultGateway = $_.DefaultIPGateway[0]
    $ethernetTableRow += "<tr><td>$name</td><td>$macAddress</td><td>$ipAddress</td><td>$subnetMask</td><td>$defaultGateway</td></tr>"
}

$rolesTableRow = ""
Get-WindowsFeature | Where-Object { $_.Installed -eq "True" } | ForEach-Object {
    $name = $_.Name
    $installed = $_.Installed
    $rolesTableRow += "<tr><td>$name</td><td>$installed</td></tr>"
}

$iisTableRow = ""
Get-ChildItem -Path IIS:\Sites | ForEach-Object {
    $name = $_.Name
    $id = $_.ID
    $physicalPath = $_.PhysicalPath
    $state = $_.State
    $iisTableRow += "<tr><td>$name</td><td>$id</td><td>$physicalPath</td><td>$state</td></tr>"
}

$softwareTableRow = ""
Get-WmiObject Win32_Product | ForEach-Object {
    $name = $_.Name
    $version = $_.Version
    $softwareTableRow += "<tr><td>$name</td><td>$version</td></tr>"
}

$servicesTableRow = ""
Get-Service | Select-Object Name, DisplayName, StartType, @{Name="Account"; Expression={(Get-WmiObject -Class Win32_Service -Filter "Name='$($_.Name)'").StartName}} | ForEach-Object {
    $name = $_.Name
    $displayName = $_.DisplayName
    $startType = $_.StartType
    $account = $_.Account
    $servicesTableRow += "<tr><td>$name</td><td>$displayName</td><td>$startType</td><td>$account</td></tr>"
}

$tasksTableRow = ""
Get-ScheduledTask | ForEach-Object {
    $name = $_.TaskName
    $path = $_.TaskPath
    $state = $_.State
    $lastRunTime = $_.LastRunTime
    $nextRunTime = $_.NextRunTime
    $tasksTableRow += "<tr><td>$name</td><td>$path</td><td>$state</td><td>$lastRunTime</td><td>$nextRunTime</td></tr>"
}

# Define HTML content
$htmlContent = $htmlTableHeaders
$htmlContent += $osHeader
$htmlContent += "<table>$osTableHeaders$osTableRow</table>"
$htmlContent += $memoryHeader
$htmlContent += "<table>$memoryTableHeaders$memoryTableRow</table>"
$htmlContent += $cpuHeader
$htmlContent += "<table>$cpuTableHeaders$cpuTableRow</table>"
$htmlContent += $diskHeader
$htmlContent += "<table>$diskTableHeaders$diskTableRow</table>"
$htmlContent += $shareHeader
$htmlContent += "<table>$shareTableHeaders$shareTableRow</table>"
$htmlContent += $pagefileHeader
$htmlContent += "<table>$pagefileTableHeaders$pagefileTableRow</table>"
$htmlContent += $ethernetHeader
$htmlContent += "<table>$ethernetTableHeaders$ethernetTableRow</table>"
$htmlContent += $ipconfigHeader
$htmlContent += "<table>$(ipconfig /all)</table>"
$htmlContent += $rolesHeader
$htmlContent += "<table>$rolesTableHeaders$rolesTableRow</table>"
$htmlContent += $iisHeader
$htmlContent += "<table>$iisTableHeaders$iisTableRow</table>"
$htmlContent += $softwareHeader
$htmlContent += "<table>$softwareTableHeaders$softwareTableRow</table>"
$htmlContent += $servicesHeader
$htmlContent += "<table>$servicesTableHeaders$servicesTableRow</table>"
$htmlContent += $tasksHeader
$htmlContent += "<table>$tasksTableHeaders$tasksTableRow</table>"

# Save HTML content to file
$htmlContent | Out-File -FilePath $htmlFilePath -Encoding UTF8


