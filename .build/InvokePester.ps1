[CmdletBinding()]
param (
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]
    $File,

    [Parameter()]
    [switch]
    $PressAnyKeyToContinue
)

$psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent

[version] $requiredPesterVersion = '5.3.3'
if ((Get-Module 'Pester') -and ((Get-Module 'Pester').Version -ne $requiredPesterVersion)) {
    foreach ($pester in (Get-Module 'Pester')) {
        if (([IO.DirectoryInfo] $pester.ModuleBase).Parent.Exists) {
            # https://pester.dev/docs/introduction/installation#removing-the-built-in-version-of-pester
            $oldPesterModule = ([IO.DirectoryInfo] $pester.ModuleBase).Parent.FullName
            & takeown /F "${oldPesterModule}" /A /R | Out-Null
            & icacls "${oldPesterModule}" /reset | Out-Null
            & icacls "${oldPesterModule}" /grant "*S-1-5-32-544:F" /inheritance:d /T | Out-Null
            Remove-Item -Path $oldPesterModule -Recurse -Force -Confirm:$false
        }
    }
    Remove-Module 'Pester' -Force

    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
    Install-Module 'Pester' -RequiredVersion $requiredPesterVersion -SkipPublisherCheck -Force
}
Import-Module 'Pester' -Passthru

Push-Location $psProjectRoot.FullName
Push-Location 'Tests'

$invokePester = @{
    # OutputFile = (Join-Path (Join-Path $psProjectRoot.FullName 'dev') 'pesterResults.xml')
    # OutputFormat = 'NUnitXML'
    Output = 'Diagnostic'
}

if ($File) {
    Write-Host ('Looking for test for: {0}' -f ($File | ConvertTo-Json)) -ForegroundColor 'Cyan'
    Get-ChildItem -Path "*${File}*" | ForEach-Object {
        $invokePester.Set_Item('Path', $_)

        Write-Host ('Invoke Pester Test: {0}' -f ($invokePester | ConvertTo-Json)) -ForegroundColor 'Cyan'
        Invoke-Pester @invokePester
    }
} else {
    Write-Host ('Invoke Pester Tests: {0}' -f ($invokePester | ConvertTo-Json)) -ForegroundColor 'Cyan'
    Invoke-Pester @invokePester
}


if ($PressAnyKeyToContinue.IsPresent) {
    Write-Host -NoNewLine 'Press any key to continue...'
    $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
}