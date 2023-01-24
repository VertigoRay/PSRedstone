#Requires -RunAsAdministrator
<#
.EXAMPLE
Mount-RedstoneWim
.LINK
https://github.com/VertigoRay/PSRedstone/wiki/Functions#mount-redstonewim
#>
function Mount-RedstoneWim {
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
        Write-Verbose "[Mount-RedstoneWim] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
        Write-Debug "[Mount-RedstoneWim] Function Invocation: $($MyInvocation | Out-String)"
    }

    process {
        # $MyInvocation
        # $MountPath.FullName
        $MountPath.FullName | Invoke-RedstoneForceEmptyDirectory
        $MountPath.Refresh()

        $windowsImage = @{
            ImagePath = $ImagePath.FullName
            Index = $ImageIndex
            Path = $MountPath.FullName
        }

        if ($LogFileF) {
            $windowsImage.Add('LogPath', ($LogFileF -f 'DISM'))
        }

        Write-Verbose "[Mount-RedstoneWim] Mount-WindowImage: $($windowsImage | ConvertTo-Json)"
        Mount-WindowsImage @windowsImage
    }

    end {}
}
#region DEVONLY
# Mount-RedstoneWim -ImagePath "$pwd\PSRedstone.wim"
#endregion
