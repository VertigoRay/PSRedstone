function Get-RedstoneExeFileInfo {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    Write-Information "[Get-RedstoneExeFileInfo] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Debug "[Get-RedstoneExeFileInfo] Function Invocation: $($MyInvocation | Out-String)"

    if (([IO.FileInfo] $Path).Exists) {
        $result = $Path
    } elseif ($command = Get-Command $Path -ErrorAction 'Ignore') {
        $result = $command.Source
    } else {
        $appPath = ('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\{0}' -f $Path)
        if ($defaultPath = (Get-ItemProperty $appPath -ErrorAction 'Ignore').'(default)') {
            $result = $defaultPath
        } else {
            Write-Warning ('EXE file location not discoverable: {0}' -f $Path)
            $result = $Path
        }
    }
    return ([IO.FileInfo] $result.Trim('"'))
}
