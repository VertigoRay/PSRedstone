[cmdletbinding()]
param(
    [string[]]
    $Task = 'default',

    [version]
    $PesterVersion = '5.3.3',

    [version]
    $NuGetPPMinVersion = '2.8.5.201'
)

trap {
    if ($env:CI) {
        $Host.SetShouldExit(1)
    }
}

if (-not (Get-PackageProvider 'NuGet' | Where-Object { $_.Version -ge $NuGetPPMinVersion })) {
    Install-PackageProvider -Name 'NuGet' -MinimumVersion $NuGetPPMinVersion -Force | Out-Null
}

if ((Get-Module 'Pester') -and ((Get-Module 'Pester').Version -ne $PesterVersion)) {
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

    Install-Module 'Pester' -RequiredVersion $PesterVersion -SkipPublisherCheck -Scope 'CurrentUser' -Force
}

if (!(Get-Module -Name 'psake' -ListAvailable)) { Install-Module -Name 'psake' -Scope 'CurrentUser' -Force }
if (!(Get-Module -Name 'PSDeploy' -ListAvailable)) { Install-Module -Name 'PSDeploy' -Scope 'CurrentUser' -Force }

Invoke-psake -BuildFile "$PSScriptRoot\buildPsake.ps1" -TaskList $Task -Verbose:$VerbosePreference
