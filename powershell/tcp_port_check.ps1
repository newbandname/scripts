# In this script, we create a new TCP client object and try to connect to the specified port on the server. 
# We then wait for the connection to complete and check if it was successful. 
# If the connection was successful, we know that the port is open. Otherwise, the port is closed.

$port = 11024
$ip = "127.0.0.1" # Replace with the IP address of the server you want to check

# Create a new TCP client object
$client = New-Object System.Net.Sockets.TcpClient

# Try to connect to the specified port on the server
$connection = $client.BeginConnect($ip, $port, $null, $null)

# Wait for the connection to complete
$wait = $connection.AsyncWaitHandle.WaitOne(1000, $false)

# Check if the connection was successful
if (!$client.Connected) {
    Write-Host "Port $port is closed"
} else {
    Write-Host "Port $port is open"
}

# Close the connection
$client.Close()