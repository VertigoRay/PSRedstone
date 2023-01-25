#Requires -RunAsAdministrator
<#
.EXAMPLE
New-Wim -ImagePath 'PSRedstone.wim' -CapturePath 'PSRedstone' -Name 'PSRedstone'
.LINK
https://github.com/VertigoRay/PSRedstone/wiki/Functions#new-wim
#>
function New-Wim {
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

        [Parameter(Mandatory = $false)]
        [IO.FileInfo]
        $LogFileF
    )

    begin {
        Write-Verbose "[New-Wim] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
        Write-Debug "[New-Wim] Function Invocation: $($MyInvocation | Out-String)"
    }

    process {
        if (-not $ImagePath.Directory.Exists) {
            New-Item -ItemType 'Directory' -Path $ImagePath.Directory.FullName -Force | Out-Null
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
            Write-Information ('What if: Performing the operation "New-WindowsImage" with parameters: {0}' -f ($windowsImage | ConvertTo-Json)) -InformationAction Continue
        } else {
            New-WindowsImage @windowsImage
        }
    }

    end {}
}
#region DEVONLY
# New-Wim -ImagePath "PSRedstone.wim" -CapturePath "PSRedstone" -Name "PSRedstone"
#endregion
