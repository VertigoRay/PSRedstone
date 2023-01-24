<#
.SYNOPSIS
Download a file and validate the checksum.
.DESCRIPTION
Download a file; use a few methods based on performance preference testing:

- `Start-BitsTransfer`
- `Net.WebClient`
- `Invoke-WebRequest`

If the first one fails, the next one will be tried. Target directory will be automatically created.
A checksum will be validated if it is supplied.
.PARAMETER Uri
Uri to the File to be downloaded.
.PARAMETER OutFile
The full path of the file to be downloaded.
.PARAMETER OutFolder
Folder where you want the file to go. If this is specified, the file name is derived from the last segment of the Uri parameter.
.PARAMETER Checksum
A string containing the Algorithm and the Hash separated by a colon.
For example: "SHA256:AA24A85644ECCCAD7098327899A3C827A6BE2AE1474C7958C1500DCD55EE66D8"

The algorithm should be a valid algorithm recognized by `Get-FileHash`.
.EXAMPLE
Invoke-RedstoneDownload 'https://download3.vmware.com/software/CART23FQ4_WIN_2212/VMware-Horizon-Client-2212-8.8.0-21079405.exe' -OutFile (Join-Path $env:Temp 'VMware-Horizon-Client-2212-8.8.0-21079405.exe')
.EXAMPLE
Invoke-RedstoneDownload 'https://download3.vmware.com/software/CART23FQ4_WIN_2212/VMware-Horizon-Client-2212-8.8.0-21079405.exe' -OutFolder $env:Temp
.EXAMPLE
Invoke-RedstoneDownload 'https://download3.vmware.com/software/CART23FQ4_WIN_2212/VMware-Horizon-Client-2212-8.8.0-21079405.exe' -OutFolder $env:Temp -Checksum 'sha256:a0bac35619328f5f9aa56508572f343f7a388286768b31ab95377c37b052e5ac'
.LINK
https://github.com/VertigoRay/PSRedstone/wiki/Functions#invoke-redstonedownload
#>
function Invoke-RedstoneDownload {
    [CmdletBinding(DefaultParameterSetName = 'OutFile')]
    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'OutFile')]
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'OutFolder')]
        [ValidateNotNullOrEmpty()]
        [uri]
        $Uri,

        [Parameter(Mandatory = $true, ParameterSetName = 'OutFile')]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]
        $OutFile,

        [Parameter(Mandatory = $true, ParameterSetName = 'OutFolder')]
        [ValidateNotNullOrEmpty()]
        [IO.DirectoryInfo]
        $OutFolder,

        [Parameter(Mandatory = $false, ParameterSetName = 'OutFile', HelpMessage = 'A string containing the Algorithm and the Hash separated by a colon.')]
        [Parameter(Mandatory = $false, ParameterSetName = 'OutFolder', HelpMessage = 'A string containing the Algorithm and the Hash separated by a colon.')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if ($_.Split(':', 2)[0] -in (Get-Command 'Microsoft.PowerShell.Utility\Get-FileHash').Parameters.Algorithm.Attributes.ValidValues) {
                Write-Output $true
            } else {
                Throw ('The first part ("{1}") of argument "{0}" does not belong to the set specified by Get-FileHash''s Algorithm parameter. Supply a first part "{1}" that is in the set "{2}" and then try the command again.' -f @(
                    $_
                    $_.Split(':', 2)[0]
                    ((Get-Command 'Microsoft.PowerShell.Utility\Get-FileHash').Parameters.Algorithm.Attributes.ValidValues -join ', ')
                ))
            }
        })]
        [string]
        $Checksum
    )

    Write-Information ('[Invoke-RedstoneDownload] > {0}' -f ($MyInvocation.BoundParameters | ConvertTo-Json -Compress))
    Write-Debug ('[Invoke-RedstoneDownload] Function Invocation: {0}' -f ($MyInvocation | Out-String))

    if ($PSCmdlet.ParameterSetName -eq 'OutFolder') {
        [IO.FileInfo] $OutFile = [IO.Path]::Combine($OutFolder.FullName, $Uri.Segments[-1])
    }

    if (-not $OutFile.Directory.Exists) {
        New-Item -ItemType 'Directory' -Path $OutFile.Directory.FullName | Out-Null
        Write-Verbose ('[Invoke-RedstoneDownload] Directory created: {0}' -f $OutFile.Directory.FullName)
    }

    $startBitsTransfer = @{
        Source      = $Uri.AbsoluteUri
        Destination = $OutFile.FullName
        ErrorAction = 'Stop'
    }
    Write-Verbose ('[Invoke-RedstoneDownload] startBitsTransfer: {0}' -f ($startBitsTransfer | ConvertTo-Json))

    try {
        Start-BitsTransfer @startBitsTransfer
    } catch {
        Write-Warning ('[Invoke-RedstoneDownload] BitsTransfer Failed: {0}' -f $_)
        try {
            (New-Object Net.WebClient).DownloadFile($startBitsTransfer.Source, $startBitsTransfer.Destination)
        } catch {
            Write-Warning ('[Invoke-RedstoneDownload] WebClient Failed: {0}' -f $_)
            Invoke-WebRequest -Uri $startBitsTransfer.Source -OutFile $startBitsTransfer.Destination
        }
    }

    if ($Checksum) {
        $hash = Get-FileHash -LiteralPath $startBitsTransfer.Destination -Algorithm $Checksum.Algorithm
        Write-Verbose ('[Invoke-RedstoneDownload] Downloaded File Hash: {0}' -f ($hash | ConvertTo-Json))

        if ($Checksum.Hash -ne $hash.Hash) {
            Remove-Item -LiteralPath $startBitsTransfer.Destination -Force
            Throw ('Unexpected Hash; Downloaded file deleted!')
        }
    }

    $OutFile.Refresh()
    return $OutFile
}
