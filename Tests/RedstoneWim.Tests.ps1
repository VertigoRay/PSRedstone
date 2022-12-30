BeforeAll {
    [IO.DirectoryInfo] $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
    Write-Information ('[BeforeAll] psProjectRoot: {0}' -f $psProjectRoot)

    [bool] $script:isElevated = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    Write-Information ('[BeforeAll] PowerShell is Elevated: {0}' -f $script:isElevated)

    if ($script:isElevated) {
        $imports = @(
            '{0}\PSRedstone\Public\Dismount-RedstoneWim.ps1'
            '{0}\PSRedstone\Public\Invoke-RedstoneForceEmptyDirectory.ps1'
            '{0}\PSRedstone\Public\Mount-RedstoneWim.ps1'
            '{0}\PSRedstone\Public\New-RedstoneWim.ps1'
        )

        foreach ($import in $imports) {
            Write-Information ('[BeforeAll] Importing: {0}' -f ($import -f $psProjectRoot.FullName))
            . ($import -f $psProjectRoot.FullName)
        }
    }

    Write-Information ('[BeforeAll] Redstone Commands: {0}' -f (Get-Command '*-Redstone*' | Out-String))

    [IO.DirectoryInfo] $capturePath = [IO.Path]::Combine($psProjectRoot.FullName, 'PSRedstone')
    Write-Information ('[BeforeAll] RedstoneWim CapturePath: [{1}] {0}' -f $capturePath.FullName, $capturePath.GetType().FullName)

    # Comment `[string] $TestDrive` out to use default Pester Test location.
    #    More Info: https://pester.dev/docs/usage/testdrive#compare-with-literal-path
    [string] $TestDrive = [IO.Path]::Combine($psProjectRoot.FullName, 'dev')
    Write-Information ('[BeforeAll] Pester TestDrive: {0}' -f $TestDrive)

    [IO.FileInfo] $imagePath = [IO.Path]::Combine($TestDrive, 'PSRedstone', 'PSRedstone.wim')
    Write-Information ('[BeforeAll] RedstoneWim Image Path: [{1}] {0}' -f $imagePath.FullName, $imagePath.GetType().FullName)

    [IO.DirectoryInfo] $mountPath = [IO.Path]::Combine($TestDrive, 'Mount_PSRedstone')
    Write-Information ('[BeforeAll] RedstoneWim Mount Path: [{1}] {0}' -f $mountPath.FullName, $mountPath.GetType().FullName)
}

AfterAll {
    Write-Information ('[AfterAll] RedstoneWim Image Path: [{1}] {0}' -f $imagePath.FullName, $imagePath.GetType().FullName)
    if ($imagePath.Exists) {
        Write-Information ('[AfterAll] Deleting Image Path...')
        Remove-Item $imagePath.FullName -Force
    }

    Write-Information ('[AfterAll] RedstoneWim Mount Path: [{1}] {0}' -f $mountPath.FullName, $mountPath.GetType().FullName)
    if ($mountPath.Exists) {
        Write-Information ('[AfterAll] Deleting Mount Path...')
        Remove-Item $mountPath.FullName -Recurse -Force
    }
}

Describe 'RedstoneWim' -Tag 'WIM' {
    if ($script:isElevated) {
        Context 'NEW' {
            BeforeAll {
                Write-Information ('[Context NEW BeforeAll] RedstoneWim Image Path: [{1}] {0}' -f $imagePath.FullName, $imagePath.GetType().FullName)
                if ($imagePath.Exists) {
                    Remove-Item $imagePath.FullName -Force
                }

                $newWim = @{
                    ImagePath = $imagePath.FullName
                    CapturePath = $capturePath.FullName
                    Name = 'PSRedstone'
                }
                Write-Information ('[Context NEW BeforeAll] New-RedstoneWim: {0}' -f ($newWim | ConvertTo-Json))
            }

            It 'Should be elevated to create WIMs' {
                $script:isElevated | Should -Be $true
            }

            It ('WIM does not already exist: {0}' -f $imagePath.FullName) {
                $imagePath.Exists | Should -Be $false
            }

            It ('New-RedstoneWim Should Run') {
                { New-RedstoneWim @newWim } | Should -Not -Throw
            }

            It ('WIM Created: {0}' -f $imagePath) {
                $imagePath.Refresh()
                $imagePath.Exists | Should -Be $true
            }
        }

        Context 'MOUNT' {
            BeforeAll {
                Write-Information ('[Context MOUNT BeforeAll] RedstoneWim Image Path: [{1}] {0}' -f $imagePath.FullName, $imagePath.GetType().FullName)
                if ($mountPath.Exists) {
                    Remove-Item $mountPath.FullName -Force
                }

                $mountWim = @{
                    ImagePath = $imagePath.FullName
                    MountPath = $mountPath.FullName
                }
                Write-Information ('[Context MOUNT BeforeAll] Mount-RedstoneWim: {0}' -f ($mountWim | ConvertTo-Json))
            }

            It 'Should be elevated to mount WIMs' {
                $script:isElevated | Should -Be $true
            }

            It ('Mount path does not exist: {0}' -f $mountPath.FullName) {
                $mountPath.Exists | Should -Be $false
            }

            It ('Mount-RedstoneWim Should Run') {
                { Mount-RedstoneWim @mountWim } | Should -Not -Throw
            }

            It ('Mount path exists: {0}' -f $mountPath.FullName) {
                $mountPath.Refresh()
                $mountPath.Exists | Should -Be $true
            }

            It ('Mount path not empty: {0}' -f $mountPath.FullName) {
                Get-ChildItem $mountPath.FullName | Should -Not -BeNullOrEmpty
            }

            It ('WIM mounted: {0}' -f $mountPath.FullName) {
                $mounted = Get-WindowsImage -Mounted | Where-Object { $_.Path -eq $mountPath.FullName }
                $mounted.MountStatus | Should -Be 'Ok'
            }
        }

        Context 'DISMOUNT' {
            BeforeAll {
                $dismountWim = @{
                    MountPath = $mountPath.FullName
                }
                Write-Information ('[Context DISMOUNT BeforeAll] Dismount-RedstoneWim: {0}' -f ($dismountWim | ConvertTo-Json))
            }

            It 'Should be elevated to dismount WIMs' {
                $script:isElevated | Should -Be $true
            }

            It ('Mount path exists: {0}' -f $mountPath.FullName) {
                $mountPath.Refresh()
                $mountPath.Exists | Should -Be $true
            }

            It ('Dismount-RedstoneWim Should Run') {
                { Dismount-RedstoneWim @dismountWim } | Should -Not -Throw
            }

            It ('Mount path still exists: {0}' -f $mountPath.FullName) {
                $mountPath.Refresh()
                $mountPath.Exists | Should -Be $true
            }

            It ('Mount path is empty: {0}' -f $mountPath.FullName) {
                Get-ChildItem $mountPath.FullName | Should -BeNullOrEmpty
            }

            It ('WIM dismounted: {0}' -f $mountPath.FullName) {
                $mounted = Get-WindowsImage -Mounted | Where-Object { $_.Path -eq $mountPath.FullName }
                $mounted.MountStatus | Should -BeNullOrEmpty
            }
        }
    } else {
        # NOT Elevated
        Write-Warning ('[Describe] PowerShell is NOT Elevated')
    }
}
