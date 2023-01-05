$script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
. ('{0}\PSRedstone\Private\RedstoneClassAndEnums.ps1' -f $psProjectRoot.FullName)

Describe ('New-Redstone') {
    BeforeAll {
        $script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
        . ('{0}\PSRedstone\Private\RedstoneClassAndEnums.ps1' -f $psProjectRoot.FullName)
        . ('{0}\PSRedstone\Public\New-Redstone.ps1' -f $psProjectRoot.FullName)
    }

    Context ('NoParams') {
        BeforeEach {
            $script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
            if (Test-Path -LiteralPath 'variable:RedstonePester') {
                Clear-Variable -Name 'RedstonePester'
            }
            $script:publisher = 'MyPublisher'
            $script:product = 'MyProduct'
            $script:version = '1.2.3'
            $script:action = 'install'
            [IO.FileInfo] $json = [IO.Path]::Combine($PWD.ProviderPath, 'settings.json')
            $jsonData = @{
                Publisher = $script:publisher
                Product = $script:product
                Version = $script:version
                Action = $script:action
            }
            $jsonData | ConvertTo-Json | Out-File -Encoding 'ascii' -LiteralPath $json.FullName
            $json.Refresh()
        }

        AfterEach {
            $script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
            Remove-Item -LiteralPath ([IO.Path]::Combine($PWD.ProviderPath, 'settings.json')) -Force
        }

        It ('Redstone Type') {
            $redstonePester, $settingsPester = New-Redstone
            $RedstonePester.GetType().FullName | Should -Be 'Redstone'
        }
    }

    Context ('SettingsJson') {
        BeforeEach {
            $script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
            if (Test-Path -LiteralPath 'variable:RedstonePester') {
                Clear-Variable -Name 'RedstonePester'
            }
            $script:publisher = 'MyPublisher'
            $script:product = 'MyProduct'
            $script:version = '1.2.3'
            $script:action = 'install'
            [IO.FileInfo] $json = [IO.Path]::Combine($script:psProjectRoot.FullName, 'dev', 'settings.json')
            $jsonData = @{
                Publisher = $script:publisher
                Product = $script:product
                Version = $script:version
                Action = $script:action
            }
            $jsonData | ConvertTo-Json | Out-File -Encoding 'ascii' -LiteralPath $json.FullName
            $json.Refresh()
        }

        AfterEach {
            $script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
            Remove-Item -LiteralPath ([IO.Path]::Combine($script:psProjectRoot.FullName, 'dev', 'settings.json')) -Force
        }

        It ('Redstone ParameterName Provided Type') {
            $redstonePester, $settingsPester = New-Redstone -SettingsJson ([IO.Path]::Combine($script:psProjectRoot.FullName, 'dev', 'settings.json'))
            $redstonePester.GetType().FullName | Should -Be 'Redstone'
        }

        It ('Redstone Positional Type') {
            $redstonePester, $settingsPester = New-Redstone ([IO.FileInfo] [IO.Path]::Combine($script:psProjectRoot.FullName, 'dev', 'settings.json'))
            $redstonePester.GetType().FullName | Should -Be 'Redstone'
        }
    }

    Context ('ManuallyDefined') {
        BeforeEach {
            if (Test-Path -LiteralPath 'variable:RedstonePester') {
                Clear-Variable -Name 'RedstonePester'
            }
        }

        It ('Redstone ParameterNameProvided Type') {
            $redstonePester, $settingsPester = New-Redstone -Publisher 'MyPublisher' -Product 'MyProduct' -Version '1.2.3' -Action 'install'
            $RedstonePester.GetType().FullName | Should -Be 'Redstone'
        }

        It ('Redstone Positional Type') {
            $redstonePester, $settingsPester = New-Redstone 'MyPublisher' 'MyProduct' '1.2.3' 'install'
            $RedstonePester.GetType().FullName | Should -Be 'Redstone'
        }
    }
}
