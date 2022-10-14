$psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
Write-Debug ('psProjectRoot: {0}' -f $psProjectRoot)

. ('{0}\PSBacon\Public\New-BaconWim.ps1' -f $psProjectRoot.FullName)

[bool] $isElevated = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

Describe 'New-BaconWim' {
    Context 'dev\PSBacon.wim' {
        It 'Should be elevated to create WIMs' {
            $isElevated | Should Be $true
        }

        if ($isElevated) {
            $imagePath = '{0}\dev\PSBacon.wim' -f $psProjectRoot.FullName
            $capturePath = '{0}\PSBacon' -f $psProjectRoot.FullName

            if (Test-Path $imagePath) {
                Remove-Item $imagePath -Force
            }

            It ('WIM does not already exist: {0}' -f $imagePath) {
                Test-Path $imagePath | Should Be $false
            }

            New-BaconWim -ImagePath $imagePath -CapturePath $capturePath -Name 'PSBacon'

            It ('WIM Created: {0}' -f $imagePath) {
                Test-Path $imagePath | Should Be $true
            }
        }
    }

    Context 'Several Images' {
        $severalImages = @(
            @{
                ImagePath = '{0}\dev\PSBacon2.wim' -f $psProjectRoot.FullName
                CapturePath = '{0}\PSBacon' -f $psProjectRoot.FullName
                Name = 'PSBacons'
            },
            @{
                ImagePath = '{0}\dev\Tests.wim' -f $psProjectRoot.FullName
                CapturePath = '{0}\Tests' -f $psProjectRoot.FullName
                Name = 'Pester Tests'
            }
        )

        foreach ($image in $severalImages) {
            if (Test-Path $image.ImagePath) {
                Remove-Item $image.ImagePath -Force
            }

            It 'WIM does not already exist' {
                Test-Path $image.ImagePath | Should Be $false
            }
        }

        $severalImages | New-BaconWim

        foreach ($image in $severalImages) {
            It ('WIM Created: {0}' -f $image.ImagePath) {
                Test-Path $image.ImagePath | Should Be $true
            }
        }
    }
}
