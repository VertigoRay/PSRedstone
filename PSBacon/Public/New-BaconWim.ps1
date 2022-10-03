<#
.EXAMPLE
New-BaconWim -ImagePath "PSBacon.wim" -CapturePath "PSBacon" -Name "PSBacon"

.EXAMPLE
$severalImages = @(
    @{
        ImagePath = "f:\CADWIM\Files.wim"
        CapturePath = "f:\CADWIM\Files"
        Name = "InstallerSources"
    },
    @{
        ImagePath = "f:\CADWIM2\Files.wim"
        CapturePath = "f:\CADWIM2\Files"
        Name = "InstallerSources2"
    }
)

$severalImages | New-BaconWim
#>
function New-BaconWim {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Individual'
        )]
        [IO.FileInfo]
        $ImagePath,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Individual'
        )]
        [IO.DirectoryInfo]
        $CapturePath,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Individual'
        )]
        [String]
        $Name,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Piped',
            ValueFromPipeline = $true
        )]
        [hashtable[]]
        $WimInstructions
    )

    
    begin {
        Write-Information "[New-BaconWim] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
        Write-Debug "[New-BaconWim] Function Invocation: $($MyInvocation | Out-String)"
    }
    
    process {
        if ($PSCmdlet.ParameterSetName -eq 'Individual') {
            New-WindowsImage -ImagePath $ImagePath -CapturePath $CapturePath -Name $Name
        } else { # Piped
            foreach ($wimInstruction in $WimInstructions) {
                New-WindowsImage @imageInstruction
            }
        }
    }
    
    end {
        
    }
}

New-BaconWim -ImagePath "PSBacon.wim" -CapturePath "PSBacon" -Name "PSBacon"