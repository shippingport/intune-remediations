$scriptContent = { 
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -erroraction silentlycontinue | out-null
    $ProtocolHandler = Get-Item 'HKCR:\ToastReboot' -erroraction 'silentlycontinue'
    if (($ProtocolHandler)) {
        New-item 'HKCR:\ToastReboot' -force
        Set-ItemProperty 'HKCR:\ToastReboot' -name '(DEFAULT)' -value 'url:ToastReboot' -force
        Set-ItemProperty 'HKCR:\ToastReboot' -name 'URL Protocol' -value '' -force
        New-ItemProperty -path 'HKCR:\ToastReboot' -propertytype dword -name 'EditFlags' -value 2162688
        New-item 'HKCR:\ToastReboot\Shell\Open\command' -force
        Set-ItemProperty 'HKCR:\ToastReboot\Shell\Open\command' -name '(DEFAULT)' -value 'shutdown.exe /r /t 60 /c "Your computer will reboot in 1 minute."' -force
    }

    # Check is PSGallery is trusted
    $repo = Get-PSRepository | Where-Object -Property Name -eq "PSGallery"
    if ($repo.InstallationPolicy -eq "Untrusted") {
        Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
    }

    # Check if required modules are installed and available
    if(!(Get-Module -Name BurntToast)) {
        Install-Module -Name BurntToast -AllowClobber -Force
    }
    if(!(Get-Module -Name RunAsUser)) {
        Install-Module -Name RunAsUser -AllowClobber -Force
    }

    Invoke-AsCurrentUser -ScriptBlock {
        $heroimage = New-BTImage -Source 'https://somedomain.com/image.gif' -HeroImage
        $Text1 = New-BTText -Content "IT Department"
        $Text2 = New-BTText -Content "Your computer has been on for more than 7 days. To ensure proper operation, please reboot your computer soon.`nOr remind me later:"
        $Button = New-BTButton -Content "Remind me later" -snooze -id 'SnoozeTime'
        $Button2 = New-BTButton -Content "Reboot now" -Arguments "ToastReboot:" -ActivationType Protocol
        $5Min = New-BTSelectionBoxItem -Id 5 -Content 'In 5 minutes'
        $10Min = New-BTSelectionBoxItem -Id 10 -Content 'Remind me in 10 minutes'
        $1Hour = New-BTSelectionBoxItem -Id 60 -Content 'In 1 hour'
        $4Hours = New-BTSelectionBoxItem -Id 240 -Content 'In 4 hours'
        $Items = $5Min, $10Min, $1Hour, $4Hours
        $SelectionBox = New-BTInput -Id 'SnoozeTime' -DefaultSelectionBoxItemId 10 -Items $Items
        $action = New-BTAction -Buttons $Button, $Button2 -inputs $SelectionBox
        $Binding = New-BTBinding -Children $text1, $text2 -HeroImage $heroimage
        $Visual = New-BTVisual -BindingGeneric $Binding
        $Content = New-BTContent -Visual $Visual -Actions $action
        Submit-BTNotification -Content $Content -AppId '<yourappidhere>'
    }

    # Set PSGallery back to previous state
    Set-PSRepository -Name "PSGallery" -InstallationPolicy $repo.InstallationPolicy

    Start-Sleep -Seconds 14400
    shutdown.exe /r /t 60 /c "Your computer will reboot in 1 minute."
}

$dirPath = "$env:windir\IT\Scripts\Remediations"

if(!(Test-Path -Path $env:windir\IT\Scripts\Remediations)) {
    New-Item -ItemType Directory -Path $dirPath -ErrorAction Stop
    $scriptContent | Out-File $dirPath\Uptime-Remediation.ps1
}

Start-Process powershell.exe -ArgumentList $dirPath\Uptime-Remediation.ps1 -WindowStyle hidden

# No longer required since rewrite, but can still be used if you edit this above to start using some PS7 exclusive functions...
# Check if running with PowerShell 7 or higher
# if ($PSVersionTable.PSVersion.Major -eq '5') {
#     # Running in PS5, relaunch to pswh
#     Start-Process pwsh.exe -ArgumentList $dirPath\Uptime-Remediation.ps1
# } elseif ($PSVersionTable.PSVersion -ge '7') {
#     Start-Process pwsh.exe -ArgumentList $dirPath\Uptime-Remediation.ps1
# } else {
#     Write-Error -Message 'Something went wrong: cannot determine what to do with this PowerShell version: $PSVersionTable.PSVersion.'
# }
