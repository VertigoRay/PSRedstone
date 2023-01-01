<#
.SYNOPSIS
Retrieves information about installed applications.
.DESCRIPTION
Retrieves information about installed applications by querying the registry. You can specify an application name, a product code, or both.
Returns information about application publisher, name & version, product code, uninstall string, quiet uninstall string, install source, location, date, and application architecture.
.PARAMETER Name
The name of the application to retrieve information for. Performs a regex match on the application display name by default.
.PARAMETER Exact
Specifies that the named application must be matched using the exact name.
.PARAMETER WildCard
Specifies that the named application must be matched using a wildcard search.
.PARAMETER ProductCode
The product code of the application to retrieve information for.
.PARAMETER IncludeUpdatesAndHotfixes
Include matches against updates and hotfixes in results.
.PARAMETER UninstallRegKeys
Default: `$global:Redstone.Settings.Functions.Get-InstalledApplication.UninstallRegKeys`

Private Parameter; used for debug overrides.
.EXAMPLE
Get-RedstoneInstalledApplication -Name 'Adobe Flash'
.EXAMPLE
Get-RedstoneInstalledApplication -ProductCode '{1AD147D0-BE0E-3D6C-AC11-64F6DC4163F1}'
.NOTES
.LINK
http://psappdeploytoolkit.com
#>
Function Get-RedstoneInstalledApplication {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string[]]
        $Name,

        [Parameter(Mandatory=$false)]
        [switch]
        $Exact = $false,

        [Parameter(Mandatory=$false)]
        [switch]
        $WildCard,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string]
        $ProductCode,

        [Parameter(Mandatory=$false)]
        [switch]
        $IncludeUpdatesAndHotfixes,

        [Parameter(Mandatory=$false, HelpMessage="Private Parameter; used for debug overrides.")]
        [ValidateNotNullorEmpty()]
        [string[]]
        $UninstallRegKeys = @(
            'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
            'HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
        )
    )

    Write-Information "[Get-RedstoneInstalledApplication] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Debug "[Get-RedstoneInstalledApplication] Function Invocation: $($MyInvocation | Out-String)"


    if ($Name) {
        Write-Information "[Get-RedstoneInstalledApplication] Get information for installed Application Name(s) [$($name -join ', ')]..."
    }
    if ($ProductCode) {
        Write-Information "[Get-RedstoneInstalledApplication] Get information for installed Product Code [$ProductCode]..."
    }

    ## Enumerate the installed applications from the registry for applications that have the "DisplayName" property
    [psobject[]]$regKeyApplication = @()
    foreach ($regKey in $UninstallRegKeys) {
        Write-Verbose "[Get-RedstoneInstalledApplication] Checking Key: ${regKey}"
        if (Test-Path -LiteralPath $regKey -ErrorAction 'SilentlyContinue' -ErrorVariable '+ErrorUninstallKeyPath') {
            [psobject[]]$UninstallKeyApps = Get-ChildItem -LiteralPath $regKey -ErrorAction 'SilentlyContinue' -ErrorVariable '+ErrorUninstallKeyPath'
            foreach ($UninstallKeyApp in $UninstallKeyApps) {
                Write-Verbose "[Get-RedstoneInstalledApplication] Checking Key: $($UninstallKeyApp.PSChildName)"
                try {
                    [psobject]$regKeyApplicationProps = Get-ItemProperty -LiteralPath $UninstallKeyApp.PSPath -ErrorAction 'Stop'
                    if ($regKeyApplicationProps.DisplayName) { [psobject[]]$regKeyApplication += $regKeyApplicationProps }
                } catch {
                    Write-Warning "[Get-RedstoneInstalledApplication] Unable to enumerate properties from registry key path [$($UninstallKeyApp.PSPath)]. `n$(Resolve-Error)"
                    continue
                }
            }
        }
    }
    if ($ErrorUninstallKeyPath) {
        Write-Warning "[Get-RedstoneInstalledApplication] The following error(s) took place while enumerating installed applications from the registry. `n$(Resolve-Error -ErrorRecord $ErrorUninstallKeyPath)"
    }

    ## Create a custom object with the desired properties for the installed applications and sanitize property details
    [psobject[]]$installedApplication = @()
    foreach ($regKeyApp in $regKeyApplication) {
        try {
            [string]$appDisplayName = ''
            [string]$appDisplayVersion = ''
            [string]$appPublisher = ''

            ## Bypass any updates or hotfixes
            if (-not $IncludeUpdatesAndHotfixes) {
                if ($regKeyApp.DisplayName -match '(?i)kb\d+') { continue }
                if ($regKeyApp.DisplayName -match 'Cumulative Update') { continue }
                if ($regKeyApp.DisplayName -match 'Security Update') { continue }
                if ($regKeyApp.DisplayName -match 'Hotfix') { continue }
            }

            ## Remove any control characters which may interfere with logging and creating file path names from these variables
            $appDisplayName = $regKeyApp.DisplayName -replace '[^\u001F-\u007F]',''
            $appDisplayVersion = $regKeyApp.DisplayVersion -replace '[^\u001F-\u007F]',''
            $appPublisher = $regKeyApp.Publisher -replace '[^\u001F-\u007F]',''

            ## Determine if application is a 64-bit application
            [boolean]$Is64BitApp = if (([System.Environment]::Is64BitOperatingSystem) -and ($regKeyApp.PSPath -notmatch '^Microsoft\.PowerShell\.Core\\Registry::HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node')) { $true } else { $false }

            if ($ProductCode) {
                ## Verify if there is a match with the product code passed to the script
                if ($regKeyApp.PSChildName -match [regex]::Escape($productCode)) {
                    Write-Information "[Get-RedstoneInstalledApplication] Found installed application [$appDisplayName] version [$appDisplayVersion] matching product code [$productCode]."
                    $installedApplication += New-Object -TypeName 'PSObject' -Property @{
                        UninstallSubkey = $regKeyApp.PSChildName
                        ProductCode = $regKeyApp.PSChildName -as [guid]
                        DisplayName = $appDisplayName
                        DisplayVersion = $appDisplayVersion
                        UninstallString = $regKeyApp.UninstallString
                        QuietUninstallString = $regKeyApp.QuietUninstallString
                        InstallSource = $regKeyApp.InstallSource
                        InstallLocation = $regKeyApp.InstallLocation
                        InstallDate = $regKeyApp.InstallDate
                        Publisher = $appPublisher
                        Is64BitApplication = $Is64BitApp
                        PSPath = $regKeyApp.PSPath
                    }
                }
            }

            if ($name) {
                ## Verify if there is a match with the application name(s) passed to the script
                foreach ($application in $Name) {
                    $applicationMatched = $false
                    if ($exact) {
                        #  Check for an exact application name match
                        if ($regKeyApp.DisplayName -eq $application) {
                            $applicationMatched = $true
                            Write-Information "[Get-RedstoneInstalledApplication] Found installed application [$appDisplayName] version [$appDisplayVersion] using exact name matching for search term [$application]."
                        }
                    }
                    elseif ($WildCard.IsPresent) {
                        #  Check for wildcard application name match
                        if ($regKeyApp.DisplayName -like $application) {
                            $applicationMatched = $true
                            Write-Information "[Get-RedstoneInstalledApplication] Found installed application [$appDisplayName] version [$appDisplayVersion] using wildcard matching for search term [$application]."
                        }
                    }
                    #  Check for a regex application name match
                    elseif ($regKeyApp.DisplayName -match [regex]::Escape($application)) {
                        $applicationMatched = $true
                        Write-Information "[Get-RedstoneInstalledApplication] Found installed application [$appDisplayName] version [$appDisplayVersion] using regex matching for search term [$application]."
                    }

                    if ($applicationMatched) {
                        # $installedApplication += $regKeyApp
                        $installedApplication += New-Object -TypeName 'PSObject' -Property @{
                            UninstallSubkey = $regKeyApp.PSChildName
                            ProductCode = $regKeyApp.PSChildName -as [guid]
                            DisplayName = $appDisplayName
                            DisplayVersion = $appDisplayVersion
                            UninstallString = $regKeyApp.UninstallString
                            QuietUninstallString = $regKeyApp.QuietUninstallString
                            InstallSource = $regKeyApp.InstallSource
                            InstallLocation = $regKeyApp.InstallLocation
                            InstallDate = $regKeyApp.InstallDate
                            Publisher = $appPublisher
                            Is64BitApplication = $Is64BitApp
                            PSPath = $regKeyApp.PSPath
                        }
                    }
                }
            }
        } catch {
            Write-Error "[Get-RedstoneInstalledApplication] Failed to resolve application details from registry for [$appDisplayName]. `n$(Resolve-Error)"
            continue
        }
    }

    return $installedApplication
}
#region DEVONLY
# $VerbosePreference = 'c'
# Get-RedstoneInstalledApplication -Name '*PowerShell*' -WildCard
#endregion
