<#
.SYNOPSIS
Download Zip from Winstall WWW.
.DESCRIPTION
Download Zip file from Winstall WWW to the supplied DestinationPath.
.PARAMETER Uri
URI of the .zip file to download.

Default: $global:Winstall.Cache.URI.Zip
.PARAMETER Name
The Cache Name; such as: example-1.2.3.4-1234asdf1234asdf1234asdf1234asdf
This is what is returned from the initial call to Winstall WWW.

Default: $global:Winstall.Cache.Name
.PARAMETER DestinationPath
The path (directory) to download the .zipfile to.

Default: $global:Winstall.Settings.Cache.Folder
.OUTPUTS
[System.Management.Automation.PathInfo]
.EXAMPLE
> $result = Get-WinstallCacheFile
> $result

Path
----
C:\Temp\Winstall\example-1.2.3.4-1234asdf1234asdf1234asdf1234asdf.zip
#>
function global:Get-WinstallCacheFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]
        $Uri = $global:Winstall.Cache.URI.Zip
        ,
        [Parameter(Mandatory=$false)]
        [string]
        $Name = $global:Winstall.Cache.Name
        ,
        [Parameter(Mandatory=$false)]
        [string]
        $DestinationPath = $global:Winstall.Settings.Cache.Folder
    )

    Write-Information "> $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Debug "Function Invocation: $($MyInvocation | Out-String)"


    $local_zip = "{0}\{1}.zip" -f $DestinationPath, $Name
    Write-Verbose "Local Zip: ${local_zip}"
    Write-Verbose "Ensuring DestinationPath exists ..."
    New-Item -ItemType Directory $DestinationPath -Force | Out-Debug

    $webclient = Get-WinstallWWWWebClient
    Write-Verbose "WebClient: ${webclient}"
    try {
        Write-Verbose "WebClient DownloadFile: ${Uri}"
        $webclient.DownloadFile($Uri, $local_zip)
        Write-Verbose "WebClient Downloaded: ${ZipFile}"
    } catch {
        Write-Error $_.Exception.Message
    }

    $return = Resolve-Path $local_zip
    Write-Information "Return: $($return | Out-String)"
    return $return
}