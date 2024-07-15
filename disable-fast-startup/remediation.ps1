$Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
$Name = "HiberbootEnabled"
$Value = "0"
 
if(!(Test-Path $Path)) {
    New-Item -Path $Path -Force | Out-Null
    New-ItemProperty -Path $Path -Name $Name -Value $value -PropertyType DWORD -Force | Out-Null
} else {
    Set-ItemProperty -Path $Path -Name $Name -Value $value -Force | Out-Null
}
