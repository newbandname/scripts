# Variables
$sourceDir = "C:\path\to\your\ebs\volume"
$s3Bucket = "s3://your-bucket-name"
$logDir = "C:\path\to\logs"
$maxConcurrentRequests = 100
$maxQueueSize = 1000
$numProcesses = 8

# Configure AWS CLI for higher concurrency
aws configure set default.s3.max_concurrent_requests $maxConcurrentRequests
aws configure set default.s3.max_queue_size $maxQueueSize

# Function to sync a subdirectory
function Sync-Subdir {
    param (
        [string]$Subdir,
        [string]$LogFile
    )
    aws s3 sync $Subdir "s3://your-bucket-name/$($Subdir -replace '\\', '/')" --endpoint-url https://s3-accelerate.amazonaws.com --storage-class STANDARD_IA --delete --exact-timestamps --only-show-errors > $LogFile 2>&1
}

# Get all subdirectories
$subdirs = Get-ChildItem -Path $sourceDir -Directory

$jobs = @()

foreach ($subdir in $subdirs) {
    $logFile = "$logDir\sync_$($subdir.Name -replace '[\\/:*?""<>|]', '_').log"
    $jobs += Start-Job -ScriptBlock {
        param ($subdir, $logFile)
        aws s3 sync $subdir.FullName "s3://your-bucket-name/$($subdir.Name -replace '\\', '/')" --endpoint-url https://s3-accelerate.amazonaws.com --storage-class STANDARD_IA --delete --exact-timestamps --only-show-errors > $logFile 2>&1
    } -ArgumentList $subdir, $logFile
    
    if ($jobs.Count -ge $numProcesses) {
        Receive-Job -Job $jobs
        $jobs = @()
    }
}

# Wait for remaining jobs to complete
$jobs | ForEach-Object { Receive-Job -Job $_ }
