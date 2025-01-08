$Path = "HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Preferences"
$Name = "NewOutlookMigrationUserSetting"

If(!(Test-Path $Path)) {
    New-Item -Path $Path -Force
}

New-ItemProperty -Path $Path -Name $Name -Value 0 -PropertyType DWORD -Force
Write-Host "Remediation: added NewOutlookMigrationUserSetting with value 0."
