<#
.SYNOPSIS
Uninstall a program using WMI and QuietUninstallStrings from the Registry.
.DESCRIPTION
Uninstall a program using WMI and QuietUninstallStrings from the Registry.
.PARAMETER SearchString
Program Name/DisplayName to search for. Use percent (`%`) for wildcard searches; question mark (`?`) not specifically supported.
.PARAMETER Exact
Do an exact search.
.PARAMETER ModifyUninstallString
Default: $global:Winstall.Settings.Functions.InvokeUninstall.AllowAttended

If only the Uninstall String is found, you can modify it with this parameter.
.PARAMETER AllowAttended
Allow attended uninstalls. This only applies if only an UninstallString is found in the registry.
.LINK
https://git.cas.unt.edu/winstall/winstall/wikis/Invoke-WinstallUninstall
#>
function Global:Invoke-Uninstall {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [string]
        $SearchString
        ,
        [Parameter(Mandatory=$false)]
        [switch]
        $Exact
        ,
        [string]
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        $ModifyUninstallString = $null
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [boolean]
        $AllowAttended = $global:Winstall.Settings.Functions.InvokeUninstall.AllowAttended
    )

    Write-Information "> $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Debug "Function Invocation: $($MyInvocation | Out-String)"


    <#
    .SYNOPSIS
    This processes and Uninstall string found in the registry.
    #>
    function Private:_UninstallString {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true, Position=0)]
            [ValidateNotNullorEmpty()]
            [string]
            $UninstallString
            ,
            [Parameter(Mandatory=$false, Position=1)]
            [ValidateNotNullorEmpty()]
            [string]
            $ModifyUninstallString
            ,
            [Parameter(Mandatory=$false, Position=2)]
            [ValidateNotNullorEmpty()]
            [boolean]
            $AllowAttended
        )

        Write-Information "> $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
        Write-Debug "Function Invocation: $($MyInvocation | Out-String)"


        if ($UninstallString -match '^msiexec') {
            Write-Verbose "UninstallString is an MSI ..."
            if ($UninstallString -match '\{[^}]+\}') {
                Write-Verbose "ProductCode Found: $($Matches[0])"
                Invoke-Msi -Action 'Uninstall' -Path $Matches[0]
            } elseif ($UninstallString -match '/x[ ]*(?:"([^"]+(?="))|([^\s]+))["]{0,1}') {
                $msi_file = $(if ($Matches[1]) { $Matches[1] } else { $Matches[2] })
                Write-Verbose "MSI File: $msi_file"
                Invoke-Msi -Action 'Uninstall' -Path $msi_file
            } else {
                Write-Warning "MSI UninstallString format unrecognized."
            }
        } else {
            if ($ModifyUninstallString) {
                if ($ModifyUninstallString -like '*{0}*') {
                    Invoke-Run -Cmd ($ModifyUninstallString -f $UninstallString)
                } else {
                    Invoke-Run -Cmd "${UninstallString}${ModifyUninstallString}"
                }
            } else {
                if ($AllowAttended) {
                    Invoke-Run -Cmd $UninstallString -WindowStyle 'Normal'
                } else {
                    Write-Warning "Attended uninstalls are not allowed."
                }
            }
        }
    }




    $Wildcard = (-not $Exact) -and (($SearchString -split '') -contains '%')

    Write-Information "Searching WMI ..."
    $op = if ($Wildcard) { 'like' } else { '=' }
    if ($Win32_Product = Get-CimInstance -ClassName 'Win32_Product' -Filter "Name ${op} '${SearchString}'") {
        Write-Information "Found: {Publisher: $($Win32_Product.Vendor); Name: $($Win32_Product.Name); Version: $($Win32_Product.Version); IdentifyingNumber: $($Win32_Product.IdentifyingNumber)}"
        Invoke-Msi -Action 'Uninstall' -Path $Win32_Product.IdentifyingNumber
    }


    Write-Information "Searching Registry ..."

    [hashtable] $get_installedapplication = @{}

    if ($Wildcard) {
        $get_installedapplication.Add('Name', $SearchString.Replace('%','*')) | Out-Null
        $get_installedapplication.Add('Wildcard', $true) | Out-Null
    } else {
        $get_installedapplication.Add('Name', $SearchString) | Out-Null
    }
    if ($Exact) { $get_installedapplication.Add('Exact', $true) | Out-Null }

    foreach ($app in (Get-InstalledApplication @get_installedapplication)) {
        Write-Information "Found: {Publisher: $($app.Publisher); Name: $($app.DisplayName); Version: $($app.DisplayVersion); QuietUninstallString: $($app.QuietUninstallString); UninstallString: $($app.UninstallString)}"
        if ($app.QuietUninstallString) {
            Write-Verbose "Found QuietUninstallString: $($app.QuietUninstallString)"
            Invoke-Run -Cmd $app.QuietUninstallString
        } elseif ($app.UninstallString) {
            Write-Verbose "Found UninstallString: $($app.UninstallString)"
            [hashtable]$_UninstallString = @{}
            $_UninstallString.Add('UninstallString', $app.UninstallString)

            if ($ModifyUninstallString) {
                $_UninstallString.Add('ModifyUninstallString', $ModifyUninstallString)
            }

            if ($AllowAttended) {
                $_UninstallString.Add('AllowAttended', $AllowAttended)
            }

            _UninstallString @_UninstallString
        } else {
            Write-Warning "Unable to determine a method for uninstalling."
        }
    }
}
