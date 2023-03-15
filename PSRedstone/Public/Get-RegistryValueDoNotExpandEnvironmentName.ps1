<#
.SYNOPSIS
Get a registry value without expanding environment variables.
.OUTPUTS
[bool]
.EXAMPLE
Get-RegistryValueDoNotExpandEnvironmentName 'HKCU:\Thing Foo'
.LINK
https://github.com/VertigoRay/PSRedstone/wiki/Functions#get-registryvaluedonotexpandenvironmentname
#>
function Get-RegistryValueDoNotExpandEnvironmentName {
    [OutputType([bool])]
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $Key,

        [Parameter()]
        [string]
        $Value
    )

    Write-Verbose ('[Get-RegistryValueDoNotExpandEnvironmentName] >')
    Write-Debug ('[Get-RegistryValueDoNotExpandEnvironmentName] > {0}' -f ($MyInvocation | Out-String))

    $item = Get-Item $Key
    if ($item) {
        return $item.GetValue($Value, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
    } else {
        return $null
    }
}
