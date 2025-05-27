# Get all installed programs by searching the registry
[array]$InstalledPrograms = $null
$script:InstalledPrograms += Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
$script:InstalledPrograms += Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
$script:msiexec = "$env:windir\System32\msiexec.exe"

Function Uninstall-Program($Package) {
    $TargetApp = $InstalledPrograms | Select-Object DisplayName,UninstallString | Where-Object -Property DisplayName -Like $Package.Name

    if(!([string]::IsNullOrEmpty($TargetApp.UninstallString))) {
        # Use regex to extract the GUID from the UninstallString
        $Regex = "{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}"
        $GUID = (Select-String -InputObject $TargetApp.UninstallString -Pattern $Regex -AllMatches).Matches.Value
    
        # Uninstall by calling CMD, which seems to work more reliably than using Start-Process
        cmd /c "msiexec.exe /x $GUID /qn"
    } else {
        Write-Error -Message "UninstallString malformed or not present for application" $Package.Name
    }
}

$Packages = Get-Package -AllVersions

Foreach($Package in $Packages) {
    If($Package.Name -match "HP Security Update Service*") {
        # Need to uninstall this first, otherwise it might just redownload Wolf Security while we're trying to uninstall
        # All of these should be MSIs.
        Write-Host "HP Security uninstall script: uninstalling package" $package.Name
        Uninstall-Program($Package)
    }
    elseif($Package.Name -match "HP Wolf*") {
        # uninstall that shit
        Write-Host "HP Security uninstall script: uninstalling package" $package.Name
        Uninstall-Program($Package)
    }
    elseif($Package.Name -match "HP Sure*") {
        # uninstall that shit
        Write-Host "HP Security uninstall script: uninstalling package" $package.Name
        Uninstall-Program($Package)
    }
    elseif($Package.Name -match "HP Notifications") {
        # Might as well uninstall this while we're at it
        Write-Host "HP Security uninstall script: uninstalling package" $package.Name
        Uninstall-Program($Package)
    }
    elseif($Package.Name -match "HP Insights") {
        # Same here
        Write-Host "HP Security uninstall script: uninstalling package" $package.Name
        Uninstall-Program($Package)
    }
}
