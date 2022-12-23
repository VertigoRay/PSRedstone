Describe 'Initialize' -Tag 'Class' {
    $script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
    . ('{0}\PSRedstone\Private\Initialize.ps1' -f $psProjectRoot.FullName)

    function Invoke-RedstoneTestLogFileA898F15E {
        param(
            [string] $LogFile
        )

        return $LogFile
    }

    function Invoke-RedstoneTestLogFileF7558260D {
        param(
            [string] $LogFileF
        )

        return $LogFileF
    }

    $contexts = [ordered] @{
        'Default' = @{
            Publisher = 'MyPublisher'
            Product = 'MyProduct'
            Version = '1.2.3'
            Action = 'test'
            Run = {}
        }
        'Publisher Change' = @{
            Publisher = 'YourPublisher'
            Product = 'MyProduct'
            Version = '1.2.3'
            Action = 'test'
            Run = {
                $script:Redstone.Publisher = 'YourPublisher'
            }
        }
        'Product Change' = @{
            Publisher = 'MyPublisher'
            Product = 'YourProduct'
            Version = '1.2.3'
            Action = 'test'
            Run = {
                $script:Redstone.Product = 'YourProduct'
            }
        }
        'Version Change' = @{
            Publisher = 'MyPublisher'
            Product = 'MyProduct'
            Version = '2.3.4'
            Action = 'test'
            Run = {
                $script:Redstone.Version = '2.3.4'
            }
        }
        'Action Change' = @{
            Publisher = 'MyPublisher'
            Product = 'MyProduct'
            Version = '1.2.3'
            Action = 'testing'
            Run = {
                $script:Redstone.Action = 'testing'
            }
        }
    }

    Context ('Redstone Class') {
        BeforeEach {
            $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
            . ('{0}\PSRedstone\Private\Initialize.ps1' -f $psProjectRoot.FullName)

            $script:publisher = 'MyPublisher'
            $script:product = 'MyProduct'
            $script:version = '1.2.3'
            $script:action = 'test'
            $script:Redstone = [Redstone]::new($script:publisher, $script:product, $script:version, $script:action)
        }

        It '<Title>: Publisher:<Publisher>' -TestCases @(
            foreach ($context in $contexts.GetEnumerator()) {
                @{
                    Title = $context.Name
                    Publisher = if ($context.Value.Publisher) { $context.Value.Publisher } else { $script:publisher }
                    Run = $context.Value.Run
                }
            }
        ) {
            param($Title,$Publisher,$Run)
            if ($Run -and $Run.ToString()) {
                $Run.ToString() | Invoke-Expression
            }
            $script:Redstone.Publisher | Should -Be $Publisher
        }

        It '<Title>: Product:<Product>' -TestCases @(
            foreach ($context in $contexts.GetEnumerator()) {
                @{
                    Title = $context.Name
                    Product = if ($context.Value.Product) { $context.Value.Product } else { $script:product }
                    Run = $context.Value.Run
                }
            }
        ) {
            param($Title,$Product,$Run)
            if ($Run -and $Run.ToString()) {
                $Run.ToString() | Invoke-Expression
            }
            $script:Redstone.Product | Should -Be $Product
        }

        It '<Title>: Version:<Version>' -TestCases @(
            foreach ($context in $contexts.GetEnumerator()) {
                @{
                    Title = $context.Name
                    Version = if ($context.Value.Version) { $context.Value.Version } else { $script:version }
                    Run = $context.Value.Run
                }
            }
        ) {
            param($Title,$Version,$Run)
            if ($Run -and $Run.ToString()) {
                $Run.ToString() | Invoke-Expression
            }
            $script:Redstone.Version | Should -Be $Version
        }

        It '<Title>: Action:<Action>' -TestCases @(
            foreach ($context in $contexts.GetEnumerator()) {
                @{
                    Title = $context.Name
                    Action = if ($context.Value.Action) { $context.Value.Action } else { $script:action }
                    Run = $context.Value.Run
                }
            }
        ) {
            param($Title,$Action,$Run)
            if ($Run -and $Run.ToString()) {
                $Run.ToString() | Invoke-Expression
            }
            $script:Redstone.Action | Should -Be $Action
        }

        It 'Settings Registry Key' {
            if ($context.Value -and $context.Value.ToString()) {
                $context.Value.ToString() | Invoke-Expression
            }
            $script:Redstone.Settings.Registry.Key | Should -Be 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\PSRedstone'
        }

        It 'Log File' {
            [bool] $isElevated = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
            if ($context.Value -and $context.Value.ToString()) {
                $context.Value.ToString() | Invoke-Expression
            }
            if ($isElevated) {
                $script:Redstone.Settings.Log.File.FullName | Should -Be "${env:SystemRoot}\Logs\Redstone\${publisher} ${product} ${version} ${action}.log"
            } else {
                $script:Redstone.Settings.Log.File.FullName | Should -Be "${env:Temp}\Logs\Redstone\${publisher} ${product} ${version} ${action}.log"
            }
        }

        It 'Log FileF' {
            [bool] $isElevated = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
            if ($context.Value -and $context.Value.ToString()) {
                $context.Value.ToString() | Invoke-Expression
            }
            if ($isElevated) {
                $script:Redstone.Settings.Log.FileF | Should -Be "${env:SystemRoot}\Logs\Redstone\${publisher} ${product} ${version} ${action}{0}.log"
            } else {
                $script:Redstone.Settings.Log.FileF | Should -Be "${env:Temp}\Logs\Redstone\${publisher} ${product} ${version} ${action}{0}.log"
            }
        }

        It 'PSDefaultParameterValues Write-Log:FilePath' {
            [bool] $isElevated = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
            if ($context.Value -and $context.Value.ToString()) {
                $context.Value.ToString() | Invoke-Expression
            }
            if ($isElevated) {
                $global:PSDefaultParameterValues.'Write-Log:FilePath' | Should -Be "${env:SystemRoot}\Logs\Redstone\${publisher} ${product} ${version} ${action}.log"
            } else {
                $global:PSDefaultParameterValues.'Write-Log:FilePath' | Should -Be "${env:Temp}\Logs\Redstone\${publisher} ${product} ${version} ${action}.log"
            }
        }

        It 'PSDefaultParameterValues *-Redstone*:LogFile' {
            [bool] $isElevated = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
            if ($context.Value -and $context.Value.ToString()) {
                $context.Value.ToString() | Invoke-Expression
            }
            if ($isElevated) {
                $global:PSDefaultParameterValues.'*-Redstone*:LogFile' | Should -Be "${env:SystemRoot}\Logs\Redstone\${publisher} ${product} ${version} ${action}.log"
            } else {
                $global:PSDefaultParameterValues.'*-Redstone*:LogFile' | Should -Be "${env:Temp}\Logs\Redstone\${publisher} ${product} ${version} ${action}.log"
            }
        }

        It 'PSDefaultParameterValues *-Redstone*:LogFileF' {
            [bool] $isElevated = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
            if ($context.Value -and $context.Value.ToString()) {
                $context.Value.ToString() | Invoke-Expression
            }
            if ($isElevated) {
                $global:PSDefaultParameterValues.'*-Redstone*:LogFileF' | Should -Be "${env:SystemRoot}\Logs\Redstone\${publisher} ${product} ${version} ${action}{0}.log"
            } else {
                $global:PSDefaultParameterValues.'*-Redstone*:LogFileF' | Should -Be "${env:Temp}\Logs\Redstone\${publisher} ${product} ${version} ${action}{0}.log"
            }
        }
    }
}
