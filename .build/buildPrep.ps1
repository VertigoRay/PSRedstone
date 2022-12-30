[cmdletbinding()]
param(
    [version]
    $PSDepend = '0.4.5',

    [version]
    $NuGetPPMinVersion = '2.8.5.201'
)

$installModules = @{
    PSDepend2 = $PSDepend
}

$ErrorActionPreference = 'Stop'
trap {
    Write-Warning ('{0}' -f $_)
    Write-Warning ($_ | Out-String)
    Write-Warning (Get-PSCallStack | Out-String)
    Write-Error $_ -ErrorAction 'Continue'
    if ($env:CI) {
        $Host.SetShouldExit(1)
    }
}

if (Test-Path ([IO.Path]::Combine($PSScriptRoot, 'env.ps1'))) {
    . ([IO.Path]::Combine($PSScriptRoot, 'env.ps1'))
}

Write-Information 'Enable TLS v1.2 (for GitHub et al.)'
Write-Verbose "[BUILD] SecurityProtocol OLD: $([System.Net.ServicePointManager]::SecurityProtocol)"
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
Write-Verbose "[BUILD] SecurityProtocol NEW: $([System.Net.ServicePointManager]::SecurityProtocol)"

Write-Information 'Setup NuGet PP'
if (-not (Get-PackageProvider 'NuGet' -ErrorAction 'Ignore' | Where-Object { $_.Version -ge $NuGetPPMinVersion })) {
    Install-PackageProvider -Name 'NuGet' -MinimumVersion $NuGetPPMinVersion -Force
}

Write-Information 'Get rid of older MS Pester v3'
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

Write-Information 'Install all of the modules in the $installModules hashtable.'
foreach ($module in $installModules.GetEnumerator()) {
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

    $m = Get-Module -Name $module.Name -ListAvailable
    Write-Information '{0}Installed: {1} {2}' -f "`t", $m.Name, $m.Version
}

Write-Information 'Install all build requirements'
Invoke-PSDepend -Path ([IO.Path]::Combine($PSScriptRoot, 'REQUIREMENTS.psd1'))