<#
.SYNOPSIS
Mount a registry hive.
.DESCRIPTION
Mount a hive to the registry.
Return the destination in the registry where the hive was mounted.

If the *DefaultUser* parameter is provided, then all other parameters are discarded.
.OUTPUTS
[Microsoft.Win32.RegistryKey]
.PARAMETER FilePath
The path to the hive file.

If the *DefaultUser* parameter is provided, then this parameter is discarded.
.PARAMETER Hive
Registry location where to mount the hive.
If `{0}` is provided, a formatter will provide some randomness to the location.

If the *DefaultUser* parameter is provided, then this parameter is discarded.
.PARAMETER DefaultUser
Optionally, provide just this switch to mount the Default User hive.
.EXAMPLE
$hive = Mount-RegistryHive -DefaultUser
.EXAMPLE
$hive = Mount-RegistryHive -FilePath 'C:\Temp\NTUSER.DAT'
.EXAMPLE
$hive = Mount-RegistryHive -FilePath 'C:\Temp\NTUSER.DAT' -Hive 'HKEY_USERS\TEMP'
.EXAMPLE
$hive = Mount-RegistryHive -FilePath 'C:\Temp\NTUSER.DAT' -Hive 'HKEY_USERS\THING{0}'
#>
function Mount-RegistryHive ([IO.FileInfo] $FilePath, [string] $Hive = 'HKEY_USERS\TEMP{0}', [switch] $DefaultUser, [switch] $DoNotAutoDismount) {
    if ($DefaultUser.IsPresent) {
        $defaultp = (Get-ItemProperty 'registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList').Default

        [IO.FileInfo] $FilePath = [IO.Path]::Combine($defaultp, 'NTUSER.DAT')
        [string] $Hive = 'HKEY_USERS\DEFAULT'
        while (Test-Path ('Registry::{0}' -f $Hive)) {
            [string] $Hive = 'HKEY_USERS\DEFAULT{0}' -f (New-Guid).Guid.Split('-')[0]
        }
    }

    if (-not $FilePath.Exists) {
        Throw [System.IO.FileNotFoundException] ('Provided FilePath not found: {0}' -f $FilePath.FullName)
    }

    if ($Hive -like '*{0}*') {
        [string] $hiveF = $Hive -f (New-Guid).Guid.Split('-')[0]
        while (Test-Path ('Registry::{0}' -f  $hiveF)) {
            [string] $hiveF = $Hive -f (New-Guid).Guid.Split('-')[0]
        }
        $Hive = $hiveF
    }

    if (Test-Path $Hive) {
        Throw ('Hive location already in use: {0}' -f $Hive)
    }

    $regLoad = @{
        FilePath = (Get-Command 'reg.exe').Source
        ArgumentList = @(
            'LOAD'
            $Hive
            $FilePath.FullName
        )
    }
    $result = Invoke-Run $regLoad

    if (-not $DoNotAutoDismount.IsPresent) {
        Register-EngineEvent 'PowerShell.Exiting' -SupportEvent -Action {
            Dismount-RegistryHive -Hive $Hive
        }
    }

    if ($result.Process.ExitCode) {
        # Non-Zero Exit Code
        Throw ($result.StdErr | Out-String)
    } else {
        return (Get-Item ('Registry::{0}' -f $defaultHive))
    }
}