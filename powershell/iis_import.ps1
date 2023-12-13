# IIS Import

# Set variables
$ImportPath = "C:\ImportedSite\MySite.zip"
$EncryptionPassword = "MySecurePassword"

# Import the site
Import-WebPackage -Package $ImportPath -EncryptPassword $EncryptionPassword