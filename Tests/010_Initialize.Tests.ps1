$psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
. ('{0}\PSBacon\Private\Initialize.ps1' -f $psProjectRoot.FullName)
[bool] $isElevated = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

Describe 'Initialize' {
    $script:publisher = 'MyPublisher'
    $script:product = 'MyProduct'
    $script:version = '1.2.3'
    $script:action = 'test'
    $bacon = [Bacon]::new($script:publisher, $script:product, $script:version, $script:action)

    $contexts = [ordered] @{
        'Default' = {}
        'Publisher Change' = {
            $script:publisher = 'YourPublisher'
            $bacon.Publisher = $script:publisher
        }
        'Product Change' = {
            $script:product = 'YourProduct'
            $bacon.Product = $script:product
        }
        'Version Change' = {
            $script:version = '1.2.3'
            $bacon.Version = $script:version
        }
        'Action Change' = {
            $script:action = 'testing'
            $bacon.Action = $script:action
        }
    }

    foreach ($context in $contexts.GetEnumerator()) {
        Context ('Bacon Class: {0}' -f $context.Name) {
            # $context.Value.ToString() | Invoke-Expression
            & $context.Value

            It 'Publisher' {
                $bacon.Publisher | Should Be $publisher
            }
            It 'Product' {
                $bacon.Product | Should Be $product
            }
            It 'Version' {
                $bacon.Version | Should Be $version
            }
            It 'Action' {
                $bacon.Action | Should Be $action
            }
            It 'Settings Registry Key' {
                $bacon.Settings.Registry.Key | Should Be 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\PSBacon'
            }
            It 'Log File' {
                if ($isElevated) {
                    $bacon.Settings.Log.File.FullName | Should Be "${env:SystemRoot}\Logs\Bacon\${publisher} ${product} ${version} ${action}.log"
                } else {
                    $bacon.Settings.Log.File.FullName | Should Be "${env:Temp}\Logs\Bacon\${publisher} ${product} ${version} ${action}.log"
                }
            }
            It 'Log FileF' {
                if ($isElevated) {
                    $bacon.Settings.Log.FileF | Should Be "${env:SystemRoot}\Logs\Bacon\${publisher} ${product} ${version} ${action}{0}.log"
                } else {
                    $bacon.Settings.Log.FileF | Should Be "${env:Temp}\Logs\Bacon\${publisher} ${product} ${version} ${action}{0}.log"
                }
            }
            It 'Settings Functions Get-BaconRegistryValueOrDefault RegistryKeyRoot' {
                $bacon.Settings.Functions.'Get-BaconRegistryValueOrDefault'.RegistryKeyRoot | Should Be 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\PSBacon'
            }
            It 'Settings Functions Get-BaconRegistryValueOrDefault OnlyUseDefaultSettings' {
                $bacon.Settings.Functions.'Get-BaconRegistryValueOrDefault'.OnlyUseDefaultSettings | Should Be 0
            }
            It 'PSDefaultParameterValues Write-Log:FilePath' {
                if ($isElevated) {
                    $global:PSDefaultParameterValues.'Write-Log:FilePath' | Should Be "${env:SystemRoot}\Logs\Bacon\${publisher} ${product} ${version} ${action}.log"
                } else {
                    $global:PSDefaultParameterValues.'Write-Log:FilePath' | Should Be "${env:Temp}\Logs\Bacon\${publisher} ${product} ${version} ${action}.log"
                }
            }
            It 'PSDefaultParameterValues Invoke-BaconMsi:LogFileF' {
                if ($isElevated) {
                    $global:PSDefaultParameterValues.'Invoke-BaconMsi:LogFileF' | Should Be "${env:SystemRoot}\Logs\Bacon\${publisher} ${product} ${version} ${action}{0}.log"
                } else {
                    $global:PSDefaultParameterValues.'Invoke-BaconMsi:LogFileF' | Should Be "${env:Temp}\Logs\Bacon\${publisher} ${product} ${version} ${action}{0}.log"
                }
            }
            It 'PSDefaultParameterValues Invoke-BaconRun:LogFile' {
                if ($isElevated) {
                    $global:PSDefaultParameterValues.'Invoke-BaconRun:LogFile' | Should Be "${env:SystemRoot}\Logs\Bacon\${publisher} ${product} ${version} ${action}.log"
                } else {
                    $global:PSDefaultParameterValues.'Invoke-BaconRun:LogFile' | Should Be "${env:Temp}\Logs\Bacon\${publisher} ${product} ${version} ${action}.log"
                }
            }
        }
    }
}
