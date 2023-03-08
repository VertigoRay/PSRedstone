#Requires -RunAsAdministrator
<#
.SYNOPSIS
Mount a WIM.
.DESCRIPTION
Mount a WIM to the provided mount path or one will be generated.
Automatically dismount the WIM when PowerShell exists, unless explicitly told to not auto-dismount.
.EXAMPLE
$mountPath = Mount-Wim -ImagePath thing.wim

This will mount to a unique folder in %TEMP%, returning the mounted path.
.EXAMPLE
Mount-RedstoneWim -ImagePath thing.wim -MountPath [IO.Path]::Combine($PSScriptRoot, $wim.BaseName)
.LINK
https://github.com/VertigoRay/PSRedstone/wiki/Functions#mount-wim
#>
function Mount-Wim {
    [CmdletBinding()]
    [OutputType([IO.DirectoryInfo])]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'Path to the WIM file.')]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]
        $ImagePath,

        [Parameter(Mandatory = $false, Position = 1, HelpMessage = 'Path the WIM will be mounted.')]
        [ValidateNotNullOrEmpty()]
        [IO.DirectoryInfo]
        $MountPath = [IO.Path]::Combine($env:TEMP, 'RedstoneMount', (New-Guid).Guid),

        [Parameter(Mandatory = $false, HelpMessage = 'Image index to mount.')]
        [int]
        $ImageIndex = 1,

        [Parameter(Mandatory = $false, HelpMessage = 'Do not auto-dismount when PowerShell exits.')]
        [switch]
        $DoNotAutoDismount,

        [Parameter(Mandatory = $false, HelpMessage = 'Full path for the DISM log with {0} formatter to inject "DISM".')]
        [IO.FileInfo]
        $LogFileF
    )

    begin {
        Write-Verbose "[Mount-Wim] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
        Write-Debug "[Mount-Wim] Function Invocation: $($MyInvocation | Out-String)"

        if (-not $DoNotAutoDismount.IsPresent) {
            Register-EngineEvent 'PowerShell.Exiting' -SupportEvent -Action {
                Dismount-Wim -MountPath $MountPath
            }
        }
    }

    process {
        # $MyInvocation
        # $MountPath.FullName
        $MountPath.FullName | Invoke-ForceEmptyDirectory
        $MountPath.Refresh()

        $windowsImage = @{
            ImagePath = $ImagePath.FullName
            Index = $ImageIndex
            Path = $MountPath.FullName
        }

        if ($LogFileF) {
            $windowsImage.Add('LogPath', ($LogFileF -f 'DISM'))
        }

        Write-Verbose "[Mount-Wim] Mount-WindowImage: $($windowsImage | ConvertTo-Json)"
        Mount-WindowsImage @windowsImage
        $MountPath.Refresh()

        return $MountPath
    }

    end {}
}
#region DEVONLY
# Mount-Wim -ImagePath "$pwd\PSRedstone.wim"
#endregion
