$script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
. ('{0}\PSRedstone\Public\Invoke-RedstoneMsi.ps1' -f $psProjectRoot.FullName)
. ('{0}\PSRedstone\Public\Invoke-RedstoneRun.ps1' -f $psProjectRoot.FullName)
. ('{0}\PSRedstone\Public\Get-RedstoneInstalledApplication.ps1' -f $psProjectRoot.FullName)
. ('{0}\PSRedstone\Public\Assert-RedstoneIsMutexAvailable.ps1' -f $psProjectRoot.FullName)
. ('{0}\PSRedstone\Public\Get-RedstoneMsiExitCodeMessage.ps1' -f $psProjectRoot.FullName)

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

    # [Invoke-RedstoneRun] Start-Process: {
    #     "FilePath":  "C:\\WINDOWS\\system32\\msiexec.exe",
    #     "ArgumentList":  [
    #                          "/qn",
    #                          "/i",
    #                          "\"C:\\WINDOWS\\Installer\\10150aa8.msi\"",
    #                          "REBOOT=ReallySuppress",
    #                          "/log",
    #                          "\"C:\\Users\\qhm067\\AppData\\Local\\Temp\\Logs\\Redstone\\MyPublisher MyProduct 1.2.3 test.msi.Install.log\""
    #                      ],
    #     "WorkingDirectory":  "C:\\WINDOWS\\Installer",
    #     "WindowStyle":  "Hidden",
    #     "PassThru":  true
    #     "Wait":  true,
    #     "RedirectStandardError":  "C:\\Users\\qhm067\\AppData\\Local\\Temp\\tmp206C.tmp",
    #     "RedirectStandardOutput":  "C:\\Users\\qhm067\\AppData\\Local\\Temp\\tmp206B.tmp",
    # }
    Context 'Simple Msiexec' {
        BeforeEach {
            Mock Invoke-RedstoneRun {
                param ($Cmd, $FilePath, $ArgumentList, $WorkingDirectory, $PassThru, $Wait, $WindowStyle, $LogFile)
                return @{
                    Process = @{
                        ExitCode = 0
                    }
                    Parameters = @{
                        Bound = $MyInvocation.BoundParameters
                        Unbound = $MyInvocation.UnboundParameters
                    }
                }
            }
            Mock Get-RedstoneInstalledApplication { param($ProductCode) return $null } # Msi Not Installed
            Mock Assert-RedstoneIsMutexAvailable { param($ProductCode) return $true }
            Mock Get-RedstoneMsiExitCodeMessage { param($ExitCode, $MsiLog) return 0 }
        }

        It 'Send msiexec Type' {
            $result = Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName
            $result.Parameters.Bound.FilePath | Should -BeOfType 'System.String'
        }

        It 'Send msiexec' {
            $result = Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName
            $result.Parameters.Bound.FilePath | Should -Be ('{0}\System32\msiexec.exe' -f $env:SystemRoot)
        }

        It 'ArgumentList Type' {
            $result = Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName
            ,$result.Parameters.Bound.ArgumentList | Should -BeOfType 'System.String[]'
        }

        It 'ArgumentList Count' {
            $result = Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName
            $result.Parameters.Bound.ArgumentList.Count | Should -Be 6
        }

        It 'Send /qn' {
            $result = Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName
            $result.Parameters.Bound.ArgumentList[0] | Should -Be '/qn'
        }

        It 'Send /i' {
            $result = Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName
            $result.Parameters.Bound.ArgumentList[1] | Should -Be '/i'
        }

        It 'Send filename.msi' {
            $result = Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName
            $result.Parameters.Bound.ArgumentList[2] | Should -Be ('"{0}"' -f $script:randomMsi.FullName)
        }

        It 'Send REBOOT=ReallySuppress' {
            $result = Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName
            $result.Parameters.Bound.ArgumentList[3] | Should -Be 'REBOOT=ReallySuppress'
        }

        It 'Send /log' {
            $result = Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName
            $result.Parameters.Bound.ArgumentList[4] | Should -Be '/log'
        }

        It 'Send Log File' {
            $result = Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName
            $result.Parameters.Bound.ArgumentList[5] | Should -BeLike '"*.msi.Install.log"'
        }

        It 'Send WorkingDirectory Type' {
            $result = Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName
            $result.Parameters.Bound.FilePath | Should -BeOfType 'System.String'
        }

        It 'Send WorkingDirectory' {
            $result = Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName
            $result.Parameters.Bound.WorkingDirectory | Should -Be (Get-Location).Path
        }

        It 'Send WindowStyle Type' {
            $result = Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName
            $result.Parameters.Bound.FilePath | Should -BeOfType 'System.String'
        }

        It 'Send WindowStyle' {
            $result = Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName
            $result.Parameters.Bound.WindowStyle | Should -Be 'Hidden'
        }

        It 'Send PassThru Type' {
            $result = Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName
            $result.Parameters.Bound.PassThru | Should -BeOfType 'System.Boolean'
        }

        It 'Send PassThru' {
            $result = Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName
            $result.Parameters.Bound.PassThru | Should -Be $true
        }

        It 'Send Wait Type' {
            $result = Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName
            $result.Parameters.Bound.Wait | Should -BeOfType 'System.Boolean'
        }

        It 'Send Wait' {
            $result = Invoke-RedstoneMsi -FilePath $script:randomMsi.FullName
            $result.Parameters.Bound.Wait | Should -Be $true
        }
    }
}
