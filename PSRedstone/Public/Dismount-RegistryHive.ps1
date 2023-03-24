<#
.SYNOPSIS
Dismount a registry hive.
.DESCRIPTION
Dismount a hive to the registry.
.OUTPUTS
[void]
.PARAMETER Hive
The key object returned from `Mount-RegistryHive`.
.EXAMPLE
Dismount-RegistryHive -Hive $hive

Where `$hive` was created with:

```powershell
$hive = Mount-RegistryHive -DefaultUser
```
#>
function Dismount-RegistryHive ([Microsoft.Win32.RegistryKey] $Hive) {
    # Garbage Collection
    [gc]::Collect()

    $regLoad = @{
        FilePath = (Get-Command 'reg.exe').Source
        ArgumentList = @(
            'UNLOAD'
            $Hive
        )
    }
    $result = Invoke-Run $regLoad

    if ($result.Process.ExitCode) {
        # Non-Zero Exit Code
        Throw ($result.StdErr | Out-String)
    } else {
        return (Get-Item ('Registry::{0}' -f $defaultHive))
    }
}