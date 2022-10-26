#Requires -RunAsAdministrator
<#
.EXAMPLE
try {
    Mount-BaconWim

    ... do some things ...
} catch {

} finally {
    Dismount-BaconWim
}
#>
function Mount-BaconWim {
    [CmdletBinding()]
    param (
        # Specifies a path to one or more locations.
        [Parameter(
            Mandatory=$true,
            Position=0,
            ParameterSetName="ParameterSetName",
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage="Path to one or more locations."
        )]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]
        $ImagePath,

        # Specifies a path to one or more locations.
        [Parameter(
            Mandatory=$false,
            Position=0,
            ParameterSetName="ParameterSetName",
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage="Path to one or more locations."
        )]
        [ValidateNotNullOrEmpty()]
        [IO.DirectoryInfo]
        $MountPath = (Join-Path $PWD 'BaconMount'),

        [Parameter(Mandatory = $false)]
        [int]
        $ImageIndex = 1,

        [Parameter(Mandatory = $true)]
        [IO.FileInfo]
        $LogFileF
    )

    begin {
        Write-Verbose "[Mount-BaconWim] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
        Write-Debug "[Mount-BaconWim] Function Invocation: $($MyInvocation | Out-String)"
    }

    process {
        # $MyInvocation
        # $MountPath.FullName
        $MountPath.FullName | Invoke-BaconForceEmptyDirectory
        $MountPath.Refresh()

        $windowsImage = @{
            ImagePath = $ImagePath.FullName
            Index = $ImageIndex
            Path = $MountPath.FullName
        }

        if ($LogFileF) {
            $windowsImage.Add('LogPath', ($LogFileF -f 'DISM'))
        }

        Write-Verbose "[Mount-BaconWim] Mount-WindowImage: $($windowsImage | ConvertTo-Json)"
        Mount-WindowsImage @windowsImage
    }

    end {}
}

# Mount-BaconWim -ImagePath "$pwd\PSBacon.wim"