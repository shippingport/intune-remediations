# Get all installed programs by searching the registry
[array]$InstalledPrograms = $null
$InstalledPrograms += Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
$InstalledPrograms += Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
$InstalledPrograms += Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall"

Write-Host "Checking for installed Java software..."

$result = $InstalledPrograms | Select-Object DisplayName,UninstallString | Where-Object -Property DisplayName -Like "Java*"

$script:msiexec = "$env:windir\System32\msiexec.exe"

# Uninstall the programs using their UninstallStrings.
ForEach($Program in $result) {
    if(!([string]::IsNullOrEmpty($Program.UninstallString))) {
        # Use regex to extract the GUID from the UninstallString
        $Regex = "{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}"
        $GUID = (Select-String -InputObject $Program.UninstallString -Pattern $Regex -AllMatches).Matches.Value

        # Uninstall by calling CMD, which seems to work more reliably than using Start-Process
        cmd /c "msiexec.exe /x $GUID /qn"
    } else {
        # The Java Auto Updater does not always include an uninstallstring, because it's special like that.
        # This GUID should uninstall it though.
        cmd /c "msiexec.exe /x {4A03706F-666A-4037-7777-5F2748764D10} /qn"
    }    
}
