<#
.SYNOPSIS
Is the current process elevated (running as administrator)?
.OUTPUTS
[bool]
.EXAMPLE
PS > Assert-BaconIsElevated
True
#>
function Assert-BaconIsElevated {
    [OutputType([bool])]
    [CmdletBinding()]
    Param()

    Write-Verbose ('[Assert-BaconIsElevated] >')
    Write-Debug ('[Assert-BaconIsElevated] > {0}' -f ($MyInvocation | Out-String))

    $isElevated = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    Write-Verbose ('[Assert-BaconIsElevated] IsElevated: {0}' -f $isElevated)

    return $isElevated
}
