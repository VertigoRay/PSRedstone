<#
.DESCRIPTION
    Adjust the default parameters to your liking. Otherwise, tread carefully.

    This script can be used as part of a configuration item to setup computers with PSRedstone.
    The idea here is that you setup the latest version as the MinimumVersionRequired and never change it (unless you sure you no longer need that version).

    On first run, this script will install every version of PSRedstone from the minimum version required to the latest version.
    It will timestamp each version in the registry with the current date at midnight.
    This should stand out to you as a version that was likely installed and never actually used.

    PSRedstone will also update the timestamp of it's current version each time the module is imported.
    This makes it very easy to tell what versions are active on the system.
    The second parameter helps us decide when to uninstall unused versions.

    On the second run and all subsequent runs, this script will update to the lastest version of PSRestone, if needed.
    It will also go through all versions that are currently installed and purge any versions from the system that have not been used.

    Why go through all this trouble? I'm glad you asked, refer to the README:
        https://github.com/VertigoRay/PSRedstone#advanced-start
#>
#Requires -RunAsAdministrator
[CmdletBinding()]
param (
    [Parameter(HelpMessage = 'Set the version that we started using PSRedstone here. We know none of our scripts will use anything older than this.')]
    [version]
    $MinimumVersionRequired = '2022.12.30.35018',

    [Parameter(HelpMessage = 'How many days shall a script go unused before it is removed?')]
    [int]
    $DaysAfterUnusedVersionAreUninstalled = 90
)

[hashtable] $versionInstalled = @{
    LiteralPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\VertigoRay\PSRedstone\VersionsUsed'
    Name = $MinimumVersionRequired
    Value = (Get-Date -Format 'yyyy-MM-dd' | Get-Date -Format 'O') # 2023-01-08T00:00:00.0000000
    Force = $true
}

$registerVersion = {
    param(
        [hashtable] $ItemProperty
    )

    Write-Verbose ('[REMEDIATION] Version Registered: {0}' -f ($ItemProperty | ConvertTo-Json))
    if (-not (Test-Path $ItemProperty.LiteralPath)) {
        New-Item -Path $ItemProperty.LiteralPath -Force
    }
    Set-ItemProperty @ItemProperty
}

if (Get-Module 'PSRedstone' -ListAvailable) {
    # PSRedstone not currently installed.
    Update-Module 'PSRedstone' -Force

    # Cleanup Old Versions
    Get-Module 'PSRedstone' -ListAvailable | Foreach-Object {
        $dateInstalled = (Get-ItemProperty -LiteralPath $versionInstalled.LiteralPath -Name $_.Version -ErrorAction 'Ignore').($_.Version) -as [datetime]
        if ($dateInstalled) {
            if ($dateInstalled -lt (Get-Date).AddDays(-$DaysAfterUnusedVersionAreUninstalled)) {
                # If it has gone unused for longer than desired
                Write-Information ('[REMEDIATION] # Removing Unused Version: {0}' -f $_.Version)
                Uninstall-Module $_.Name -RequiredVersion $_.Version -Force
                Remove-ItemProperty -LiteralPath $versionInstalled.LiteralPath -Name $_.Version -ErrorAction 'Ignore'
            }
        } else {
            # Version was somehow installed and not registered or not registered correctly; register it now
            $versionInstalled.Set_Item('Name', $_.Version)
            & $registerVersion $versionInstalled
        }
    }
} else {
    # PSRedstone not currently installed.
    Write-Information '[REMEDIATION] # Enable TLS v1.2 (for PSGallery, et al.)'
    Write-Verbose "[REMEDIATION] SecurityProtocol OLD: $([System.Net.ServicePointManager]::SecurityProtocol)"
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
    Write-Verbose "[REMEDIATION] SecurityProtocol NEW: $([System.Net.ServicePointManager]::SecurityProtocol)"

    Write-Information '[REMEDIATION] # Setup NuGet PP'
    [version] $NuGetPPMinVersion = '2.8.5.201'
    if (-not (Get-PackageProvider 'NuGet' -ErrorAction 'Ignore' | Where-Object { $_.Version -ge $NuGetPPMinVersion })) {
        Install-PackageProvider -Name 'NuGet' -MinimumVersion $NuGetPPMinVersion -Force
    }

    Write-Information '[REMEDIATION] Install all versions greater than or equal to the minimum version required; set above.'
    Find-Module 'PSRedstone' -Repository 'PSGallery' -AllVersions | Where-Object {
        $_.Version -lt (Find-Module 'PSRedstone' -ErrorAction 'Ignore').Version
    } | Where-Object {
        $_.Version -ge $MinimumVersionRequired
    } | Foreach-Object {
        Install-Module $_.Name -RequiredVersion $_.Version -Scope 'CurrentUser' -Repository 'PSGallery' -Force -AllowClobber
        $versionInstalled.Set_Item('Name', $_.Version)
        & $registerVersion $versionInstalled
    }
}
