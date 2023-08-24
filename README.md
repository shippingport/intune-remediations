# intune-remediations

These are some remediations I use frequently in Intune/Microsoft Endpoint Manager.

## Remediations included

### Toast-uptime-remediation
Sends a toast notification using BurntToast to the currently logged in user that their computer's uptime has exceeded 7 days. The toast notification allows the user to snooze for up to 4 hours, and forces a reboot after that.
Requires PowerShell 5.1 or later.

The function *Invoke-AsCurrentUser* from the PS module *RunAsUser* requires running as NT AUTHORITY\SYSTEM. You can use the SysInternals utility PsExec to run PowerShell as this user for testing purposes, eg.:

`Start-Process -FilePath cmd.exe -Verb Runas -ArgumentList '/k C:\SysinternalsSuite\PsExec.exe -i -s powershell.exe $env:psscriptdev\intune\remediations\toast-uptime-remediation\remediation.ps1'`
