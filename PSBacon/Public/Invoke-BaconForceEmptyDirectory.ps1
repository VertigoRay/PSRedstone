<#
.EXAMPLE
$MountPath.FullName | Invoke-BaconForceEmptyDirectory
#>
function Invoke-BaconForceEmptyDirectory {
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

    begin {}

    process {
        foreach ($p in $Path) {
            if (-not $p.Exists) {
                New-Item -ItemType 'Directory' -Path $p.FullName -Force | Out-Null
                $p.Refresh()
            } else { # Path Exists
                if ((Get-ChildItem $p.FullName | Measure-Object).Count) {
                    # Path (Directory) is NOT empty.
                    try {
                        $p.FullName | Remove-Item -Recurse -Force
                    } catch [System.ComponentModel.Win32Exception] {
                        if ($_.Exception.Message -eq 'Access to the cloud file is denied') {
                            Write-Warning ('[{0}] {1}' -f $_.Exception.GetType().FullName, $_.Exception.Message)
                            # It seems the problem comes from a directory, not the files themselves,
                            # so using a small workaround using Get-ChildItem to list and then delete
                            # all files helps to get rid of all files.
                            foreach ($item in (Get-ChildItem -LiteralPath $p.FullName -File -Recurse)) {
                                Remove-Item -LiteralPath $item.Fullname -Recurse -Force
                            }
                        } else {
                            Throw $_
                        }
                    }
                    New-Item -ItemType 'Directory' -Path $p.FullName -Force | Out-Null
                    $p.Refresh()
                }
            }
        }
    }

    end {}
}
