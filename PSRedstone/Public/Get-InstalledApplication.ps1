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
Private Parameter; used for debug overrides.
.OUTPUTS
[hashtable[]]
.EXAMPLE
Get-InstalledApplication -Name 'Adobe Flash'
.EXAMPLE
Get-InstalledApplication -ProductCode '{1AD147D0-BE0E-3D6C-AC11-64F6DC4163F1}'
.NOTES
.LINK
https://github.com/VertigoRay/PSRedstone/wiki/Functions#get-installedapplication
#>
function Get-InstalledApplication {
    [CmdletBinding(DefaultParameterSetName = 'Like')]
    [OutputType([hashtable[]])]
    Param (
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'Eq')]
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'Exact')]
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'Like')]
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'Regex')]
        [ValidateNotNullorEmpty()]
        [string[]]
        $Name = '*',

        [Parameter(Mandatory = $false, ParameterSetName = 'Eq')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Exact')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Like')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Regex')]
        [switch]
        $CaseSensitive,

        [Parameter(Mandatory = $false, ParameterSetName = 'Exact')]
        [switch]
        $Exact,

        [Parameter(Mandatory = $false, ParameterSetName = 'Like')]
        [switch]
        $WildCard,

        [Parameter(Mandatory = $false, ParameterSetName = 'Regex')]
        [switch]
        $RegEx,

        [Parameter(Mandatory = $false, ParameterSetName = 'Productcode')]
        [ValidateNotNullorEmpty()]
        [string]
        $ProductCode,

        [Parameter(Mandatory = $false, ParameterSetName = 'Eq')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Exact')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Like')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Regex')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Productcode')]
        [switch]
        $IncludeUpdatesAndHotfixes,

        [ValidateNotNullorEmpty()]
        [string[]]
        $UninstallRegKeys = @(
            'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
            'HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
        )
    )

    Write-Information "[Get-InstalledApplication] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Information "[Get-InstalledApplication] ParameterSetName> $($PSCmdlet.ParameterSetName | ConvertTo-Json -Compress)"
    Write-Debug "[Get-InstalledApplication] Function Invocation: $($MyInvocation | Out-String)"


    if ($Name) {
        Write-Information "[Get-InstalledApplication] Get information for installed Application Name(s) [$($name -join ', ')]..."
    }
    if ($ProductCode) {
        Write-Information "[Get-InstalledApplication] Get information for installed Product Code [$ProductCode]..."
    }

    ## Enumerate the installed applications from the registry for applications that have the "DisplayName" property
    [psobject[]] $regKeyApplication = @()
    foreach ($regKey in $UninstallRegKeys) {
        Write-Verbose "[Get-InstalledApplication] Checking Key: ${regKey}"
        if (Test-Path -LiteralPath $regKey -ErrorAction 'SilentlyContinue' -ErrorVariable '+ErrorUninstallKeyPath') {
            [psobject[]] $UninstallKeyApps = Get-ChildItem -LiteralPath $regKey -ErrorAction 'SilentlyContinue' -ErrorVariable '+ErrorUninstallKeyPath'
            foreach ($UninstallKeyApp in $UninstallKeyApps) {
                Write-Verbose "[Get-InstalledApplication] Checking Key: $($UninstallKeyApp.PSChildName)"
                try {
                    [psobject] $regKeyApplicationProps = Get-ItemProperty -LiteralPath $UninstallKeyApp.PSPath -ErrorAction 'Stop'
                    if ($regKeyApplicationProps.DisplayName) { [psobject[]] $regKeyApplication += $regKeyApplicationProps }
                } catch {
                    Write-Warning "[Get-InstalledApplication] Unable to enumerate properties from registry key path [$($UninstallKeyApp.PSPath)].$(if (Get-Command 'Resolve-Error' -ErrorAction 'Ignore') { "`n{0}" -f (Resolve-Error) })"
                    continue
                }
            }
        }
    }
    if ($ErrorUninstallKeyPath) {
        Write-Warning "[Get-InstalledApplication] The following error(s) took place while enumerating installed applications from the registry.$(if (Get-Command 'Resolve-Error' -ErrorAction 'Ignore') { "`n{0}" -f (Resolve-Error -ErrorRecord $ErrorUninstallKeyPath) })"
    }

    ## Create a custom object with the desired properties for the installed applications and sanitize property details
    [Collections.ArrayList] $installedApplication = @()
    foreach ($regKeyApp in $regKeyApplication) {
        try {
            [string] $appDisplayName = ''
            [string] $appDisplayVersion = ''
            [string] $appPublisher = ''

            ## Bypass any updates or hotfixes
            if (-not $IncludeUpdatesAndHotfixes.IsPresent) {
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
            [boolean] $Is64BitApp = if (([System.Environment]::Is64BitOperatingSystem) -and ($regKeyApp.PSPath -notmatch '^Microsoft\.PowerShell\.Core\\Registry::HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node')) { $true } else { $false }

            if ($PSCmdlet.ParameterSetName -eq 'ProductCode') {
                ## Verify if there is a match with the product code passed to the script
                if (($regKeyApp.PSChildName -as [guid]).Guid -eq ($ProductCode -as [guid]).Guid) {
                    Write-Information "[Get-InstalledApplication] Found installed application [$appDisplayName] version [$appDisplayVersion] matching product code [$productCode]."
                    $installedApplication.Add(@{
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
                    }) | Out-Null
                }
            } else {
                ## Verify if there is a match with the application name(s) passed to the script
                foreach ($application in $Name) {
                    $applicationMatched = $false
                    if ($Exact.IsPresent) {
                        Write-Debug ('[Get-InstalledApplication] $Exact.IsPresent')
                        #  Check for exact application name match
                        if ($CaseSensitive.IsPresent) {
                            #  Check for a CaseSensitive application name match
                            if ($regKeyApp.DisplayName -ceq $application) {
                                $applicationMatched = $true
                                Write-Information "[Get-InstalledApplication] Found installed application [$appDisplayName] version [$appDisplayVersion] using casesensitive exact name matching for search term [$application]."
                            }
                        } elseif ($regKeyApp.DisplayName -eq $application) {
                            $applicationMatched = $true
                            Write-Information "[Get-InstalledApplication] Found installed application [$appDisplayName] version [$appDisplayVersion] using exact name matching for search term [$application]."
                        }
                    } elseif ($RegEx.IsPresent) {
                        Write-Debug ('[Get-InstalledApplication] $RegEx.IsPresent')
                        #  Check for a regex application name match
                        if ($CaseSensitive.IsPresent) {
                            #  Check for a CaseSensitive application name match
                            if ($regKeyApp.DisplayName -cmatch $application) {
                                $applicationMatched = $true
                                Write-Information "[Get-InstalledApplication] Found installed application [$appDisplayName] version [$appDisplayVersion] using casesensitive regex name matching for search term [$application]."
                            }
                        } elseif ($regKeyApp.DisplayName -match $application) {
                            $applicationMatched = $true
                            Write-Information "[Get-InstalledApplication] Found installed application [$appDisplayName] version [$appDisplayVersion] using regex name matching for search term [$application]."
                        }
                    } else {
                        #  Check for a like application name match
                        if ($CaseSensitive.IsPresent) {
                            #  Check for a CaseSensitive application name match
                            if ($regKeyApp.DisplayName -clike $application) {
                                $applicationMatched = $true
                                Write-Information "[Get-InstalledApplication] Found installed application [$appDisplayName] version [$appDisplayVersion] using casesensitive like name matching for search term [$application]."
                            } else {
                                Write-Information "[Get-InstalledApplication] No found installed application using casesensitive like name matching for search term [$application]."
                            }
                        } elseif ($regKeyApp.DisplayName -like $application) {
                            $applicationMatched = $true
                            Write-Information "[Get-InstalledApplication] Found installed application [$appDisplayName] version [$appDisplayVersion] using like name matching for search term [$application]."
                        }
                    }

                    if ($applicationMatched) {
                        $installedApplication.Add(@{
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
                        }) | Out-Null
                    }
                }
            }
        } catch {
            Write-Error "[Get-InstalledApplication] Failed to resolve application details from registry for [$appDisplayName].$(if (Get-Command 'Resolve-Error' -ErrorAction 'Ignore') { "`n{0}" -f (Resolve-Error) })"
            continue
        }
    }

    Write-Information ('[Get-InstalledApplication] Application Searched: {0}' -f $application)
    return $installedApplication
}
#region DEVONLY
# $VerbosePreference = 'c'
# Get-InstalledApplication -Name '*PowerShell*' -WildCard
#endregion
