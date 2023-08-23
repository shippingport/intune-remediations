# Check EventLog for last full shutdown
[datetime]$StartUpDate = ((Get-WinEvent -ProviderName 'Microsoft-Windows-Kernel-Boot'| Where-Object {$_.ID -eq 27 -and $_.message -like "*0x0*"} -ea silentlycontinue)[0]).TimeCreated
# Get current date to run a delta against
[datetime]$CurrentDate = Get-Date

$DeltaReboot = New-TimeSpan -Start $StartUpDate -End $CurrentDate

# If the registry value matches the expected value, output "Compliant"
If ($DeltaReboot.Days -ge '7'){
    Write-Warning "Not compliant: uptime limit exceeded! Last full shutdown/reboot at $StartUpDate, last checked at $CurrentDate"
    Exit 1
}
Else {
    Write-Output "Compliant: system uptime less than 7 days: last full shutdown/reboot at $StartUpDate, last checked at $CurrentDate"
    Exit 0
}
