<#
.SYNOPSIS
Get a registry value without expanding environment variables.
.OUTPUTS
[bool]
.EXAMPLE
PS > Get-RedstoneRegistryValueDoNotExpandEnvironmentName HKCU:\Thing Foo
True
#>
function Get-RedstoneRegistryValueDoNotExpandEnvironmentName {
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

    Write-Verbose ('[Get-RedstoneRegistryValueDoNotExpandEnvironmentName] >')
    Write-Debug ('[Get-RedstoneRegistryValueDoNotExpandEnvironmentName] > {0}' -f ($MyInvocation | Out-String))

    $item = Get-Item $Key
    if ($item) {
        return $item.GetValue($Value, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
    } else {
        return $null
    }
}
