Describe 'BaconWim' -Tag 'WIM' {
    [IO.FileInfo] $capturePath = '{0}\PSBacon' -f $psProjectRoot.FullName
    [IO.FileInfo] $imagePath = '{0}\devPSBacon\PSBacon.wim' -f 'TestDrive:'
    [IO.FileInfo] $mountPath = '{0}\dev\Mount_PSBacon' -f 'TestDrive:'
    [bool] $isElevated = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

    BeforeAll {
        $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
        Write-Debug ('psProjectRoot: {0}' -f $psProjectRoot)

        if ($isElevated) {
            . ('{0}\PSBacon\Public\Dismount-BaconWim.ps1' -f $psProjectRoot.FullName)
            . ('{0}\PSBacon\Public\Mount-BaconWim.ps1' -f $psProjectRoot.FullName)
            . ('{0}\PSBacon\Public\New-BaconWim.ps1' -f $psProjectRoot.FullName)
        }
        . ('{0}\PSBacon\Public\Invoke-BaconForceEmptyDirectory.ps1' -f $psProjectRoot.FullName)
    }

    Context 'NEW' {
        It 'Should be elevated to create WIMs' {
            $isElevated | Should -Be $true
        }

        if ((New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
            if (Test-Path $imagePath) {
                Remove-Item $imagePath -Force
            }

            Write-Host ($imagePath | Select *) -ForegroundColor 'Cyan'

            It ('WIM does not already exist: {0}' -f $imagePath) {
                Test-Path $imagePath | Should -Be $false
            }

            New-BaconWim -ImagePath $imagePath -CapturePath $capturePath -Name 'PSBacon'

            It ('WIM Created: {0}' -f $imagePath) {
                Test-Path $imagePath | Should -Be $true
            }
        }
    }

    Context 'MOUNT' {
        It 'Should be elevated to mount WIMs' {
            $isElevated | Should -Be $true
        }

        if ($isElevated) {
            if (Test-Path $mountPath) {
                Remove-Item $mountPath -Recurse -Force
            }

            It ('Mount path does not already exist: {0}' -f $mountPath) {
                Test-Path $mountPath | Should -Be $false
            }

            Mount-BaconWim -ImagePath $imagePath -MountPath $mountPath

            It ('WIM mounted: {0}' -f $mountPath) {
                Test-Path $mountPath | Should -Be $true
            }
        }
    }

    Context 'DISMOUNT' {
        It 'Should be elevated to dismount WIMs' {
            $isElevated | Should -Be $true
        }

        if ($isElevated) {
            It ('Mount path already exist: {0}' -f $mountPath) {
                Test-Path $mountPath | Should -Be $true
            }

            Write-Host "Dismount-BaconWim -MountPath '${mountPath}'" -Fore Cyan
            Dismount-BaconWim -MountPath $mountPath

            It ('WIM dismounted: {0}' -f $mountPath) {
                Test-Path $mountPath | Should -Be $false
            }

            It ('WIM dismounted 2: {0}' -f $mountPath) {
                Get-ChildItem $mountPath | Should -Be $false
            }
        }
    }
}
