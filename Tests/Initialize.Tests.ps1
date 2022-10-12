. '..\PSBacon\Private\Initialize.ps1'
[bool] $isElevated = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

Describe 'Initialize' {
    $bacon = [Bacon]::new('MyPublisher', 'MyProduct', '1.2.3', 'test')
    Context 'Bacon Class: Default' {
        It 'Publisher' {
            $bacon.Publisher | Should Be 'MyPublisher'
        }
        It 'Product' {
            $bacon.Product | Should Be 'MyProduct'
        }
        It 'Version' {
            $bacon.Version | Should Be '1.2.3'
        }
        It 'Action' {
            $bacon.Action | Should Be 'test'
        }
        It 'Settings Registry Key' {
            $bacon.Settings.Registry.Key | Should Be 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\PSBacon'
        }
        It 'Log File' {
            if ($isElevated) {
                $bacon.Settings.Log.File.FullName | Should Be "${env:SystemRoot}\Logs\Bacon\MyPublisher MyProduct 1.2.3 test.log"
            } else {
                $bacon.Settings.Log.File.FullName | Should Be "${env:Temp}\Logs\Bacon\MyPublisher MyProduct 1.2.3 test.log"
            }
        }
        It 'Log FileF' {
            if ($isElevated) {
                $bacon.Settings.Log.FileF | Should Be "${env:SystemRoot}\Logs\Bacon\MyPublisher MyProduct 1.2.3 test{0}.log"
            } else {
                $bacon.Settings.Log.FileF | Should Be "${env:Temp}\Logs\Bacon\MyPublisher MyProduct 1.2.3 test{0}.log"
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
                $global:PSDefaultParameterValues.'Write-Log:FilePath' | Should Be "${env:SystemRoot}\Logs\Bacon\MyPublisher MyProduct 1.2.3 test.log"
            } else {
                $global:PSDefaultParameterValues.'Write-Log:FilePath' | Should Be "${env:Temp}\Logs\Bacon\MyPublisher MyProduct 1.2.3 test.log"
            }
        }
        It 'PSDefaultParameterValues Invoke-BaconMsi:LogFileF' {
            if ($isElevated) {
                $global:PSDefaultParameterValues.'Invoke-BaconMsi:LogFileF' | Should Be "${env:SystemRoot}\Logs\Bacon\MyPublisher MyProduct 1.2.3 test{0}.log"
            } else {
                $global:PSDefaultParameterValues.'Invoke-BaconMsi:LogFileF' | Should Be "${env:Temp}\Logs\Bacon\MyPublisher MyProduct 1.2.3 test{0}.log"
            }
        }
        It 'PSDefaultParameterValues Invoke-BaconRun:LogFile' {
            if ($isElevated) {
                $global:PSDefaultParameterValues.'Invoke-BaconRun:LogFile' | Should Be "${env:SystemRoot}\Logs\Bacon\MyPublisher MyProduct 1.2.3 test.log"
            } else {
                $global:PSDefaultParameterValues.'Invoke-BaconRun:LogFile' | Should Be "${env:Temp}\Logs\Bacon\MyPublisher MyProduct 1.2.3 test.log"
            }
        }
    }

    Context 'Bacon Class: Publisher Change' {
        $bacon.Publisher = 'YourPublisher'
        It 'Publisher' {
            $bacon.Publisher | Should Be 'YourPublisher'
        }
        It 'Product' {
            $bacon.Product | Should Be 'MyProduct'
        }
        It 'Version' {
            $bacon.Version | Should Be '1.2.3'
        }
        It 'Action' {
            $bacon.Action | Should Be 'test'
        }
        It 'Settings Registry Key' {
            $bacon.Settings.Registry.Key | Should Be 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\PSBacon'
        }
        It 'Log File' {
            if ($isElevated) {
                $bacon.Settings.Log.File.FullName | Should Be "${env:SystemRoot}\Logs\Bacon\YourPublisher MyProduct 1.2.3 test.log"
            } else {
                $bacon.Settings.Log.File.FullName | Should Be "${env:Temp}\Logs\Bacon\YourPublisher MyProduct 1.2.3 test.log"
            }
        }
        It 'Log FileF' {
            if ($isElevated) {
                $bacon.Settings.Log.FileF | Should Be "${env:SystemRoot}\Logs\Bacon\YourPublisher MyProduct 1.2.3 test{0}.log"
            } else {
                $bacon.Settings.Log.FileF | Should Be "${env:Temp}\Logs\Bacon\YourPublisher MyProduct 1.2.3 test{0}.log"
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
                $global:PSDefaultParameterValues.'Write-Log:FilePath' | Should Be "${env:SystemRoot}\Logs\Bacon\YourPublisher MyProduct 1.2.3 test.log"
            } else {
                $global:PSDefaultParameterValues.'Write-Log:FilePath' | Should Be "${env:Temp}\Logs\Bacon\YourPublisher MyProduct 1.2.3 test.log"
            }
        }
        It 'PSDefaultParameterValues Invoke-BaconMsi:LogFileF' {
            if ($isElevated) {
                $global:PSDefaultParameterValues.'Invoke-BaconMsi:LogFileF' | Should Be "${env:SystemRoot}\Logs\Bacon\YourPublisher MyProduct 1.2.3 test{0}.log"
            } else {
                $global:PSDefaultParameterValues.'Invoke-BaconMsi:LogFileF' | Should Be "${env:Temp}\Logs\Bacon\YourPublisher MyProduct 1.2.3 test{0}.log"
            }
        }
    }

    Context 'Bacon Class: Product Change' {
        $bacon.Product = 'YourProduct'
        It 'Publisher' {
            $bacon.Publisher | Should Be 'YourPublisher'
        }
        It 'Product' {
            $bacon.Product | Should Be 'YourProduct'
        }
        It 'Version' {
            $bacon.Version | Should Be '1.2.3'
        }
        It 'Action' {
            $bacon.Action | Should Be 'test'
        }
        It 'Settings Registry Key' {
            $bacon.Settings.Registry.Key | Should Be 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\PSBacon'
        }
        It 'Log File' {
            if ($isElevated) {
                $bacon.Settings.Log.File.FullName | Should Be "${env:SystemRoot}\Logs\Bacon\YourPublisher YourProduct 1.2.3 test.log"
            } else {
                $bacon.Settings.Log.File.FullName | Should Be "${env:Temp}\Logs\Bacon\YourPublisher YourProduct 1.2.3 test.log"
            }
        }
        It 'Log FileF' {
            if ($isElevated) {
                $bacon.Settings.Log.FileF | Should Be "${env:SystemRoot}\Logs\Bacon\YourPublisher YourProduct 1.2.3 test{0}.log"
            } else {
                $bacon.Settings.Log.FileF | Should Be "${env:Temp}\Logs\Bacon\YourPublisher YourProduct 1.2.3 test{0}.log"
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
                $global:PSDefaultParameterValues.'Write-Log:FilePath' | Should Be "${env:SystemRoot}\Logs\Bacon\YourPublisher YourProduct 1.2.3 test.log"
            } else {
                $global:PSDefaultParameterValues.'Write-Log:FilePath' | Should Be "${env:Temp}\Logs\Bacon\YourPublisher YourProduct 1.2.3 test.log"
            }
        }
        It 'PSDefaultParameterValues Invoke-BaconMsi:LogFileF' {
            if ($isElevated) {
                $global:PSDefaultParameterValues.'Invoke-BaconMsi:LogFileF' | Should Be "${env:SystemRoot}\Logs\Bacon\YourPublisher YourProduct 1.2.3 test{0}.log"
            } else {
                $global:PSDefaultParameterValues.'Invoke-BaconMsi:LogFileF' | Should Be "${env:Temp}\Logs\Bacon\YourPublisher YourProduct 1.2.3 test{0}.log"
            }
        }
    }

    Context 'Bacon Class: Version Change' {
        $bacon.Version = '2.3.4'
        It 'Publisher' {
            $bacon.Publisher | Should Be 'YourPublisher'
        }
        It 'Product' {
            $bacon.Product | Should Be 'YourProduct'
        }
        It 'Version' {
            $bacon.Version | Should Be '2.3.4'
        }
        It 'Action' {
            $bacon.Action | Should Be 'test'
        }
        It 'Settings Registry Key' {
            $bacon.Settings.Registry.Key | Should Be 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\PSBacon'
        }
        It 'Log File' {
            if ($isElevated) {
                $bacon.Settings.Log.File.FullName | Should Be "${env:SystemRoot}\Logs\Bacon\YourPublisher YourProduct 2.3.4 test.log"
            } else {
                $bacon.Settings.Log.File.FullName | Should Be "${env:Temp}\Logs\Bacon\YourPublisher YourProduct 2.3.4 test.log"
            }
        }
        It 'Log FileF' {
            if ($isElevated) {
                $bacon.Settings.Log.FileF | Should Be "${env:SystemRoot}\Logs\Bacon\YourPublisher YourProduct 2.3.4 test{0}.log"
            } else {
                $bacon.Settings.Log.FileF | Should Be "${env:Temp}\Logs\Bacon\YourPublisher YourProduct 2.3.4 test{0}.log"
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
                $global:PSDefaultParameterValues.'Write-Log:FilePath' | Should Be "${env:SystemRoot}\Logs\Bacon\YourPublisher YourProduct 2.3.4 test.log"
            } else {
                $global:PSDefaultParameterValues.'Write-Log:FilePath' | Should Be "${env:Temp}\Logs\Bacon\YourPublisher YourProduct 2.3.4 test.log"
            }
        }
        It 'PSDefaultParameterValues Invoke-BaconMsi:LogFileF' {
            if ($isElevated) {
                $global:PSDefaultParameterValues.'Invoke-BaconMsi:LogFileF' | Should Be "${env:SystemRoot}\Logs\Bacon\YourPublisher YourProduct 2.3.4 test{0}.log"
            } else {
                $global:PSDefaultParameterValues.'Invoke-BaconMsi:LogFileF' | Should Be "${env:Temp}\Logs\Bacon\YourPublisher YourProduct 2.3.4 test{0}.log"
            }
        }
    }
}
