<#
.SYNOPSIS
Download an archive (.zip) and expand/extract it.
.DESCRIPTION
This will use download a single archive (.zip) and expand/extract it.

Pipeline is not supported.
.PARAMETER Uri
Specifies the Uniform Resource Identifier (URI) of the Internet resource to which the web request is sent. Enter a URI. This parameter supports HTTP, HTTPS, FTP, and FILE values.

This parameter is required. The parameter name (Uri) is optional.
.PARAMETER ZipFile
If supplied, needs to be the full path of the intended download location.

Default action: download the .zip file to the Temp directory. If the zip filename cannot be derived, generate a random name.
.PARAMETER ZipFilePath
The Path to download to.

Defaults to: $global:Winstall.Temp
.PARAMETER DestinationPath
Specifies the path to the folder in which you want the command to save extracted files. Enter the path to a folder, but do not specify a file name or file name extension.

Default action: create a folder with the name of the ZipFile in the working directory.
.PARAMETER WebClient
Use an existing `System.Net.WebClient` object. For example, the one returned from `Get-WinstallWWWWebClient`.
.PARAMETER DeleteZip
Delete the downloaded .zip file after extraction.

Keep in mind, if the .zip file is downloaded to the default location, the .zip file will be automatically deleted when Winstall exists.
.PARAMETER DoNotForceExpand
Do not add `-Force` to the `Expand-Archive` function.
.PARAMETER ExpandArchiveMaxRetry
Expand-Archive can fail if a virus scanner is locking out the file. We should keep trying for a bit.
Some archives might be massive and require more time to expand, so this allows you to adjust the timeout.
.OUTPUTS
[System.Collections.Hashtable]
@{
    'Uri' = $Uri;
    'ZipFile' = $ZipFile;
    'DestinationPath' = $DestinationPath;
    'ZipDeleted' = $ZipDeleted;
}
.EXAMPLE
# In this example, the ZipFile can be derived as: foo.zip
> [string](Get-Location)
C:\Example\1
> $result = Get-ArchiveAndExpand "ftp://example.com/foo.zip"
> $result
Name                Value
----                ----
DestinationPath     C:\Example\1\foo
Uri                 ftp://example.com/foo.zip
ExpandForced        True
ZipFile             C:\Temp\foo.zip
ZipDeleted          False
.EXAMPLE
# In this example, the ZipFile cannot be derived.
> [string](Get-Location)
C:\Example\2
> $result = Get-ArchiveAndExpand "ftp://example.com/foo.zip?bar=true"
> $result
Name                Value
----                ----
DestinationPath     C:\Example\2\f480091b-bc5a-460b-98a5-d26d6fd7c049
Uri                 ftp://example.com/foo.zip?bar=true
ExpandForced        True
ZipFile             C:\Temp\f480091b-bc5a-460b-98a5-d26d6fd7c049.zip
ZipDeleted          False
.EXAMPLE
# In this example, we supply all the parameters.
> $result = Get-ArchiveAndExpand "ftp://example.com/foo.zip?bar=true" -ZipFile "C:\Temp\3\foo.zip" -DestinationPath "C:\Temp\3\foo" -WebClient (Get-WinstallWWWWebClient) -DeleteZip
> $result
Name                Value
----                ----
DestinationPath     C:\Temp\3\foo
Uri                 ftp://example.com/foo.zip?bar=true
ExpandForced        True
ZipFile             C:\Temp\3\foo.zip
ZipDeleted          True
#>
function Global:Get-ArchiveAndExpand {
    [CmdLetBinding()]
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]
        $Uri
        ,
        [Parameter(Mandatory=$false)]
        [string]
        $ZipFile
        ,
        [Parameter(Mandatory=$false)]
        [string]
        $ZipFilePath = $global:Winstall.Temp
        ,
        [Parameter(Mandatory=$false)]
        [string]
        $DestinationPath
        ,
        [Parameter(Mandatory=$false)]
        [System.Net.WebClient]
        $WebClient
        ,
        [Parameter(Mandatory=$false)]
        [switch]
        $DeleteZip
        ,
        [Parameter(Mandatory=$false)]
        [switch]
        $DoNotForceExpand
        ,
        [Parameter(Mandatory=$false)]
        [int]
        $ExpandArchiveMaxRetry = 15
    )

    Write-Information "[Get-ArchiveAndExpand] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Debug "[Get-ArchiveAndExpand] Function Invocation: $($MyInvocation | Out-String)"
    Write-Debug "[Get-ArchiveAndExpand] Location: $(Get-Location)"


    if (-not $ZipFile) {
        Write-Verbose "[Get-ArchiveAndExpand] ZipFile not passed as a parameter."

        if (([uri]$Uri).Segments[-1].EndsWith('.zip')) {
            $ZipFile = "${ZipFilePath}\$(([uri]$Uri).Segments[-1])"
        } else {
            Write-Verbose "[Get-ArchiveAndExpand] ZipFile doesn't look right, let's just generate a name ..."
            $ZipFile = "${ZipFilePath}\$(New-Guid).zip"
        }

        Write-Verbose "[Get-ArchiveAndExpand] ZipFile: ${ZipFile}"
    }

    if (-not $WebClient) {
        $WebClient = New-Object System.Net.WebClient
    }
    Write-Verbose "[Get-ArchiveAndExpand] System.Net.WebClient: $($WebClient | Out-String)"
    Write-Verbose "[Get-ArchiveAndExpand] System.Net.WebClient DownloadFile: ${Uri}"
    $WebClient.DownloadFile($Uri, $ZipFile)
    Write-Verbose "[Get-ArchiveAndExpand] System.Net.WebClient Downloaded: ${ZipFile}"

    [string]$ZipFile = (Resolve-Path $ZipFile).Path
    Write-Verbose "[Get-ArchiveAndExpand] ZipFile: ${ZipFile}"

    if (-not $DestinationPath) {
        Write-Verbose "[Get-ArchiveAndExpand] DestinationPath not passed as a parameter."

        [string]$DestinationPath = (Split-Path $ZipFile -Leaf) -replace '\.zip$', ''
        Write-Verbose "[Get-ArchiveAndExpand] DestinationPath: ${DestinationPath}"
    }

    Write-Verbose "[Get-ArchiveAndExpand] Ensure DestinationPath exists."
    New-Item -ItemType Directory -Path $DestinationPath -Force | Write-Debug
    [string]$DestinationPath = (Resolve-Path $DestinationPath).Path
    Write-Verbose "[Get-ArchiveAndExpand] DestinationPath: ${DestinationPath}"

    Write-Verbose "[Get-ArchiveAndExpand] Expand-Archive ${ZipFile} to ${DestinationPath}"
    $Expand_Archive = @{
        'LiteralPath' = $ZipFile;
        'DestinationPath' = $DestinationPath;
        'Force' = $true;
        'ErrorAction' = 'Stop';
    }

    if ($DoNotForceExpand) {
        $Expand_Archive.Set_Item('Force', $false)
    }

    for ($i = 1; $i -le ($ExpandArchiveMaxRetry + 1); $i++) {
        try {
            Expand-Archive @Expand_Archive | Out-Null
            break
        } catch [System.Management.Automation.MethodInvocationException] {
            if ($i -ne ($ExpandArchiveMaxRetry + 1)) {
                Write-Warning "[Get-ArchiveAndExpand] $($Error[0].Exception.Message)"
                Write-Information ('[Get-ArchiveAndExpand] Will try again in {0} seconds ...' -f $i)
                Start-Sleep -Seconds $i
            } else {
                Throw $Error[0]
            }
            
        }
    }
    Write-Verbose "[Get-ArchiveAndExpand] Expand-Archive done."

    if ($DeleteZip) {
        Write-Verbose "[Get-ArchiveAndExpand] DeleteZip passed as a parameter."

        Write-Verbose "[Get-ArchiveAndExpand] Remove-Item: ${ZipFile}"
        Remove-Item $ZipFile -Force
        $ZipDeleted = $true
    } else {
        $ZipDeleted = $false
    }

    $return = @{
        'DestinationPath' = $DestinationPath;
        'Uri' = $Uri;
        'ExpandForced' = $Expand_Archive.Force;
        'ZipDeleted' = $ZipDeleted;
        'ZipFile' = $ZipFile;
    }
    Write-Information "[Get-ArchiveAndExpand] Return: $($return | ConvertTo-Json)"
    return $return
}