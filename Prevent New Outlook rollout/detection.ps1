# Detection script for NewOutlookMigrationUserSetting.
# Run the script as the system user.

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

    If((Get-Item -Path $Path).Property -Contains $Name) {
        # Path exits, check its value
        $Result = Get-ItemProperty -Path $Path -Name $Name
        $Result = $Result.NewOutlookMigrationUserSetting
    
        If($Result -ne 0) {
            Write-Warning "Not compliant: NewOutlookMigrationUserSetting is not correctly, value is currently: $Result. Run remediation."
            Write-Host "Exit 0"
            #Exit 0
        } else {
            Write-Host "Compliant: NewOutlookMigrationUserSetting is set correctly."
            Write-Host "Exit 1"
            Exit 1
        }
    } else {
        #false
        Write-Warning "Not compliant: NewOutlookMigrationUserSetting does not exist. Run remediation."
        Write-Host "Exit 0"
        Exit 1
    }
}
