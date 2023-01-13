<#
    .Synopsis
        Return the current version number for this project.
    .Description
        Return the current version number for this project.
        If a versions has already been setup in this environment, returns that.
        Otherwise, creates a version using the format: "yyyy.MM.dd.sssss"
        Where "sssss" is the total number of seconds since midnight.
        If on AppVeyor, will use the Build Number for instead of seconds.
    .Example
        $version = & .\version.ps1
    .Example
        # Largest possible Revision
        PS > (New-TimeSpan -Start ([datetime]::Today) -End ([datetime]::Today).AddDays(1)).TotalSeconds
        86400
#>
[CmdletBinding()]
param()

if (-not $env:MODULE_VERSION) {
    Write-Debug ('[version.ps1] env:MODULE_VERSION empty; setting ...')

    $versionMMB = Get-Date -Format 'yyyy.MM.dd'
    Write-Debug ('[version.ps1] versionMMB: {0}' -f $versionMMB)
    $versionR = (New-TimeSpan -Start ([datetime]::Today)).TotalSeconds -as [int]
    Write-Debug ('[version.ps1] versionR: {0}' -f $versionR)

    if ($env:APPVEYOR_BUILD_NUMBER) {
        Write-Debug ('[version.ps1] APPVEYOR_BUILD_NUMBER: {0}' -f $env:APPVEYOR_BUILD_NUMBER)
        $env:MODULE_VERSION = '{0}.{1}' -f $versionMMB, $env:APPVEYOR_BUILD_NUMBER
    } else {
        $env:MODULE_VERSION = '{0}.{1}' -f $versionMMB, $versionR
    }
} else {
    Write-Debug ('[version.ps1] env:MODULE_VERSION already set.')
}
Write-Verbose ('[version.ps1] env:MODULE_VERSION: {0}' -f $env:MODULE_VERSION)

if ($version = $env:MODULE_VERSION -as [version]) {
    Write-Debug ('[version.ps1] returning ver: [{0}] {1}' -f $version.GetType().FullName, $version)
    return $version
} else {
    Write-Debug ('[version.ps1] returning env: [{0}] {1}' -f $env:MODULE_VERSION.GetType().FullName, $env:MODULE_VERSION)
    return $env:MODULE_VERSION
}
