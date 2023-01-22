Describe 'Get-RedstoneInstalledApplication' {
    $script:First64 = (Get-ItemProperty ('Registry::{0}' -f (Get-ChildItem 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' | Where-Object { $_.PSChildName -as [guid] } | Select-Object -First 1).Name))
    $script:First32 = (Get-ItemProperty ('Registry::{0}' -f (Get-ChildItem 'HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall' | Where-Object { $_.PSChildName -as [guid] } | Select-Object -First 1).Name))

    BeforeAll {
        $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
        . ('{0}\PSRedstone\Public\Get-RedstoneInstalledApplication.ps1' -f $psProjectRoot.FullName)

        $script:First64 = (Get-ItemProperty ('Registry::{0}' -f (Get-ChildItem 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' | Where-Object { $_.PSChildName -as [guid] } | Select-Object -First 1).Name))
        $script:First32 = (Get-ItemProperty ('Registry::{0}' -f (Get-ChildItem 'HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall' | Where-Object { $_.PSChildName -as [guid] } | Select-Object -First 1).Name))
    }

    Context ('All') {
        It 'Not Throw' {
            { Get-RedstoneInstalledApplication } | Should -Not -Throw
        }

        It 'Return Type' {
            Get-RedstoneInstalledApplication | Should -BeOfType 'PSObject'
        }

        It 'Return Count' {
            (Get-RedstoneInstalledApplication | Measure-Object).Count | Should -BeGreaterThan 1
        }

        It 'UninstallSubkey' {
            (Get-RedstoneInstalledApplication).UninstallSubkey | Should -BeOfType 'System.String'
        }

        It 'DisplayName' {
            (Get-RedstoneInstalledApplication).DisplayName | Should -BeOfType 'System.String'
        }

        It 'DisplayVersion' {
            (Get-RedstoneInstalledApplication).DisplayVersion | Should -BeOfType 'System.String'
        }

        It 'Publisher' {
            (Get-RedstoneInstalledApplication).Publisher | Should -BeOfType 'System.String'
        }

        It 'Is64BitApplication' {
            (Get-RedstoneInstalledApplication).Is64BitApplication | Should -BeOfType 'System.Boolean'
        }

        It 'PSPath' {
            (Get-RedstoneInstalledApplication).PSPath | Should -BeOfType 'System.String'
        }
    }

    Context ('None') {
        BeforeAll {
            $script:Name = (New-Guid).Guid.Split('-')[0]
        }

        It 'Not Throw' {
            { Get-RedstoneInstalledApplication } | Should -Not -Throw
        }

        It 'Return Type' {
            Get-RedstoneInstalledApplication $script:Name | Should -BeNullOrEmpty
        }

        It 'Return Count' {
            (Get-RedstoneInstalledApplication $script:Name | Measure-Object).Count | Should -Be 0
        }

        It 'UninstallSubkey' {
            (Get-RedstoneInstalledApplication $script:Name).UninstallSubkey | Should -BeNullOrEmpty
        }

        It 'DisplayName' {
            (Get-RedstoneInstalledApplication $script:Name).DisplayName | Should -BeNullOrEmpty
        }

        It 'DisplayVersion' {
            (Get-RedstoneInstalledApplication $script:Name).DisplayVersion | Should -BeNullOrEmpty
        }

        It 'Publisher' {
            (Get-RedstoneInstalledApplication $script:Name).Publisher | Should -BeNullOrEmpty
        }

        It 'Is64BitApplication' {
            (Get-RedstoneInstalledApplication $script:Name).Is64BitApplication | Should -BeNullOrEmpty
        }

        It 'PSPath' {
            (Get-RedstoneInstalledApplication $script:Name).PSPath | Should -BeNullOrEmpty
        }
    }

    Context ('First64') {
        $testCases = @(
            @{
                Title = 'CaseSensitive'
                Splat = @{
                    Name = $script:First64.DisplayName
                    CaseSensitive = $true
                }
            }
            @{
                Title = 'Exact'
                Splat = @{
                    Name = $script:First64.DisplayName.ToLower()
                    Exact = $true
                }
            }
            @{
                Title = 'Exact CaseSensitive'
                Splat = @{
                    Name = $script:First64.DisplayName
                    Exact = $true
                    CaseSensitive = $true
                }
            }
            @{
                Title = 'RegEx'
                Splat = @{
                    Name = [Regex]::Escape($script:First64.DisplayName.ToLower())
                    RegEx = $true
                }
            }
            @{
                Title = 'RegEx CaseSensitive'
                Splat = @{
                    Name = [Regex]::Escape($script:First64.DisplayName)
                    RegEx = $true
                    CaseSensitive = $true
                }
            }
            @{
                Title = 'ProductCode'
                Splat = @{
                    ProductCode = $script:First64.PSChildName
                }
            }
            @{
                Title = 'WildCard'
                Splat = @{
                    Name = $script:First64.DisplayName.ToLower()
                    WildCard = $true
                }
            }
            @{
                Title = 'WildCard CaseSensitive'
                Splat = @{
                    Name = $script:First64.DisplayName
                    WildCard = $true
                    CaseSensitive = $true
                }
            }
            @{
                Title = 'IncludeUpdatesAndHotfixes'
                Splat = @{
                    Name = $script:First64.DisplayName
                    IncludeUpdatesAndHotfixes = $true
                }
            }
        )

        It 'Not Throw: <Title>' -TestCases $testCases {
            { Get-RedstoneInstalledApplication @Splat } | Should -Not -Throw
        }

        It 'Return Type: <Title>' -TestCases $testCases {
            Get-RedstoneInstalledApplication @Splat | Should -BeOfType 'PSObject'
        }

        It 'Return Count: <Title>' -TestCases $testCases {
            (Get-RedstoneInstalledApplication @Splat | Measure-Object).Count | Should -BeGreaterOrEqual 1
        }

        It 'UninstallSubkey Type: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).UninstallSubkey | Select-Object -First 1) -as [guid] | Should -BeOfType 'guid'
        }

        It 'UninstallSubkey: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).UninstallSubkey | Select-Object -First 1) | Should -Be $script:First64.PSChildName
        }

        It 'DisplayName Type: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).DisplayName | Select-Object -First 1) | Should -BeOfType 'System.String'
        }

        It 'DisplayName: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).DisplayName | Select-Object -First 1) | Should -Be $script:First64.DisplayName
        }

        It 'DisplayVersion Type: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).DisplayVersion | Select-Object -First 1) | Should -BeOfType 'System.String'
        }

        It 'DisplayVersion: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).DisplayVersion | Select-Object -First 1) | Should -Be $script:First64.DisplayVersion
        }

        It 'Publisher Type: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).Publisher | Select-Object -First 1) | Should -BeOfType 'System.String'
        }

        It 'Publisher: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).Publisher | Select-Object -First 1) | Should -Be $script:First64.Publisher
        }

        It 'Is64BitApplication Type: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).Is64BitApplication | Select-Object -First 1) | Should -BeOfType 'System.Boolean'
        }

        It 'Is64BitApplication: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).Is64BitApplication | Select-Object -First 1) | Should -Be $true
        }

        It 'PSPath Type: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).PSPath | Select-Object -First 1) | Should -BeOfType 'System.String'
        }

        It 'PSPath: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).PSPath | Select-Object -First 1) | Should -Be $script:First64.PSPath
        }
    }

    Context ('First32') {
        $testCases = @(
            @{
                Title = 'CaseSensitive'
                Splat = @{
                    Name = $script:First32.DisplayName
                    CaseSensitive = $true
                }
            }
            @{
                Title = 'Exact'
                Splat = @{
                    Name = $script:First32.DisplayName.ToLower()
                    Exact = $true
                }
            }
            @{
                Title = 'Exact CaseSensitive'
                Splat = @{
                    Name = $script:First32.DisplayName
                    Exact = $true
                    CaseSensitive = $true
                }
            }
            @{
                Title = 'RegEx'
                Splat = @{
                    Name = [Regex]::Escape($script:First32.DisplayName.ToLower())
                    RegEx = $true
                }
            }
            @{
                Title = 'RegEx CaseSensitive'
                Splat = @{
                    Name = [Regex]::Escape($script:First32.DisplayName)
                    RegEx = $true
                    CaseSensitive = $true
                }
            }
            @{
                Title = 'ProductCode'
                Splat = @{
                    ProductCode = $script:First32.PSChildName
                }
            }
            @{
                Title = 'WildCard'
                Splat = @{
                    Name = $script:First32.DisplayName.ToLower()
                    WildCard = $true
                }
            }
            @{
                Title = 'WildCard CaseSensitive'
                Splat = @{
                    Name = $script:First32.DisplayName
                    WildCard = $true
                    CaseSensitive = $true
                }
            }
            @{
                Title = 'IncludeUpdatesAndHotfixes'
                Splat = @{
                    Name = $script:First32.DisplayName
                    IncludeUpdatesAndHotfixes = $true
                }
            }
        )

        It 'Not Throw: <Title>' -TestCases $testCases {
            { Get-RedstoneInstalledApplication @Splat } | Should -Not -Throw
        }

        It 'Return Type: <Title>' -TestCases $testCases {
            Get-RedstoneInstalledApplication @Splat | Should -BeOfType 'PSObject'
        }

        It 'Return Count: <Title>' -TestCases $testCases {
            (Get-RedstoneInstalledApplication @Splat | Measure-Object).Count | Should -BeGreaterOrEqual 1
        }

        It 'UninstallSubkey Type: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).UninstallSubkey | Select-Object -First 1) -as [guid] | Should -BeOfType 'guid'
        }

        It 'UninstallSubkey: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).UninstallSubkey | Select-Object -First 1) | Should -Be $script:First32.PSChildName
        }

        It 'DisplayName Type: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).DisplayName | Select-Object -First 1) | Should -BeOfType 'System.String'
        }

        It 'DisplayName: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).DisplayName | Select-Object -First 1) | Should -Be $script:First32.DisplayName
        }

        It 'DisplayVersion Type: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).DisplayVersion | Select-Object -First 1) | Should -BeOfType 'System.String'
        }

        It 'DisplayVersion: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).DisplayVersion | Select-Object -First 1) | Should -Be $script:First32.DisplayVersion
        }

        It 'Publisher Type: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).Publisher | Select-Object -First 1) | Should -BeOfType 'System.String'
        }

        It 'Publisher: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).Publisher | Select-Object -First 1) | Should -Be $script:First32.Publisher
        }

        It 'Is64BitApplication Type: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).Is64BitApplication | Select-Object -First 1) | Should -BeOfType 'System.Boolean'
        }

        It 'Is64BitApplication: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).Is64BitApplication | Select-Object -First 1) | Should -Be $false
        }

        It 'PSPath Type: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).PSPath | Select-Object -First 1) | Should -BeOfType 'System.String'
        }

        It 'PSPath: <Title>' -TestCases $testCases {
            ((Get-RedstoneInstalledApplication @Splat).PSPath | Select-Object -First 1) | Should -Be $script:First32.PSPath
        }
    }
}
