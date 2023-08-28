$Path = "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\mailto\UserChoice"
$Name = "ProgId"
$Result = Get-ItemProperty -Path $Path -Name $Name

if($Result.ProgId -eq 'MSEdgeHTM') {
    Write-Warning "Compliant: mailto assoc is set to MSEdgeHTM."
    Exit 0
} else {
    Write-Output "Not compliant: default mailto assoc is not set to Edge. Running remediation."
    Exit 1
}
