# IIS Export


# Set variables
$SiteName = "MySite"
$ExportPath = "C:\ExportedSite\MySite.zip"
$EncryptionPassword = "MySecurePassword"

# Export the site
$Site = Get-WebSite -Name $SiteName
$SiteId = $Site.ID
$SiteBinding = Get-WebBinding -Name $SiteName
$SiteAppPool = $Site.applicationPool
Export-WebPackage -Site $SiteId -Package $ExportPath -AppPool $SiteAppPool -EncryptPassword $EncryptionPassword