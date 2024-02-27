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

# ... (Other script sections remain the same)

# IP Configuration (Refined)
$html += "<h3>IP Configuration</h2>"
$html += "<pre>" 
$html += (ipconfig /all | Out-String).Trim() 
$html += "</pre>"

# ... (Rest of the script remains the same)

# Close HTML 
$html += "</body></html>"

# Save to file 
$html | Out-File $outputFilePath