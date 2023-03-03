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

function Get-ServiceAccount {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [string]$ServiceName
    )
    process {
        $service = Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'"
        $account = $service.StartName
        return $account
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

$networkHeader = "<h2>Network Information</h2>"
$networkTableHeaders = "<tr><th>Name</th><th>MAC Address</th><th>Status</th></tr>"

$ipconfigHeader = "<h2>IPConfig/All Information</h2>"

$rolesHeader = "<h2>Installed Roles and Features</h2>"
$rolesTableHeaders = "<tr><th>Name</th><th>Installed</th></tr>"

$iisHeader = "<h2>IIS Site Configurations</h2>"
$iisTableHeaders = "<tr><th>Name</th><th>ID</th><th>Physical Path</th><th>State</th></tr>"

$softwareHeader = "<h2>Installed Software</h2>"
$softwareTableHeaders = "<tr><th>Name</th><th>Version</th></tr>"

$servicesHeader = "<h2>Services Installed</h2>"
$servicesTableHeaders = "<tr><th>Name</th><th>Display Name</th><th>Start Type</th><th>Account</th></tr>"

$tasksHeader = "<h2>Scheduled Tasks</h2>"
$tasksTableHeaders = "<tr><th>Task Name</th><th>Task Path</th><th>State</th><th>Last Run Time</th><th>Next Run Time</th></tr>"

# Define table row data
$osTableRow = "<tr><td>$((Get-CimInstance Win32_OperatingSystem).Caption)</td><td>$((Get-CimInstance Win32_OperatingSystem).Version)</td></tr>"

$memoryTableRow = "<tr><td>$(Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum | Select-Object @{Name='Size';Expression={Get-GB $_.Sum}}).Size</td></tr>"

$cpuTableRow = "<tr><td>$((Get-CimInstance Win32_Processor).Name)</td><td>$((Get-CimInstance Win32_Processor).NumberOfCores)</td><td>$((Get-CimInstance Win32_Processor).NumberOfLogicalProcessors)</td></tr>"

$diskTableRow = ""
Get-CimInstance Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | ForEach-Object {
    $diskTableRow += "<tr><td>$($_.DeviceID)</td><td>$($_.Size | Get-GB)</td><td>$($_.FreeSpace | Get-GB)</td></tr>"
}

$shareTableRow = ""
Get-SmbShare | ForEach-Object {
    $shareTableRow += "<tr><td>$($_.Name)</td><td>$($_.Path)</td><td>$($_.Description)</td></tr>"
}

$pagefileTableRow = "<tr><td>$(Get-CimInstance Win32_PageFileUsage | Select-Object @{Name='Size';Expression={Get-GB $_.AllocatedBaseSize}}).Size</td></tr>"

$networkTableRow = ""
Get-NetAdapter | ForEach-Object {
    $networkTableRow += "<tr><td>$($_.Name)</td><td>$($_.MacAddress)</td><td>$($_.Status)</td></tr>"
}

$ipconfigTableRow = "<tr><td><pre>$(ipconfig /all)</pre></td></tr>"

$rolesTableRow = ""
Get-WindowsFeature | Where-Object {$_.Installed -eq $true} | ForEach-Object {
    $rolesTableRow += "<tr><td>$($_.Name)</td><td>$($_.Installed)</td></tr>"
}

$iisTableRow = ""
Get-Website | ForEach-Object {
    $iisTableRow += "<tr><td>$($_.Name)</td><td>$($_.ID)</td><td>$($_.PhysicalPath)</td><td>$($_.State)</td></tr>"
}

$softwareTableRow = ""
Get-Package | ForEach-Object {
    $softwareTableRow += "<tr><td>$($_.Name)</td><td>$($_.Version)</td></tr>"
}

$servicesTableRow = ""
Get-Service | ForEach-Object {
    $servicesTableRow += "<tr><td>$($_.Name)</td><td>$($_.DisplayName)</td><td>$($_.StartType)</td><td>$(Get-ServiceAccount $_.Name)</td></tr>"
}

$tasksTableRow = ""
Get-ScheduledTask | ForEach-Object {
    $tasksTableRow += "<tr><td>$($_.TaskName)</td><td>$($_.TaskPath)</td><td>$($_.State)</td><td>$($_.LastRunTime)</td><td>$($_.NextRunTime)</td></tr>"
}

# Define HTML table footer
$htmlTableFooter = "</table>"

# Define table data for the HTML file
$htmlTableData = $htmlTableHeaders
$htmlTableData += $osHeader + "<table>" + $osTableHeaders + $osTableRow + $htmlTableFooter
$htmlTableData += $memoryHeader + "<table>" + $memoryTableHeaders + $memoryTableRow + $htmlTableFooter
$htmlTableData += $cpuHeader + "<table>" + $cpuTableHeaders + $cpuTableRow + $htmlTableFooter
$htmlTableData += $diskHeader + "<table>" + $diskTableHeaders + $diskTableRow + $htmlTableFooter
$htmlTableData += $shareHeader + "<table>" + $shareTableHeaders + $shareTableRow + $htmlTableFooter
$htmlTableData += $pagefileHeader + "<table>" + $pagefileTableHeaders + $pagefileTableRow + $htmlTableFooter
$htmlTableData += $networkHeader + "<table>" + $networkTableHeaders + $networkTableRow + $htmlTableFooter
$htmlTableData += $ipconfigHeader + "<table>" + $ipconfigTableRow + $htmlTableFooter
$htmlTableData += $rolesHeader + "<table>" + $rolesTableHeaders + $rolesTableRow + $htmlTableFooter
$htmlTableData += $iisHeader + "<table>" + $iisTableHeaders + $iisTableRow + $htmlTableFooter
$htmlTableData += $softwareHeader + "<table>" + $softwareTableHeaders + $softwareTableRow + $htmlTableFooter
$htmlTableData += $servicesHeader + "<table>" + $servicesTableHeaders + $servicesTableRow + $htmlTableFooter
$htmlTableData += $tasksHeader + "<table>" + $tasksTableHeaders + $tasksTableRow + $htmlTableFooter

# Export data to an HTML file
$htmlTableData | Out-File -FilePath $htmlFilePath


