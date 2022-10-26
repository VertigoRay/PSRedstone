function Invoke-BaconDownload {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [uri]
        $Uri,

        [Parameter()]
        [IO.FileInfo]
        $OutFile,

        [Parameter()]
        [IO.DirectoryInfo]
        $OutFolder,

        [Parameter()]
        [hashtable]
        $Checksum
    )

    Write-Debug ('[Invoke-BaconDownload] MyInvocation: {0}' -f ($MyInvocation | Out-String))

    if (-not $OutFile.Directory.Exists -and -not $OutFolder.Exists) {
        $directory = if ($OutFile) { $OutFile.DirectoryName } else { $OutFolder.FullName }
        New-Item -Path $directory -ItemType Directory
    }

    if ($OutFolder) {
        [IO.FileInfo] $OutFile = Join-Path $OutFolder.FullName $Uri.Segments[-1]
    }

    $startBitsTransfer = @{
        Source      = $Uri.AbsoluteUri
        Destination = $OutFile.FullName
        ErrorAction = 'Stop'
    }
    Write-Verbose ('[Invoke-BaconDownload] startBitsTransfer: {0}' -f ($startBitsTransfer | ConvertTo-Json))

    try {
        Start-BitsTransfer @startBitsTransfer
    } catch {
        Write-Warning ('[Invoke-BaconDownload] BitsTransfer Failed: {0}' -f $_)
        try {
            (New-Object Net.WebClient).DownloadFile($startBitsTransfer.Source, $startBitsTransfer.Destination)
        } catch {
            Write-Warning ('[Invoke-BaconDownload] WebClient Failed: {0}' -f $_)
            Invoke-WebRequest -Uri $startBitsTransfer.Source -OutFile $startBitsTransfer.Destination
        }
    }

    if ($Checksum) {
        $hash = Get-FileHash -LiteralPath $startBitsTransfer.Destination -Algorithm $Checksum.Algorithm
        Write-Verbose ('[Invoke-BaconDownload] Downloaded File Hash: {0}' -f ($hash | ConvertTo-Json))

        if ($Checksum.Hash -ne $hash.Hash) {
            Remove-Item -LiteralPath $startBitsTransfer.Destination -Force
            Throw ('Unexpected Hash; Downloaded file deleted!')
        }
    }

    $OutFile.Refresh()
    return $OutFile
}
