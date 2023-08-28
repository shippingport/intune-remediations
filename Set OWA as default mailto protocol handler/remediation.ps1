<#
        .SYNOPSIS
        This remediation adds the protocol handler for mailto to the HKCU registry, and generates the nessecary hash so Windows won't reset this app association.
        The hash function was recycled with minor modifications from https://github.com/DanysysTeam/PS-SFTA/.

#>

$Path = "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\mailto\UserChoice"
$ProgId = "MSEdgeHTM"

function Get-HashForProtocolMapping() {
    # This seems to be just about the only reliable way of fiding a user SID when Azure AD joined... Not perfect, but it works.
    $SIDPreRegex = whoami /user
    $SIDPostRegex = [regex]::Match($SIDPreRegex,'([A-Za-z0-9]+(-[A-Za-z0-9]+)+)').Groups[1].Value

    function Get-HexDateTime {
        [OutputType([string])]

        $now = [DateTime]::Now
        $dateTime = [DateTime]::New($now.Year, $now.Month, $now.Day, $now.Hour, $now.Minute, 0)
        $fileTime = $dateTime.ToFileTime()
        $hi = ($fileTime -shr 32)
        $low = ($fileTime -band 0xFFFFFFFFL)
        $dateTimeHex = ($hi.ToString("X8") + $low.ToString("X8")).ToLower()
        Write-Output $dateTimeHex
      }

    function Get-UserExperience {
        [OutputType([string])]
        $hardcodedExperience = "User Choice set via Windows User Experience {D18B6DD5-6124-4341-9318-804003BAFA0B}"
        $userExperienceSearch = "User Choice set via Windows User Experience"
        $userExperienceString = ""
        $user32Path = [Environment]::GetFolderPath([Environment+SpecialFolder]::SystemX86) + "\Shell32.dll"
        $fileStream = [System.IO.File]::Open($user32Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $binaryReader = New-Object System.IO.BinaryReader($fileStream)
        [Byte[]] $bytesData = $binaryReader.ReadBytes(5mb)
        $fileStream.Close()
        $dataString = [Text.Encoding]::Unicode.GetString($bytesData)
        $position1 = $dataString.IndexOf($userExperienceSearch)
        $position2 = $dataString.IndexOf("}", $position1)
        try {
          $userExperienceString = $dataString.Substring($position1, $position2 - $position1 + 1)
        }
        catch {
          $userExperienceString = $hardcodedExperience
        }
        Write-Output $userExperienceString
      }

      function Get-Hash {
        [CmdletBinding()]
        param (
          [Parameter( Position = 0, Mandatory = $True )]
          [string]
          $BaseInfo
        )

        function Get-ShiftRight {
          [CmdletBinding()]
          param (
            [Parameter( Position = 0, Mandatory = $true)]
            [long] $iValue, 

            [Parameter( Position = 1, Mandatory = $true)]
            [int] $iCount 
          )
        
          if ($iValue -band 0x80000000) {
            Write-Output (( $iValue -shr $iCount) -bxor 0xFFFF0000)
          }
          else {
            Write-Output  ($iValue -shr $iCount)
          }
        }


        function Get-Long {
          [CmdletBinding()]
          param (
            [Parameter( Position = 0, Mandatory = $true)]
            [byte[]] $Bytes,
        
            [Parameter( Position = 1)]
            [int] $Index = 0
          )
        
          Write-Output ([BitConverter]::ToInt32($Bytes, $Index))
        }


        function Convert-Int32 {
          param (
            [Parameter( Position = 0, Mandatory = $true)]
            [long] $Value
          )
        
          [byte[]] $bytes = [BitConverter]::GetBytes($Value)
          return [BitConverter]::ToInt32( $bytes, 0) 
        }

        [Byte[]] $bytesBaseInfo = [System.Text.Encoding]::Unicode.GetBytes($baseInfo) 
        $bytesBaseInfo += 0x00, 0x00  

        $MD5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
        [Byte[]] $bytesMD5 = $MD5.ComputeHash($bytesBaseInfo)

        $lengthBase = ($baseInfo.Length * 2) + 2 
        $length = (($lengthBase -band 4) -le 1) + (Get-ShiftRight $lengthBase  2) - 1
        $base64Hash = ""

        if ($length -gt 1) {
        
          $map = @{PDATA = 0; CACHE = 0; COUNTER = 0 ; INDEX = 0; MD51 = 0; MD52 = 0; OUTHASH1 = 0; OUTHASH2 = 0;
            R0 = 0; R1 = @(0, 0); R2 = @(0, 0); R3 = 0; R4 = @(0, 0); R5 = @(0, 0); R6 = @(0, 0); R7 = @(0, 0)
          }
      
          $map.CACHE = 0
          $map.OUTHASH1 = 0
          $map.PDATA = 0
          $map.MD51 = (((Get-Long $bytesMD5) -bor 1) + 0x69FB0000L)
          $map.MD52 = ((Get-Long $bytesMD5 4) -bor 1) + 0x13DB0000L
          $map.INDEX = Get-ShiftRight ($length - 2) 1
          $map.COUNTER = $map.INDEX + 1
      
          while ($map.COUNTER) {
            $map.R0 = Convert-Int32 ((Get-Long $bytesBaseInfo $map.PDATA) + [long]$map.OUTHASH1)
            $map.R1[0] = Convert-Int32 (Get-Long $bytesBaseInfo ($map.PDATA + 4))
            $map.PDATA = $map.PDATA + 8
            $map.R2[0] = Convert-Int32 (($map.R0 * ([long]$map.MD51)) - (0x10FA9605L * ((Get-ShiftRight $map.R0 16))))
            $map.R2[1] = Convert-Int32 ((0x79F8A395L * ([long]$map.R2[0])) + (0x689B6B9FL * (Get-ShiftRight $map.R2[0] 16)))
            $map.R3 = Convert-Int32 ((0xEA970001L * $map.R2[1]) - (0x3C101569L * (Get-ShiftRight $map.R2[1] 16) ))
            $map.R4[0] = Convert-Int32 ($map.R3 + $map.R1[0])
            $map.R5[0] = Convert-Int32 ($map.CACHE + $map.R3)
            $map.R6[0] = Convert-Int32 (($map.R4[0] * [long]$map.MD52) - (0x3CE8EC25L * (Get-ShiftRight $map.R4[0] 16)))
            $map.R6[1] = Convert-Int32 ((0x59C3AF2DL * $map.R6[0]) - (0x2232E0F1L * (Get-ShiftRight $map.R6[0] 16)))
            $map.OUTHASH1 = Convert-Int32 ((0x1EC90001L * $map.R6[1]) + (0x35BD1EC9L * (Get-ShiftRight $map.R6[1] 16)))
            $map.OUTHASH2 = Convert-Int32 ([long]$map.R5[0] + [long]$map.OUTHASH1)
            $map.CACHE = ([long]$map.OUTHASH2)
            $map.COUNTER = $map.COUNTER - 1
          }

          [Byte[]] $outHash = @(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
          [byte[]] $buffer = [BitConverter]::GetBytes($map.OUTHASH1)
          $buffer.CopyTo($outHash, 0)
          $buffer = [BitConverter]::GetBytes($map.OUTHASH2)
          $buffer.CopyTo($outHash, 4)
      
          $map = @{PDATA = 0; CACHE = 0; COUNTER = 0 ; INDEX = 0; MD51 = 0; MD52 = 0; OUTHASH1 = 0; OUTHASH2 = 0;
            R0 = 0; R1 = @(0, 0); R2 = @(0, 0); R3 = 0; R4 = @(0, 0); R5 = @(0, 0); R6 = @(0, 0); R7 = @(0, 0)
          }
      
          $map.CACHE = 0
          $map.OUTHASH1 = 0
          $map.PDATA = 0
          $map.MD51 = ((Get-Long $bytesMD5) -bor 1)
          $map.MD52 = ((Get-Long $bytesMD5 4) -bor 1)
          $map.INDEX = Get-ShiftRight ($length - 2) 1
          $map.COUNTER = $map.INDEX + 1

          while ($map.COUNTER) {
            $map.R0 = Convert-Int32 ((Get-Long $bytesBaseInfo $map.PDATA) + ([long]$map.OUTHASH1))
            $map.PDATA = $map.PDATA + 8
            $map.R1[0] = Convert-Int32 ($map.R0 * [long]$map.MD51)
            $map.R1[1] = Convert-Int32 ((0xB1110000L * $map.R1[0]) - (0x30674EEFL * (Get-ShiftRight $map.R1[0] 16)))
            $map.R2[0] = Convert-Int32 ((0x5B9F0000L * $map.R1[1]) - (0x78F7A461L * (Get-ShiftRight $map.R1[1] 16)))
            $map.R2[1] = Convert-Int32 ((0x12CEB96DL * (Get-ShiftRight $map.R2[0] 16)) - (0x46930000L * $map.R2[0]))
            $map.R3 = Convert-Int32 ((0x1D830000L * $map.R2[1]) + (0x257E1D83L * (Get-ShiftRight $map.R2[1] 16)))
            $map.R4[0] = Convert-Int32 ([long]$map.MD52 * ([long]$map.R3 + (Get-Long $bytesBaseInfo ($map.PDATA - 4))))
            $map.R4[1] = Convert-Int32 ((0x16F50000L * $map.R4[0]) - (0x5D8BE90BL * (Get-ShiftRight $map.R4[0] 16)))
            $map.R5[0] = Convert-Int32 ((0x96FF0000L * $map.R4[1]) - (0x2C7C6901L * (Get-ShiftRight $map.R4[1] 16)))
            $map.R5[1] = Convert-Int32 ((0x2B890000L * $map.R5[0]) + (0x7C932B89L * (Get-ShiftRight $map.R5[0] 16)))
            $map.OUTHASH1 = Convert-Int32 ((0x9F690000L * $map.R5[1]) - (0x405B6097L * (Get-ShiftRight ($map.R5[1]) 16)))
            $map.OUTHASH2 = Convert-Int32 ([long]$map.OUTHASH1 + $map.CACHE + $map.R3) 
            $map.CACHE = ([long]$map.OUTHASH2)
            $map.COUNTER = $map.COUNTER - 1
          }
      
          $buffer = [BitConverter]::GetBytes($map.OUTHASH1)
          $buffer.CopyTo($outHash, 8)
          $buffer = [BitConverter]::GetBytes($map.OUTHASH2)
          $buffer.CopyTo($outHash, 12)
      
          [Byte[]] $outHashBase = @(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
          $hashValue1 = ((Get-Long $outHash 8) -bxor (Get-Long $outHash))
          $hashValue2 = ((Get-Long $outHash 12) -bxor (Get-Long $outHash 4))
      
          $buffer = [BitConverter]::GetBytes($hashValue1)
          $buffer.CopyTo($outHashBase, 0)
          $buffer = [BitConverter]::GetBytes($hashValue2)
          $buffer.CopyTo($outHashBase, 4)
          $base64Hash = [Convert]::ToBase64String($outHashBase) 
        }

        return $base64Hash
      }

    $Extension = "mailto"
    $ProgId = "MSEdgeHTM"
    $userDateTime = Get-HexDateTime
    $userExperience = Get-UserExperience
    $baseInfo = "$Extension$SIDPostRegex$ProgId$userDateTime$userExperience".ToLower()

    $progHash = Get-Hash $baseInfo
    return $progHash
}

$Hash = Get-HashForProtocolMapping
 
if(!(Test-Path $Path)) {
    New-Item -Path $Path -Force | Out-Null
    New-ItemProperty -Path $Path -Name "ProgId" -Value $ProgId -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $Path -Name "Hash" -Value $Hash -PropertyType String -Force | Out-Null
} else {
    New-ItemProperty -Path $Path -Name "ProgId" -Value $ProgId -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $Path -Name "Hash" -Value $Hash -PropertyType String -Force | Out-Null
}
