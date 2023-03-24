<#
.SYNOPSIS
Run `Set-ItemProperty` on a mounted registry hive.
.DESCRIPTION
Run `Set-ItemProperty` on a mounted registry hive.
This process is non-trivial as it requires us to close handles after creating keys and do garbage cleanup when we're done.
Doing these extra steps allows unloading/dismounting of the hive.
Return the resulting ItemProperty.
.OUTPUTS
[PSCustomObject]
.PARAMETER Hive
The key object returned from `Mount-RegistryHive`.
.PARAMETER Key
Key path, within the hive, to edit.
This will be concatinated with the hive.
A leading `\` will be stripped.

If the `Hive` parameter is not provided, this should be the full Key.
Do NOT use PSDrive references like `HKCU:` or `HKLM:`.
Instead use normal registry paths, like `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft`.
.PARAMETER Value
Specifies the name of the property.
.PARAMETER Type
This is a dynamic parameter made available by the Registry provider.
The Registry provider and this parameter are only available on Windows.

A registry type (aka [RegistryValueKind](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/set-itemproperty#-type)) as expected when using `Set-ItemProperty`.
.PARAMETER Data
Specifies the value of the property.
.EXAMPLE
$result = Set-RegistryHiveItemProperty -Hive $hive -Key 'Policies\Microsoft\Windows\Personalization' -Value 'NoChangingSoundScheme' -Type 'String' -Data 1

Where `$hive` was created with:

```powershell
$hive = Mount-RegistryHive -DefaultUser
```
#>
function Set-RegistryHiveItemProperty ([Microsoft.Win32.RegistryKey] $Hive, [string] $Key, [string] $Value, [string] $Type, $Data) {
    if ($Key.StartsWith('\')) {
        $Key = $Key.TrimStart([IO.Path]::DirectorySeparatorChar)
    }

    $path = if ($Hive) {
        Write-Output ('Registry::{0}' -f [IO.Path]::Combine($Hive, $Key))
    } else {
        Write-Output ('Registry::{0}' -f $Key)
    }

    if (-not (Test-Path $path)) {
        # New-Item will delete a registry path, if it exists, and create it empty.
        $item = New-Item -Path $path -Force
        $item.Handle.Close()
    }

    if ((Get-ItemProperty -Path $path -Name $Value -ErrorAction 'Ignore').$Value) {
        Set-ItemProperty -Path $path -Name $Value -PropertyType $Type -Value $Data
    } else {
        New-ItemProperty -Path $path -Name $Value -PropertyType $Type -Value $Data
    }

    #Garbage Collection
    [gc]::Collect()

    return (Get-ItemProperty -Path $path -Name $Value)
}


