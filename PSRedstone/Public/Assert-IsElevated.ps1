<#
.SYNOPSIS
Is the current process elevated (running as administrator)?
.OUTPUTS
[bool]
.EXAMPLE
Assert-IsElevated
Returns `$true` if you're  running as an administrator.
.LINK
https://github.com/VertigoRay/PSRedstone/wiki/Functions#assert-iselevated
#>
function Assert-IsElevated {
    [OutputType([bool])]
    [CmdletBinding()]
    Param()

    Write-Verbose ('[Assert-IsElevated] >')
    Write-Debug ('[Assert-IsElevated] > {0}' -f ($MyInvocation | Out-String))

    $isElevated = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    Write-Verbose ('[Assert-IsElevated] IsElevated: {0}' -f $isElevated)

    return $isElevated
}
