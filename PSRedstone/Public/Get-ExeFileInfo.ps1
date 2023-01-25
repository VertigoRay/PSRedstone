<#
.SYNOPSIS
Attempt to find the EXE in the provided Path.
.DESCRIPTION
This functions will go through three steps to find the provided EXE:

- Determine if you provided the full path to the EXE or if it's in the current directory.
- Determine if it can be found under any path in $env:PATH.
- Determine if the locations was registered in the registry.

If one of these is true, it'll stop looking and return the `IO.FileInfo` of the EXE.
.OUTPUTS
[IO.FileInfo]
.EXAMPLE
Get-ExeFileInfo 'notepad.exe'
.EXAMPLE
Get-ExeFileInfo 'chrome.exe'
.LINK
https://github.com/VertigoRay/PSRedstone/wiki/Functions#get-exefileinfo
#>
function Get-ExeFileInfo {
    [CmdletBinding()]
    [OutputType([IO.FileInfo])]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'Name of the EXE to search for.')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if (([IO.FileInfo] $_).Extension -eq '.exe') {
                Write-Output $true
            } else {
                Throw ('The Path "{0}" has an unexpected extension "{1}"; expecting ".exe".' -f @(
                    $_
                    ([IO.FileInfo] $_).Extension
                ))
            }
        })]
        [string]
        $Path
    )

    Write-Information "[Get-ExeFileInfo] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Debug "[Get-ExeFileInfo] Function Invocation: $($MyInvocation | Out-String)"

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
