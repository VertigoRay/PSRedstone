function Invoke-BaconDownload {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [uri]
        $Uri,

        [Parameter(Mandatory = $true)]
        [IO.FileInfo]
        $OutFile
    )

    Write-Verbose ('[Invoke-BaconDownload] MyInvocation: {0}' -f ($MyInvocation | Out-String))
    
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
}
