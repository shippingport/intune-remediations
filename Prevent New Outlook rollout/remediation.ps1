# Remediation script for NewOutlookMigrationUserSetting.

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

    # Check if the path exits or not
    If(Test-Path $Path) {
        # It exists, so just force set the key
        # Forcing here to overwrite existing values, which must be wrong
        New-ItemProperty -Path $Path -Name $Name -Value 0 -PropertyType DWORD -Force
    } else {
        # Create the keys first, then add the dword
        New-Item $Path -Force
        New-ItemProperty -Path $Path -Name $Name -Value 0 -PropertyType DWORD -Force
    }

    Write-Host "Remediation: added NewOutlookMigrationUserSetting with value 0."
    
    Write-Host "Remediation: performing clean up."
    # Clean up
    Remove-PSDrive -Name HKU
}
