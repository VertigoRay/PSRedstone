[cmdletbinding()]
param(
    [version]
    $PSDepend = '0.4.5',

    [version]
    $NuGetPPMinVersion = '2.8.5.201'
)

$script:psScriptRootParent = ([IO.DirectoryInfo] $PSScriptRoot).Parent

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

Write-Information '# Enable TLS v1.2 (for GitHub et al.)'
Write-Verbose "[BUILD] SecurityProtocol OLD: $([System.Net.ServicePointManager]::SecurityProtocol)"
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
Write-Verbose "[BUILD] SecurityProtocol NEW: $([System.Net.ServicePointManager]::SecurityProtocol)"

Write-Information '# Setup NuGet PP'
if (-not (Get-PackageProvider 'NuGet' -ErrorAction 'Ignore' | Where-Object { $_.Version -ge $NuGetPPMinVersion })) {
    Install-PackageProvider -Name 'NuGet' -MinimumVersion $NuGetPPMinVersion -Force
}

Write-Information '# Get rid of older MS Pester v3'
$PesterVersion = (Import-PowerShellDataFile ([IO.Path]::Combine($PSScriptRoot, 'REQUIREMENTS.psd1'))).Pester
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

Write-Information '# Install all of the modules in the $installModules hashtable.'
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
    Install-Module @install -Scope 'CurrentUser' -AllowClobber -Force

    $m = Get-Module -Name $module.Name -ListAvailable
    Write-Information ('Installed: {0} {1}' -f $m.Name, $m.Version)
}

Write-Information '# Install all build requirements'
$invokePSDepend = @{
    Path = [IO.Path]::Combine($PSScriptRoot, 'REQUIREMENTS.psd1')
    Force = $true
}
Write-Information ('Invoke-PSDepend: {0}' -f ($invokePSDepend | ConvertTo-Json))
Invoke-PSDepend @invokePSDepend

Write-Information ('# Prepping Codecov Uploader ...' -f ($invokePSDepend | ConvertTo-Json))
# https://docs.codecov.com/docs/codecov-uploader#integrity-checking-the-uploader
$downloads = @(
    # [uri] 'https://files.gpg4win.org/gpg4win-4.1.0.exe'
    # [uri] 'https://uploader.codecov.io/verification.gpg'
    [uri] 'https://uploader.codecov.io/latest/windows/codecov.exe'
    # [uri] 'https://uploader.codecov.io/latest/windows/codecov.exe.SHA256SUM'
    # [uri] 'https://uploader.codecov.io/latest/windows/codecov.exe.SHA256SUM.sig'
)

$item = @{
    ItemType = 'Directory'
    Path = [IO.Path]::Combine($script:psScriptRootParent.FullName, 'dev', 'BuildOutput')
    Force = $true
}
Write-Information ('Creating: {0}' -f ($item | ConvertTo-Json))
New-Item @item | Out-Null

$location = @{
    LiteralPath = [IO.Path]::Combine($script:psScriptRootParent.FullName, 'dev')
}
Write-Information ('Set Location: {0}' -f ($location | ConvertTo-Json))
Push-Location @location

foreach ($download in $downloads) {
    Write-Information ('Downloading: {0}' -f $download.AbsoluteUri)
    Invoke-WebRequest -Uri $download.AbsoluteUri -Outfile $download.Segments[-1]
}

# Write-Information ('Installing: gpg4win-4.1.0.exe')
# Start-Process -FilePath 'gpg4win-4.1.0.exe' -ArgumentList '/S' -Wait

Pop-Location