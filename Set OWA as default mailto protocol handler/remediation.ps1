$Path = "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\mailto\UserChoice"
$ProgId = "MSEdgeHTM"
$Hash = "JeUgSvhYYDw="
 
if(!(Test-Path $Path)) {
    New-Item -Path $Path -Force | Out-Null
    New-ItemProperty -Path $Path -Name "ProgId" -Value $ProgId -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $Path -Name "Hash" -Value $Hash -PropertyType String -Force | Out-Null
} else {
    New-ItemProperty -Path $Path -Name "ProgId" -Value $ProgId -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $Path -Name "Hash" -Value $Hash -PropertyType String -Force | Out-Null
}
