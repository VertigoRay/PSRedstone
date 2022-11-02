[cmdletbinding()]
param(
    [string[]]
    $Task = 'default',

    [version]
    $PesterVersion = '5.3.3',

    [version]
    $NuGetPPMinVersion = '2.8.5.201'
)

$installModules = @{
    Pester = @{
        RequiredVersion = $PesterVersion
        SkipPublisherCheck = $true
    }
    psake = 'latest'
    # PSDeploy = 'latest'
}

$ErrorActionPreference = 'Stop'
trap {
    Write-Error ('( ಥ ͜ʖ ͡ಥ) {0}' -f $_) -ErrorAction 'Continue'
    if ($env:CI) {
        $Host.SetShouldExit(1)
    }
}

# Setup NuGet PP
if (-not (Get-PackageProvider 'NuGet' -ErrorAction 'Ignore' | Where-Object { $_.Version -ge $NuGetPPMinVersion })) {
    Install-PackageProvider -Name 'NuGet' -MinimumVersion $NuGetPPMinVersion -Force
}

# Get rid of older MS Pester
if ((Get-Module 'Pester' -ErrorAction 'Ignore') -and ((Get-Module 'Pester' -ErrorAction 'Ignore').Version -ne $PesterVersion)) {
    foreach ($pester in (Get-Module 'Pester' -ErrorAction 'Ignore')) {
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
}

# Install all of the modules in the $installModules hashtable.
foreach ($module in $installModules.GetEnumerator()) {
    # if (-not (Get-Module -Name $module.Name -ListAvailable -ErrorAction 'Ignore')) {
        if ($module.Value -is [hashtable]) {
            $install = $module.Value
            $install.Set_Item('Name', $module.Name)
        } else {
            $install = @{
                Name = $module.Name
            }
            if ($module.Value -ne 'latest') {
                $install.Set_Item('RequiredVersion', $module.Value)
            }
        }
        Install-Module @install -Scope 'CurrentUser' -Force
        Get-Module -Name $module.Name -ListAvailable | Format-Table
    # }
}

# Run the *real* build script.
Invoke-psake -BuildFile "$PSScriptRoot\buildPsake.ps1" -TaskList $Task -Verbose:$VerbosePreference
