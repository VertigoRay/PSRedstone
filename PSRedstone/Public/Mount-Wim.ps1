#Requires -RunAsAdministrator
<#
.EXAMPLE
Mount-Wim
.LINK
https://github.com/VertigoRay/PSRedstone/wiki/Functions#mount-wim
#>
function Mount-Wim {
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
        $MountPath = ([IO.Path]::Combine($env:Temp, 'RedstoneMount')),

        [Parameter(Mandatory = $false)]
        [int]
        $ImageIndex = 1,

        [Parameter(Mandatory = $false)]
        [IO.FileInfo]
        $LogFileF
    )

    begin {
        Write-Verbose "[Mount-Wim] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
        Write-Debug "[Mount-Wim] Function Invocation: $($MyInvocation | Out-String)"
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
    }

    end {}
}
#region DEVONLY
# Mount-Wim -ImagePath "$pwd\PSRedstone.wim"
#endregion
