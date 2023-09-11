# Get all installed programs by searching the registry
[array]$InstalledPrograms = $null
$InstalledPrograms += Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
$InstalledPrograms += Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
$InstalledPrograms += Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall"

Write-Host "Checking for TeamViewer..."

$result = $InstalledPrograms | Select-Object DisplayName | Where-Object -Property DisplayName -Like "TeamViewer*"

if(!($result.Count -eq 0)) {
    Write-Host "TeamViewer was found!"
    Exit 1
} Else {
    Write-Output "TeamViewer was NOT found."
    Exit 0
}