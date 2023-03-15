<#
.SYNOPSIS
Recursively probe registry key's sub-key's and values and output a sorted array.
.DESCRIPTION
Recursively probe registry key's sub-key's and values and output a sorted array.
.PARAMETER Key
This is the key path within the hive. Do not include the Hive itself.
.PARAMETER Hive
This is a top-level node in the registry as defined by [RegistryHive Enum](https://learn.microsoft.com/en-us/dotnet/api/microsoft.win32.registryhive).
.EXAMPLE
Get-RecursiveRegistryKey 'SOFTWARE\Palo Alto Networks\GlobalProtect'
.LINK
https://github.com/VertigoRay/PSRedstone/wiki/Functions#get-registrykeyasarray
#>
function Get-RegistryKeyAsArray([string] $Key, [string] $Hive = 'LocalMachine') {
    #region Parameter Validation
    $hives = @(
        'ClassesRoot'
        'CurrentConfig'
        'CurrentUser'
        'LocalMachine'
        'PerformanceData'
        'Users'
    )
    if ($hives -notcontains $Hive) {
        throw [System.Management.Automation.ItemNotFoundException] ('Provided hive ({0}) should be one of: {1}.' -f $hive, ($hives -join ', '))
    }
    #endregion Parameter Validation

    # Declare an arraylist to which the recursive function below can append values.
    [System.Collections.ArrayList] $RegKeysArray = 'KeyName', 'ValueName', 'Value'

    $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive, $ComputerName)
    $RegKey= $Reg.OpenSubKey($RegPath)

    function DigThroughKeys([Microsoft.Win32.RegistryKey] $Key) {
        # If it has no subkeys, retrieve the values and append to them to the global array.
        if ($Key.SubKeyCount-eq 0) {
            foreach ($value in $Key.GetValueNames()) {
                if ($null -ne $Key.GetValue($value)) {
                    [void] $RegKeysArray.Add(([PSObject] @{
                        KeyName = $Key.Name
                        ValueName = $value.ToString()
                        Value = $Key.GetValue($value)
                    }))
                }
            }
        } else {
            if ($Key.ValueCount -gt 0) {
                foreach ($value in $Key.GetValueNames()) {
                    if ($null -ne $Key.GetValue($value)) {
                        [void] $RegKeysArray.Add(([PSObject] @{
                            KeyName = $Key.Name
                            ValueName = $value.ToString()
                            Value = $Key.GetValue($value)
                        }))
                    }
                }
            }
            #Recursive lookup happens here. If the key has subkeys, send the key(s) back to this same function.
            if ($Key.SubKeyCount -gt 0) {
                foreach ($subKey in $Key.GetSubKeyNames()) {
                    DigThroughKeys -Key $Key.OpenSubKey($subKey)
                }
            }
        }
    }

    DigThroughKeys -Key $RegKey

    #Write the output to the console.
    Write-Output ($RegKeysArray | Select-Object KeyName, ValueName, Value | Sort-Object ValueName | Format-Table)

    $Reg.Close()
}
