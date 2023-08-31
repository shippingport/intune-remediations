# Get all installed programs by searching the registry
[array]$InstalledPrograms = $null
$InstalledPrograms += Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
$InstalledPrograms += Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
$InstalledPrograms += Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall"

Write-Host "Checking for installed Java software..."

$result = $InstalledPrograms | Select-Object DisplayName | Where-Object -Property DisplayName -Like "Java*"

if(!($result.Count -eq 0)) {
    Write-Host "Java apps were found:" $result.DisplayName
    Exit 1
} Else {
    Write-Output "No Java apps were found."
    Exit 0
}
