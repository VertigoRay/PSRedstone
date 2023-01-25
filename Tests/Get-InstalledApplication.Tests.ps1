Describe 'Get-InstalledApplication' {
    $script:First64 = (Get-ItemProperty ('Registry::{0}' -f (Get-ChildItem 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' | Where-Object { $_.PSChildName -as [guid] } | Select-Object -First 1).Name))
    $script:First32 = (Get-ItemProperty ('Registry::{0}' -f (Get-ChildItem 'HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall' | Where-Object { $_.PSChildName -as [guid] } | Select-Object -First 1).Name))

    BeforeAll {
        $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
        . ('{0}\PSRedstone\Public\Get-InstalledApplication.ps1' -f $psProjectRoot.FullName)

        $script:First64 = (Get-ItemProperty ('Registry::{0}' -f (Get-ChildItem 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' | Where-Object { $_.PSChildName -as [guid] } | Select-Object -First 1).Name))
        $script:First32 = (Get-ItemProperty ('Registry::{0}' -f (Get-ChildItem 'HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall' | Where-Object { $_.PSChildName -as [guid] } | Select-Object -First 1).Name))
    }

    Context ('All') {
        It 'Not Throw' {
            { Get-InstalledApplication } | Should -Not -Throw
        }

        It 'Return Type' {
            Get-InstalledApplication | Should -BeOfType 'PSObject'
        }

        It 'Return Count' {
            (Get-InstalledApplication | Measure-Object).Count | Should -BeGreaterThan 1
        }

        It 'UninstallSubkey' {
            (Get-InstalledApplication).UninstallSubkey | Should -BeOfType 'System.String'
        }

        It 'DisplayName' {
            (Get-InstalledApplication).DisplayName | Should -BeOfType 'System.String'
        }

        It 'DisplayVersion' {
            (Get-InstalledApplication).DisplayVersion | Should -BeOfType 'System.String'
        }

        It 'Publisher' {
            (Get-InstalledApplication).Publisher | Should -BeOfType 'System.String'
        }

        It 'Is64BitApplication' {
            (Get-InstalledApplication).Is64BitApplication | Should -BeOfType 'System.Boolean'
        }

        It 'PSPath' {
            (Get-InstalledApplication).PSPath | Should -BeOfType 'System.String'
        }
    }

    Context ('None') {
        BeforeAll {
            $script:Name = (New-Guid).Guid.Split('-')[0]
        }

        It 'Not Throw' {
            { Get-InstalledApplication } | Should -Not -Throw
        }

        It 'Return Type' {
            Get-InstalledApplication $script:Name | Should -BeNullOrEmpty
        }

        It 'Return Count' {
            (Get-InstalledApplication $script:Name | Measure-Object).Count | Should -Be 0
        }

        It 'UninstallSubkey' {
            (Get-InstalledApplication $script:Name).UninstallSubkey | Should -BeNullOrEmpty
        }

        It 'DisplayName' {
            (Get-InstalledApplication $script:Name).DisplayName | Should -BeNullOrEmpty
        }

        It 'DisplayVersion' {
            (Get-InstalledApplication $script:Name).DisplayVersion | Should -BeNullOrEmpty
        }

        It 'Publisher' {
            (Get-InstalledApplication $script:Name).Publisher | Should -BeNullOrEmpty
        }

        It 'Is64BitApplication' {
            (Get-InstalledApplication $script:Name).Is64BitApplication | Should -BeNullOrEmpty
        }

        It 'PSPath' {
            (Get-InstalledApplication $script:Name).PSPath | Should -BeNullOrEmpty
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
            { Get-InstalledApplication @Splat } | Should -Not -Throw
        }

        It 'Return Type: <Title>' -TestCases $testCases {
            Get-InstalledApplication @Splat | Should -BeOfType 'PSObject'
        }

        It 'Return Count: <Title>' -TestCases $testCases {
            (Get-InstalledApplication @Splat | Measure-Object).Count | Should -BeGreaterOrEqual 1
        }

        It 'UninstallSubkey Type: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).UninstallSubkey | Select-Object -First 1) -as [guid] | Should -BeOfType 'guid'
        }

        It 'UninstallSubkey: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).UninstallSubkey | Select-Object -First 1) | Should -Be $script:First64.PSChildName
        }

        It 'DisplayName Type: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).DisplayName | Select-Object -First 1) | Should -BeOfType 'System.String'
        }

        It 'DisplayName: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).DisplayName | Select-Object -First 1) | Should -Be $script:First64.DisplayName
        }

        It 'DisplayVersion Type: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).DisplayVersion | Select-Object -First 1) | Should -BeOfType 'System.String'
        }

        It 'DisplayVersion: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).DisplayVersion | Select-Object -First 1) | Should -Be $script:First64.DisplayVersion
        }

        It 'Publisher Type: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).Publisher | Select-Object -First 1) | Should -BeOfType 'System.String'
        }

        It 'Publisher: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).Publisher | Select-Object -First 1) | Should -Be $script:First64.Publisher
        }

        It 'Is64BitApplication Type: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).Is64BitApplication | Select-Object -First 1) | Should -BeOfType 'System.Boolean'
        }

        It 'Is64BitApplication: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).Is64BitApplication | Select-Object -First 1) | Should -Be $true
        }

        It 'PSPath Type: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).PSPath | Select-Object -First 1) | Should -BeOfType 'System.String'
        }

        It 'PSPath: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).PSPath | Select-Object -First 1) | Should -Be $script:First64.PSPath
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
            { Get-InstalledApplication @Splat } | Should -Not -Throw
        }

        It 'Return Type: <Title>' -TestCases $testCases {
            Get-InstalledApplication @Splat | Should -BeOfType 'PSObject'
        }

        It 'Return Count: <Title>' -TestCases $testCases {
            (Get-InstalledApplication @Splat | Measure-Object).Count | Should -BeGreaterOrEqual 1
        }

        It 'UninstallSubkey Type: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).UninstallSubkey | Select-Object -First 1) -as [guid] | Should -BeOfType 'guid'
        }

        It 'UninstallSubkey: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).UninstallSubkey | Select-Object -First 1) | Should -Be $script:First32.PSChildName
        }

        It 'DisplayName Type: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).DisplayName | Select-Object -First 1) | Should -BeOfType 'System.String'
        }

        It 'DisplayName: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).DisplayName | Select-Object -First 1) | Should -Be $script:First32.DisplayName
        }

        It 'DisplayVersion Type: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).DisplayVersion | Select-Object -First 1) | Should -BeOfType 'System.String'
        }

        It 'DisplayVersion: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).DisplayVersion | Select-Object -First 1) | Should -Be $script:First32.DisplayVersion
        }

        It 'Publisher Type: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).Publisher | Select-Object -First 1) | Should -BeOfType 'System.String'
        }

        It 'Publisher: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).Publisher | Select-Object -First 1) | Should -Be $script:First32.Publisher
        }

        It 'Is64BitApplication Type: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).Is64BitApplication | Select-Object -First 1) | Should -BeOfType 'System.Boolean'
        }

        It 'Is64BitApplication: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).Is64BitApplication | Select-Object -First 1) | Should -Be $false
        }

        It 'PSPath Type: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).PSPath | Select-Object -First 1) | Should -BeOfType 'System.String'
        }

        It 'PSPath: <Title>' -TestCases $testCases {
            ((Get-InstalledApplication @Splat).PSPath | Select-Object -First 1) | Should -Be $script:First32.PSPath
        }
    }
}
