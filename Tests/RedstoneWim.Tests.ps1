Describe 'RedstoneWim' -Tag 'WIM' {
    [IO.FileInfo] $capturePath = [IO.Path]::Combine($psProjectRoot.FullName, 'PSRedstone')
    $imagePath = [IO.Path]::Combine('TestDrive:', 'dev', 'PSRedstone', 'PSRedstone.wim')
    $mountPath = [IO.Path]::Combine('TestDrive:', 'dev', 'Mount_PSRedstone')
    [bool] $script:isElevated = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

    BeforeAll {
        $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
        Write-Debug ('psProjectRoot: {0}' -f $psProjectRoot)

        if ($isElevated) {
            . ('{0}\PSRedstone\Public\Dismount-RedstoneWim.ps1' -f $psProjectRoot.FullName)
            . ('{0}\PSRedstone\Public\Mount-RedstoneWim.ps1' -f $psProjectRoot.FullName)
            . ('{0}\PSRedstone\Public\New-RedstoneWim.ps1' -f $psProjectRoot.FullName)
        }
        . ('{0}\PSRedstone\Public\Invoke-RedstoneForceEmptyDirectory.ps1' -f $psProjectRoot.FullName)
    }

    Context 'NEW' {
        It 'Should be elevated to create WIMs' {
            (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator) | Should -Be $true
        }

        if ((New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
            if (Test-Path $imagePath) {
                Remove-Item $imagePath -Force
            }

            Write-Host ($imagePath | Select-Object *) -ForegroundColor 'Cyan'

            It ('WIM does not already exist: {0}' -f $imagePath) {
                Test-Path $imagePath | Should -Be $false
            }

            New-RedstoneWim -ImagePath $imagePath -CapturePath $capturePath -Name 'PSRedstone'

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

            Mount-RedstoneWim -ImagePath $imagePath -MountPath $mountPath

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

            Write-Host "Dismount-RedstoneWim -MountPath '${mountPath}'" -Fore Cyan
            Dismount-RedstoneWim -MountPath $mountPath

            It ('WIM dismounted: {0}' -f $mountPath) {
                Test-Path $mountPath | Should -Be $false
            }

            It ('WIM dismounted 2: {0}' -f $mountPath) {
                Get-ChildItem $mountPath | Should -Be $false
            }
        }
    }
}
