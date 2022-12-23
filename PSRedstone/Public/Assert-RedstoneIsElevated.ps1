<#
.SYNOPSIS
Is the current process elevated (running as administrator)?
.OUTPUTS
[bool]
.EXAMPLE
PS > Assert-RedstoneIsElevated
True
#>
function Assert-RedstoneIsElevated {
    [OutputType([bool])]
    [CmdletBinding()]
    Param()

    Write-Verbose ('[Assert-RedstoneIsElevated] >')
    Write-Debug ('[Assert-RedstoneIsElevated] > {0}' -f ($MyInvocation | Out-String))

    $isElevated = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    Write-Verbose ('[Assert-RedstoneIsElevated] IsElevated: {0}' -f $isElevated)

    return $isElevated
}
