$Path = "HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Preferences"
$Name = "NewOutlookMigrationUserSetting"

If(Test-Path -Path "$Path\$Name") {
    # true
    $Result = Get-ItemProperty -Path $Path -Name $Name

    If($Result.NewOutlookMigrationUserSetting -ne 0) {
        Write-Warning "Not compliant: NewOutlookMigrationUserSetting is not correctly, value is currently: $Result. Run remediation."
        Exit 0
    } else {
        Write-Host "Compliant: NewOutlookMigrationUserSetting is set correctly."
        Exit 1
    }
} else {
    #false
    Write-Warning "Not compliant: NewOutlookMigrationUserSetting does not exist. Run remediation."
    Exit 1
}
