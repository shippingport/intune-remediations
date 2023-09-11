# Get all installed programs by searching the registry
[array]$InstalledPrograms = $null
$InstalledPrograms += Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
$InstalledPrograms += Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"

# In order to detect programs installed as CurrentUser, make sure to check "Run this script using the logged-on credentials" in Intune.
# Also comment or remove the two lines referencing HKEY_LOCAL_MACHINE, since CurrentUser obviously can't uninstall machine-level installs unless they have local admin (which they shouldn't have!)
# Then uncomment the line below. Also make sure to add a check for Wow6432Node.
#$InstalledPrograms += Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall"

Write-Host "Checking for TeamViewer..."

$result = $InstalledPrograms | Select-Object DisplayName,UninstallString | Where-Object -Property DisplayName -Like "TeamViewer*"

$script:msiexec = "$env:windir\System32\msiexec.exe"

# Uninstall the program(s) using their UninstallStrings.
ForEach($Program in $result) {
    if(!([string]::IsNullOrEmpty($Program.UninstallString))) {
        # Use regex to extract the GUID from the UninstallString
        $Regex = "{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}"
        $GUID = (Select-String -InputObject $Program.UninstallString -Pattern $Regex -AllMatches).Matches.Value

        # Uninstall by calling CMD, which seems to work more reliably than using Start-Process
        cmd /c "msiexec.exe /x $GUID /qn"
    } else {
        Write-Error -Message "Could not uninstall TeamViewer: could not locate GUID. Please check the logs for more information."
    }    
}