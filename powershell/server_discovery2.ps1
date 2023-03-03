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
    <table>
    <thead>
        <tr>
            <th>Computer Name</th>
            <th>OS Information</th>
            <th>Memory Info (GB)</th>
            <th>CPU Info</th>
            <th>Logical Disk Info (GB)</th>
            <th>File Share Info</th>
            <th>Page File Info (GB)</th>
            <th>Network Interfaces Info</th>
            <th>IPConfig/All Info</th>
            <th>Roles and Features Installed</th>
            <th>IIS Site Configurations</th>
            <th>All Software Installed</th>
            <th>Services Installed</th>
            <th>List of Administrator Accounts</th>
            <th>Scheduled Tasks</th>
        </tr>
    </thead>
    <tbody>
"@

# Define HTML table footer
$htmlTableFooter = @"
    </tbody>
    </table>
"@

# Define table row data
$htmlTableRow = @"
        <tr>
            <td>$computerName</td>
            <td>$(Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version)</td>
            <td>$(Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum | Select-Object @{Name="Size";Expression={Get-GB $_.Sum}}).Size</td>
            <td>$(Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors)</td>
            <td>$((Get-CimInstance Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | Measure-Object Size -Sum | Select-Object @{Name="Size";Expression={Get-GB $_.Sum}}).Size)</td>
            <td>$(Get-SmbShare | Select-Object Name, Path, Description)</td>
            <td>$(Get-CimInstance Win32_PageFileUsage | Select-Object @{Name="Size";Expression={Get-GB $_.AllocatedBaseSize}}).Size</td>
            <td>$(Get-NetAdapter | Select-Object Name, InterfaceDescription, MacAddress, Status)</td>
            <td>$(ipconfig /all)</td>
            <td>$(Get-WindowsFeature | Where-Object {$_.Installed -eq $true} | Select-Object Name, Installed)</td>
            <td>$(Get-Website | Select-Object Name, ID, PhysicalPath, State)</td>
            <td>$(Get-Package | Select-Object Name, Version)</td>
            <td>$(Get-Service | Select-Object Name
            ,@{Name="StartType";Expression={$_.StartMode}}
            ,@{Name="Account";Expression={Get-ServiceAccount $_.Name}})</td>
            <td>$(Get-LocalGroupMember -Group "Administrators" | Select-Object Name)</td>
            <td>$(Get-ScheduledTask | Select-Object TaskName, TaskPath, State, LastRunTime, NextRunTime)</td>
        </tr>
"@

# Get all data for the HTML table
$htmlTableData = $htmlTableHeaders + $htmlTableRow + $htmlTableFooter

# Export data to an HTML file
$htmlTableData | Out-File -FilePath $htmlFilePath

