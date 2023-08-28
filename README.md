# intune-remediations

These are some remediations I use frequently in Intune/Microsoft Endpoint Manager.

## Remediations included

### Toast-uptime-remediation
Sends a toast notification using BurntToast to the currently logged in user that their computer's uptime has exceeded 7 days. The toast notification allows the user to snooze for up to 4 hours, and forces a reboot after that.
Requires PowerShell 5.1 or later.

The function *Invoke-AsCurrentUser* from the PS module *RunAsUser* requires running as NT AUTHORITY\SYSTEM. You can use the SysInternals utility PsExec to run PowerShell as this user for testing purposes, eg.:

`Start-Process -FilePath cmd.exe -Verb Runas -ArgumentList '/k C:\SysinternalsSuite\PsExec.exe -i -s powershell.exe $env:psscriptdev\intune\remediations\toast-uptime-remediation\remediation.ps1'`

### Set Outlook Web Access (OWA) as default mailto-protocol handler
This is a two parter.
First, add the following protocol handler to your Microsoft Edge policy using either Intune or a GPO:

1. Under "Microsoft Edge - Default Settings (users can override)" add Register protocol handlers (Device).
2. The handler to add is:
```
[
  {
    "default": true,
    "protocol": "mailto",
    "url": "https://outlook.office.com/owa/?&rru=compose&to=%s"
  }
]
```
Then add the remediation using the files provided. Set *Run this script using the logged-on credentials* to Yes/True.
