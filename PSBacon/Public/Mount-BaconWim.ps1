<#
.EXAMPLE
try {
    Mount-BaconWim
    
    ... do some things ...
} catch {

} finall {
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
        $ImageIndex = 1
    )
    
    begin {
        Write-Information "[Mount-BaconWim] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
        Write-Debug "[Mount-BaconWim] Function Invocation: $($MyInvocation | Out-String)"

        function Invoke-ForceEmptyDirectory {
            [CmdletBinding()]
            param (
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
                [IO.DirectoryInfo]
                $Path
            )

            if (-not $Path.Exists) {
                New-Item -ItemType 'Directory' -Path $Path.FullName -Force | Out-Null
                $Path.Refresh()
            } else { # Path Exists
                if ((Get-ChildItem 'BaconMount' | Measure-Object).Count) {
                    # Path (Directory) is NOT empty.
                    try {
                        $Path.FullName | Remove-Item -Recurse -Force
                    } catch [System.ComponentModel.Win32Exception] {
                        if ($_.Exception.Message -eq 'Access to the cloud file is denied') {
                            Write-Warning ('[{0}] {1}' -f $_.Exception.GetType().FullName, $_.Exception.Message)
                            # It seems the problem comes from a directory, not the files themselves,
                            # so using a small workaround using Get-ChildItem to list and then delete
                            # all files helps to get rid of all files.
                            foreach ($item in (Get-ChildItem -LiteralPath $Path.FullName -File -Recurse)) {
                                Remove-Item -LiteralPath $item.Fullname -Recurse -Force
                            }
                        } else {
                            Throw $_
                        }
                    }
                    New-Item -ItemType 'Directory' -Path $Path.FullName -Force | Out-Null
                    $Path.Refresh()
                }
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
        Write-Verbose "[Mount-BaconWim] Mount-WindowImage: $($windowsImage | ConvertTo-Json)"
        Mount-WindowsImage @windowsImage
    }
    
    end {
        
    }
}

Mount-BaconWim -ImagePath "$pwd\PSBacon.wim"