#Requires -RunAsAdministrator
<#
.EXAMPLE
New-BaconWim -ImagePath "PSBacon.wim" -CapturePath "PSBacon" -Name "PSBacon"
#>
function New-BaconWim {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true)]
        [IO.FileInfo]
        $ImagePath,

        [Parameter(Mandatory = $true)]
        [IO.DirectoryInfo]
        $CapturePath,

        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [IO.FileInfo]
        $LogFileF
    )

    begin {
        Write-Verbose "[New-BaconWim] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
        Write-Debug "[New-BaconWim] Function Invocation: $($MyInvocation | Out-String)"
    }

    process {
        if (-not $ImagePath.Directory.Exists) {
            New-Item -ItemType 'Directory' -Path $ImagePath.FullName -Force | Out-Null
            $ImagePath.Refresh()
        }

        $windowsImage = @{
            ImagePath = $ImagePath.FullName
            CapturePath = $CapturePath.FullName
            Name = $Name
        }

        if ($LogFileF) {
            $windowsImage.Add('LogPath', ($LogFileF -f 'DISM'))
        }

        if ($WhatIf.IsPresent) {
            Write-Host ('What if: Performing the operation "New-WindowsImage" with parameters: {0}' -f ($windowsImage | ConvertTo-Json))
        } else {
            New-WindowsImage @windowsImage
        }
    }

    end {}
}

# New-BaconWim -ImagePath "PSBacon.wim" -CapturePath "PSBacon" -Name "PSBacon"