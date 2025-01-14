# Remediation script for NewOutlookMigrationUserSetting.
# Make sure the remediation is run in the 64-bit PowerShell host so as to prevent the key being created under the (wrong) Wow6432Node.

# Get the current user's SID
$SID = (New-Object -ComObject Microsoft.DiskQuota).TranslateLogonNameToSID((Get-CimInstance -ClassName Win32_ComputerSystem).Username)

If([string]::IsNullOrEmpty($SID)) {
    Write-Warning "NewOutlookMigrationUserSetting: no user currently logged in. Exiting."
    Exit 0
} else {
    # Add the HKU drive since this is not mapped by default
    New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null

    $Path = "registry::HKU\$SID\Software\Policies\Microsoft\Office\16.0\Outlook\Preferences"
    $Name = "NewOutlookMigrationUserSetting"

    New-ItemProperty -Path $Path -Name $Name -Value 0 -PropertyType DWORD -Force
    Write-Host "Remediation: added NewOutlookMigrationUserSetting with value 0."
    
    Write-Host "Remediation: performing clean up."
    # Clean up
    Remove-PSDrive -Name HKU
}
