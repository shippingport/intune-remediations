$Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
$Name = "HiberbootEnabled"
$Result = Get-ItemProperty -Path $Path -Name $Name

if($Result.HiberbootEnabled -eq '1') {
    Write-Warning "Not compliant: hiberboot is set to enabled. Run remediation."
    Exit 1
} elseif ($Result.HiberbootEnabled -eq '0') {
    Write-Output "Compliant: hiberboot is disabled."
    Exit 0
} else {
    Write-Error "Hiberboot status was not 0 or 1. DWORD content was:" $Result.HiberbootEnabled
    Exit 1
}
