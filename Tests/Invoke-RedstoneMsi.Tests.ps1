$script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
. ('{0}\PSRedstone\Public\Invoke-RedstoneMsi.ps1' -f $psProjectRoot.FullName)
. ('{0}\PSRedstone\Public\Invoke-RedstoneMsi.ps1' -f $psProjectRoot.FullName)
. ('{0}\PSRedstone\Public\Invoke-RedstoneMsi.ps1' -f $psProjectRoot.FullName)
. ('{0}\PSRedstone\Public\Invoke-RedstoneMsi.ps1' -f $psProjectRoot.FullName)

Describe 'Invoke-RedstoneMsi' {
    BeforeAll {
        $script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
        . ('{0}\PSRedstone\Public\Invoke-RedstoneMsi.ps1' -f $psProjectRoot.FullName)
        . ('{0}\PSRedstone\Public\Invoke-RedstoneRun.ps1' -f $psProjectRoot.FullName)
        . ('{0}\PSRedstone\Public\Get-RedstoneInstalledApplication.ps1' -f $psProjectRoot.FullName)
        . ('{0}\PSRedstone\Public\Assert-RedstoneIsMutexAvailable.ps1' -f $psProjectRoot.FullName)
        . ('{0}\PSRedstone\Public\Get-RedstoneMsiExitCodeMessage.ps1' -f $psProjectRoot.FullName)

        [IO.FileInfo] $script:randomMsi = Get-ChildItem "$env:SystemRoot\Installer" -Filter '*.msi' -File -Recurse | Select-Object -First 1
        if (-not $script:randomMsi.Exists) {
            Start-BitsTransfer -Source 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi' -Destination "$TestDrive\googlechromestandaloneenterprise64.msi"
            [IO.FileInfo] $script:randomMsi = "$TestDrive\googlechromestandaloneenterprise64.msi"
        }
    }

    Context 'Simple Msiexec' {
        BeforeEach {
            Mock Invoke-RedstoneRun { param($FilePath, $ArgumentList) return @{Process = @{ExitCode = 0}; Foo = @($FilePath, $ArgumentList)} }
            Mock Get-RedstoneInstalledApplication { param($ProductCode) return $null } # Msi Not Installed
            Mock Assert-RedstoneIsMutexAvailable { param($ProductCode) return $true }
            Mock Get-RedstoneMsiExitCodeMessage { param($ExitCode, $MsiLog) return 0 }
        }

        It 'Should send msiexec' {
            $FilePath, $ArgumentList = (Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName).Foo
            $FilePath | Should -Be ('{0}\System32\msiexec.exe' -f $env:SystemRoot)
        }

        It 'Should send /qn' {
            $FilePath, $ArgumentList = (Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName).Foo
            $ArgumentList[0] | Should -Be '/qn'
        }

        It 'Should send /i' {
            $FilePath, $ArgumentList = (Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName).Foo
            $ArgumentList[1] | Should -Be '/i'
        }

        It 'Should send filename.msi' {
            $FilePath, $ArgumentList = (Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName).Foo
            $ArgumentList[2] | Should -Be ('"{0}"' -f $script:randomMsi.FullName)
        }

        It 'Should send REBOOT=ReallySuppress' {
            $FilePath, $ArgumentList = (Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName).Foo
            $ArgumentList[3] | Should -Be 'REBOOT=ReallySuppress'
        }

        It 'Should send /log' {
            $FilePath, $ArgumentList = (Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName).Foo
            $ArgumentList[4] | Should -Be '/log'
        }

        It 'Should send /i' {
            $FilePath, $ArgumentList = (Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName).Foo
            $ArgumentList[5] | Should -BeLike '"*\Logs\Redstone\*.msi.Install.log"'
        }
    }
}
