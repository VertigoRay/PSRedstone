Describe 'Install-WindowsUpdateAdv: <Name>' -ForEach @(
    @{
        Name = '0 Windows Updates'
        WindowsUpdates = Import-Clixml ([IO.Path]::Combine($PSScriptRoot, 'Install-WindowsUpdateAdv-WindowsUpdates0.xml'))
        LastDeploymentChangeTime = @()
    }
    @{
        Name = '1 Windows Update'
        WindowsUpdates = Import-Clixml ([IO.Path]::Combine($PSScriptRoot, 'Install-WindowsUpdateAdv-WindowsUpdates1.xml'))
        LastDeploymentChangeTime = @('2023-02-01T00:00:00')
    }
    @{
        Name = '2 Windows Updates'
        WindowsUpdates = Import-Clixml ([IO.Path]::Combine($PSScriptRoot, 'Install-WindowsUpdateAdv-WindowsUpdates2.xml'))
        LastDeploymentChangeTime = @('2023-02-11T00:00:00', '2023-01-23T00:00:00')
    }
) {
    BeforeAll {
        $script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
        . ('{0}\PSRedstone\Public\Install-WindowsUpdateAdv.ps1' -f $psProjectRoot.FullName)

        # Let's take calls to Dism.exe
        $dism = [IO.FileInfo] [IO.Path]::Combine($env:SystemRoot, 'System32', 'Dism.exe')
        New-Item -Path 'function:' -Name $dism.FullName -Value {
            Write-Verbose ('{0}: {1}' -f $dism.BaseName, $dism.Name)
        } -Force
        Mock $dism.FullName {
            return ('Mocked: {0}' -f $dism.BaseName)
        }
        New-Alias -Name $dism.Name -Value $dism.FullName

        # Let's take calls to sfc.exe
        $sfc = [IO.FileInfo] [IO.Path]::Combine($env:SystemRoot, 'System32', 'sfc.exe')
        New-Item -Path 'function:' -Name $sfc.FullName -Value {
            Write-Verbose ('{0}: {1}' -f $sfc.BaseName, $sfc.Name)
        } -Force
        Mock $sfc.FullName {
            return ('Mocked: {0}' -f $sfc.BaseName)
        }
        New-Alias -Name $sfc.Name -Value $sfc.FullName

        # Let's take calls to UsoClient.exe
        $usoClient = [IO.FileInfo] [IO.Path]::Combine($env:SystemRoot, 'System32', 'UsoClient.exe')
        New-Item -Path 'function:' -Name $usoClient.FullName -Value {
            Write-Verbose ('{0}: {1}' -f $usoClient.BaseName, $usoClient.Name)
        } -Force
        Mock $usoClient.FullName {
            return ('Mocked: {0}' -f $usoClient.BaseName)
        }
        New-Alias -Name $usoClient.Name -Value $usoClient.FullName

        # Let's take calls to wuauclt.exe
        $wuauclt = [IO.FileInfo] [IO.Path]::Combine($env:SystemRoot, 'System32', 'wuauclt.exe')
        New-Item -Path 'function:' -Name $wuauclt.FullName -Value {
            Write-Verbose ('{0}: {1}' -f $wuauclt.BaseName, $wuauclt.Name)
        } -Force
        Mock $wuauclt.FullName {
            return ('Mocked: {0}' -f $wuauclt.BaseName)
        }
        New-Alias -Name $wuauclt.Name -Value $wuauclt.FullName

        function Get-WindowsUpdate { Write-Verbose 'Get-WindowsUpdate' }
        function Install-WindowsUpdate { Write-Verbose 'Install-WindowsUpdate' }
        function Show-ToastNotification { Write-Verbose 'Show-ToastNotification' }
    }

    It ('Windows Update Count: {0}' -f $Name.Split(' ')[0]) -TestCases @(
        @{
            UpdateCount = $Name.Split(' ')[0] -as [int]
        }
    ) {
        ($WindowsUpdates | Measure-Object).Count | Should -Be $UpdateCount
    }

    It ('Get-WindowsUpdate Count: {0}' -f $Name.Split(' ')[0]) -TestCases @(
        @{
            UpdateCount = $Name.Split(' ')[0] -as [int]
        }
    ) {
        Mock 'Get-WindowsUpdate' { return $WindowsUpdates }
        (Get-WindowsUpdate | Measure-Object).Count | Should -Be $UpdateCount
    }

    It 'Confirm Mock: C:\Windows\System32\Dism.exe' {
        & 'C:\Windows\System32\Dism.exe' This Is A Test | Should -Be 'Mocked: Dism'
    }

    It 'Confirm Mock: Dism.exe' {
        & 'Dism.exe'  This Is A Test | Should -Be 'Mocked: Dism'
    }

    It 'Confirm Mock: C:\Windows\System32\sfc.exe' {
        & 'C:\Windows\System32\sfc.exe' This Is A Test | Should -Be 'Mocked: sfc'
    }

    It 'Confirm Mock: sfc.exe' {
        & 'sfc.exe' This Is A Test | Should -Be 'Mocked: sfc'
    }

    It 'Confirm Mock: C:\Windows\System32\wuauclt.exe' {
        & 'C:\Windows\System32\wuauclt.exe' This Is A Test | Should -Be 'Mocked: wuauclt'
    }

    It 'Confirm Mock: wuauclt.exe' {
        & 'wuauclt.exe'  This Is A Test | Should -Be 'Mocked: wuauclt'
    }

    It 'Confirm Mock: C:\Windows\System32\UsoClient.exe' {
        & 'C:\Windows\System32\UsoClient.exe' This Is A Test | Should -Be 'Mocked: UsoClient'
    }

    It 'Confirm Mock: UsoClient.exe' {
        & 'UsoClient.exe' This Is A Test | Should -Be 'Mocked: UsoClient'
    }

    Context 'Example 1' {
        BeforeEach {
            Mock 'Dism.exe' { return $MyInvocation.MyCommand }
            Mock 'sfc.exe' { return $MyInvocation.MyCommand }
            Mock 'UsoClient.exe' { return $MyInvocation.MyCommand }
            Mock 'wuauclt.exe' { return $MyInvocation.MyCommand }
            Mock 'Get-Command' { return $Name }
            Mock 'Get-Module' { return $Name }
            Mock 'Get-PackageProvider' { return $Name }
            Mock 'Get-Service' { return $Name }
            Mock 'Get-WindowsUpdate' { return $WindowsUpdates }
            Mock 'Install-Module' { return $Name }
            Mock 'Install-PackageProvider' { return $Name }
            Mock 'Install-WindowsUpdate' { return $MyInvocation }
            Mock 'Remove-Item' { return $Path }
            Mock 'Set-Service' { return $Name }
            Mock 'Show-ToastNotification' { return $Name }
            Mock 'Start-Service' { return $Name }
            Mock 'Stop-Service' { return $Name }

            $result = Install-WindowsUpdateAdv
        }

        It -Skip 'Install-WindowsUpdateAdv' {
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Dism.exe' {
            Should -Invoke -CommandName 'Dism.exe' -Times 0
        }

        It 'sfc.exe' {
            Should -Invoke -CommandName 'sfc.exe' -Times 0
        }

        It 'UsoClient.exe' {
            Should -Invoke -CommandName 'UsoClient.exe' -Times 0
        }

        It 'wuauclt.exe' {
            Should -Invoke -CommandName 'wuauclt.exe' -Times 0
        }

        It 'Get-Command UsoClient.exe' {
            Should -Invoke -CommandName 'Get-Command' -Times 0 -ParameterFilter { $Name -eq 'UsoClient.exe' }
        }

        It 'Get-Module PSWindowsUpdate' {
            Should -Invoke -CommandName 'Get-Module' -Times 1 -ParameterFilter { $Name -eq 'PSWindowsUpdate' }
        }

        It 'Get-PackageProvider NuGet' {
            Should -Invoke -CommandName 'Get-PackageProvider' -Times 1 -ParameterFilter { $Name -eq 'NuGet' }
        }

        It 'Get-Service wuauserv' {
            Should -Invoke -CommandName 'Get-Service' -Times 0 -ParameterFilter { $Name -eq 'wuauserv' }
        }

        It 'Get-WindowsUpdate' {
            Should -Invoke -CommandName 'Get-WindowsUpdate' -Times 1
        }

        It 'Install-Module PSWindowsUpdate' {
            Should -Invoke -CommandName 'Install-Module' -Times 1 -ParameterFilter { $Name -eq 'PSWindowsUpdate' }
        }

        It 'Install-PackageProvider NuGet' {
            Should -Invoke -CommandName 'Install-PackageProvider' -Times 1 -ParameterFilter { $Name -eq 'NuGet' }
        }

        It -Skip 'Install-WindowsUpdate' {
            Should -Invoke -CommandName 'Install-WindowsUpdate' -Times 1
        }

        It 'Remove-Item' {
            Should -Invoke -CommandName 'Remove-Item' -Times 0
        }

        It 'Set-Service wuauserv' {
            Should -Invoke -CommandName 'Set-Service' -Times 0 -ParameterFilter { $Name -eq 'wuauserv' }
        }

        It 'Show-ToastNotification' {
            Should -Invoke -CommandName 'Show-ToastNotification' -Times 0 -ParameterFilter { $ToastTitle -eq 'Windows Update' }
        }

        It 'Start-Service wuauserv' {
            Should -Invoke -CommandName 'Start-Service' -Times 0 -ParameterFilter { $Name -eq 'wuauserv' }
        }

        It 'Stop-Service wuauserv' {
            Should -Invoke -CommandName 'Stop-Service' -Times 0 -ParameterFilter { $Name -eq 'wuauserv' }
        }
    }

    Context 'Example 1: Thrown Install-WindowsUpdate' {
        BeforeEach {
            function Install-WindowsUpdate { throw [System.Management.Automation.CommandNotFoundException] 'Example 1: Thrown Install-WindowsUpdate' }

            Mock 'Dism.exe' { return $MyInvocation.MyCommand }
            Mock 'sfc.exe' { return $MyInvocation.MyCommand }
            Mock 'UsoClient.exe' { return $MyInvocation.MyCommand }
            Mock 'wuauclt.exe' { return $MyInvocation.MyCommand }
            Mock 'Get-Command' { return $Name }
            Mock 'Get-Module' { return $Name }
            Mock 'Get-PackageProvider' { return $Name }
            Mock 'Get-Service' { return $Name }
            Mock 'Get-WindowsUpdate' { return $WindowsUpdates }
            Mock 'Install-Module' { return $Name }
            Mock 'Install-PackageProvider' { return $Name }
            Mock 'Remove-Item' { return $Path }
            Mock 'Set-Service' { return $Name }
            Mock 'Show-ToastNotification' { return $Name }
            Mock 'Start-Service' { return $Name }
            Mock 'Stop-Service' { return $Name }

            $result = Install-WindowsUpdateAdv
        }

        It -Skip 'Install-WindowsUpdateAdv' {
            ($result | Measure-Object).Count | Should -Be ($Name.Split(' ')[0] -as [int])
        }

        It 'Dism.exe' {
            Should -Invoke -CommandName 'Dism.exe' -Times 0
        }

        It 'sfc.exe' {
            Should -Invoke -CommandName 'sfc.exe' -Times 0
        }

        It -Skip 'UsoClient.exe' {
            Should -Invoke -CommandName 'UsoClient.exe' -Times 0
        }

        It 'wuauclt.exe' {
            Should -Invoke -CommandName 'wuauclt.exe' -Times 0
        }

        It -Skip 'Get-Command UsoClient.exe' {
            Should -Invoke -CommandName 'Get-Command' -Times 0 -ParameterFilter { $Name -eq 'UsoClient.exe' }
        }

        It 'Get-Module PSWindowsUpdate' {
            Should -Invoke -CommandName 'Get-Module' -Times 1 -ParameterFilter { $Name -eq 'PSWindowsUpdate' }
        }

        It 'Get-PackageProvider NuGet' {
            Should -Invoke -CommandName 'Get-PackageProvider' -Times 1 -ParameterFilter { $Name -eq 'NuGet' }
        }

        It 'Get-Service wuauserv' {
            Should -Invoke -CommandName 'Get-Service' -Times 0 -ParameterFilter { $Name -eq 'wuauserv' }
        }

        It 'Get-WindowsUpdate' {
            Should -Invoke -CommandName 'Get-WindowsUpdate' -Times 1
        }

        It 'Install-Module PSWindowsUpdate' {
            Should -Invoke -CommandName 'Install-Module' -Times 1 -ParameterFilter { $Name -eq 'PSWindowsUpdate' }
        }

        It 'Install-PackageProvider NuGet' {
            Should -Invoke -CommandName 'Install-PackageProvider' -Times 1 -ParameterFilter { $Name -eq 'NuGet' }
        }

        It -Skip 'Install-WindowsUpdate' {
            Should -Invoke -CommandName 'Install-WindowsUpdate' -Times 1
        }

        It 'Remove-Item' {
            Should -Invoke -CommandName 'Remove-Item' -Times 0
        }

        It 'Set-Service wuauserv' {
            Should -Invoke -CommandName 'Set-Service' -Times 0 -ParameterFilter { $Name -eq 'wuauserv' }
        }

        It 'Show-ToastNotification' {
            Should -Invoke -CommandName 'Show-ToastNotification' -Times 0 -ParameterFilter { $ToastTitle -eq 'Windows Update' }
        }

        It 'Start-Service wuauserv' {
            Should -Invoke -CommandName 'Start-Service' -Times 0 -ParameterFilter { $Name -eq 'wuauserv' }
        }

        It 'Stop-Service wuauserv' {
            Should -Invoke -CommandName 'Stop-Service' -Times 0 -ParameterFilter { $Name -eq 'wuauserv' }
        }
    }

    Context 'Example 2' {
        BeforeEach {
            Mock 'Dism.exe' { return $MyInvocation.MyCommand }
            Mock 'sfc.exe' { return $MyInvocation.MyCommand }
            Mock 'UsoClient.exe' { return $MyInvocation.MyCommand }
            Mock 'wuauclt.exe' { return $MyInvocation.MyCommand }
            Mock 'Get-Command' { return $Name }
            Mock 'Get-Module' { return $Name }
            Mock 'Get-PackageProvider' { return $Name }
            Mock 'Get-Service' { return $Name }
            Mock 'Get-WindowsUpdate' { return $WindowsUpdates }
            Mock 'Install-Module' { return $Name }
            Mock 'Install-PackageProvider' { return $Name }
            Mock 'Install-WindowsUpdate' { return $MyInvocation }
            Mock 'Remove-Item' { return $Path }
            Mock 'Set-Service' { return $Name }
            Mock 'Show-ToastNotification' { return $Name }
            Mock 'Start-Service' { return $Name }
            Mock 'Stop-Service' { return $Name }

            $result = Install-WindowsUpdateAdv -FixWUAU
        }

        It -Skip 'Install-WindowsUpdateAdv -FixWUAU' {
            $result | Should -BeNullOrEmpty
        }

        It -Skip 'Dism.exe' {
            Should -Invoke -CommandName 'Dism.exe' -Times 1
        }

        It -Skip 'sfc.exe' {
            Should -Invoke -CommandName 'sfc.exe' -Times 1
        }

        It -Skip 'UsoClient.exe' {
            Should -Invoke -CommandName 'UsoClient.exe' -Times 1
        }

        It 'wuauclt.exe' {
            Should -Invoke -CommandName 'wuauclt.exe' -Times 0
        }

        It 'Get-Command UsoClient.exe' {
            Should -Invoke -CommandName 'Get-Command' -Times 0 -ParameterFilter { $Name -eq 'UsoClient.exe' }
        }

        It 'Get-Module PSWindowsUpdate' {
            Should -Invoke -CommandName 'Get-Module' -Times 1 -ParameterFilter { $Name -eq 'PSWindowsUpdate' }
        }

        It 'Get-PackageProvider NuGet' {
            Should -Invoke -CommandName 'Get-PackageProvider' -Times 1 -ParameterFilter { $Name -eq 'NuGet' }
        }

        It -Skip 'Get-Service wuauserv' {
            Should -Invoke -CommandName 'Get-Service' -Times 1 -ParameterFilter { $Name -eq 'wuauserv' }
        }

        It 'Get-WindowsUpdate' {
            Should -Invoke -CommandName 'Get-WindowsUpdate' -Times 1
        }

        It 'Install-Module PSWindowsUpdate' {
            Should -Invoke -CommandName 'Install-Module' -Times 1 -ParameterFilter { $Name -eq 'PSWindowsUpdate' }
        }

        It 'Install-PackageProvider NuGet' {
            Should -Invoke -CommandName 'Install-PackageProvider' -Times 1 -ParameterFilter { $Name -eq 'NuGet' }
        }

        It -Skip 'Install-WindowsUpdate' {
            Should -Invoke -CommandName 'Install-WindowsUpdate' -Times 1
        }

        It -Skip 'Remove-Item' {
            Should -Invoke -CommandName 'Remove-Item' -Times 0
        }

        It -Skip 'Set-Service wuauserv' {
            Should -Invoke -CommandName 'Set-Service' -Times 1 -ParameterFilter { $Name -eq 'wuauserv' }
        }

        It 'Show-ToastNotification' {
            Should -Invoke -CommandName 'Show-ToastNotification' -Times 0 -ParameterFilter { $ToastTitle -eq 'Windows Update' }
        }

        It -Skip 'Start-Service wuauserv' {
            Should -Invoke -CommandName 'Start-Service' -Times 1 -ParameterFilter { $Name -eq 'wuauserv' }
        }

        It -Skip 'Stop-Service wuauserv' {
            Should -Invoke -CommandName 'Stop-Service' -Times 1 -ParameterFilter { $Name -eq 'wuauserv' }
        }
    }

    Context 'Example 3' {
        It -Skip 'Install-WindowsUpdateAdv -LastDeploymentChangeThresholdDays 30 -FixWUAU' {
            Install-WindowsUpdateAdv -LastDeploymentChangeThresholdDays 30 -FixWUAU | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Example 4' {
        BeforeAll {
            $scheduleJob = (Get-Date -Format 'MM-dd-yyyy' | Get-Date).AddDays(1).AddHours(-7) | Get-Date -Format 'O' # 5pm today
        }

        It -Skip ('Install-WindowsUpdateAdv -LastDeploymentChangeThresholdDays 30 -FixWUAU -ScheduleJob {0}' -f $scheduleJob) {
            Install-WindowsUpdateAdv -LastDeploymentChangeThresholdDays 30 -FixWUAU -ScheduleJob $scheduleJob | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Example 5' {
        BeforeAll {
            $scheduleJob = (Get-Date -Format 'MM-dd-yyyy' | Get-Date).AddDays(1).AddHours(-7) | Get-Date -Format 'O' # 5pm today
            $scheduleReboot = (Get-Date -Format 'MM-dd-yyyy' | Get-Date).AddDays(1).AddHours(-1) | Get-Date -Format 'O' # 11pm today
        }

        It -Skip ('Install-WindowsUpdateAdv -LastDeploymentChangeThresholdDays 30 -FixWUAU -ScheduleJob {0} -ScheduleReboot {1}' -f $scheduleJob, $scheduleReboot) {
            Install-WindowsUpdateAdv -LastDeploymentChangeThresholdDays 30 -FixWUAU -ScheduleJob $scheduleJob -ScheduleReboot $scheduleReboot | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Example 6' {
        BeforeAll {
            $scheduleJob = (Get-Date -Format 'MM-dd-yyyy' | Get-Date).AddDays(1).AddHours(-7) | Get-Date -Format 'O' # 5pm today
            $scheduleReboot = (Get-Date -Format 'MM-dd-yyyy' | Get-Date).AddDays(1).AddHours(-1) | Get-Date -Format 'O' # 11pm today

            $toastNotification  = @{
                ToastNotifier = 'Tech Solutions: Endpoint Solutions Engineering'
                ToastTitle = 'Windows Update'
                ToastText = 'This computer is at least 30 days overdue for {0} Windows Update{1}. {2} being forced on your system {3}. A reboot may occur {4}.'
                ToastTextFormatters = @(
                    @($null, 's')
                    @('The update is', 'Updates are')
                    @(('on {0}' -f ($scheduleJob | Get-Date -Format (Get-Culture).DateTimeFormat.FullDateTimePattern)), 'now')
                    @(('on {0}' -f ($scheduleReboot | Get-Date -Format (Get-Culture).DateTimeFormat.FullDateTimePattern)), 'immediately afterwards')
                )
            }
        }

        It -Skip ('Install-WindowsUpdateAdv -LastDeploymentChangeThresholdDays 30 -FixWUAU -ScheduleJob {0} -ScheduleReboot {1} -ToastNotification $toastNotification' -f $scheduleJob, $scheduleReboot) {
            Install-WindowsUpdateAdv -LastDeploymentChangeThresholdDays 30 -FixWUAU -ScheduleJob $scheduleJob -ScheduleReboot $scheduleReboot -ToastNotification $toastNotification | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Example 7: UsoClient' {
        It -Skip 'Install-WindowsUpdateAdv -FixWUAU -NoPSWindowsUpdate' {
            Install-WindowsUpdateAdv -FixWUAU -NoPSWindowsUpdate | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Example 7: wuauclt' {
        BeforeAll {
            Mock 'Get-Command' { return $null }
        }

        It -Skip 'Install-WindowsUpdateAdv -FixWUAU -NoPSWindowsUpdate' {
            Install-WindowsUpdateAdv -FixWUAU -NoPSWindowsUpdate | Should -Not -BeNullOrEmpty
        }
    }
}
