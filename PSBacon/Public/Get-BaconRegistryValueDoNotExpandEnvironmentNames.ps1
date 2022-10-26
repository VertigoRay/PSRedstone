<#
.SYNOPSIS
Is the current process elevated (running as administrator)?
.OUTPUTS
[bool]
.EXAMPLE
PS > Assert-BaconIsElevated
True
#>
function Global:Get-RegistryValueDoNotExpandEnvironmentName {
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