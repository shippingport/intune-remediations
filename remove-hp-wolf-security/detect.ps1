# Detection script for HP Wolf Security

$packages = Get-Package -AllVersions

If($packages.Name -match "HP Wolf*") {
    # run remediation
    #Write-Host "Exit 1"
    exit 1
} else {
    #Write-Host "Exit 0"
    exit 0
}
