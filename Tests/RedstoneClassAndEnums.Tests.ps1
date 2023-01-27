Describe 'RedstoneClassAndEnums' -Tag 'Class' {
    $script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
    . ('{0}\PSRedstone\Private\RedstoneClassAndEnums.ps1' -f $psProjectRoot.FullName)

    $contexts = [ordered] @{
        'Default' = @{
            Publisher = 'MyPublisher'
            Product = 'MyProduct'
            Version = '1.2.3'
            Action = { if ($instantiation.Name -eq 'FourParams') { 'test' } else { ([IO.FileInfo] $PSCommandPath).BaseName } }
            Run = {}
        }
        'Publisher Change' = @{
            Publisher = 'YourPublisher'
            Product = 'MyProduct'
            Version = '1.2.3'
            Action = { if ($instantiation.Name -eq 'FourParams') { 'test' } else { ([IO.FileInfo] $PSCommandPath).BaseName } }
            Run = {
                $script:Redstone.Publisher = 'YourPublisher'
            }
        }
        'Product Change' = @{
            Publisher = 'MyPublisher'
            Product = 'YourProduct'
            Version = '1.2.3'
            Action = { if ($instantiation.Name -eq 'FourParams') { 'test' } else { ([IO.FileInfo] $PSCommandPath).BaseName } }
            Run = {
                $script:Redstone.Product = 'YourProduct'
            }
        }
        'Version Change' = @{
            Publisher = 'MyPublisher'
            Product = 'MyProduct'
            Version = '2.3.4'
            Action = { if ($instantiation.Name -eq 'FourParams') { 'test' } else { ([IO.FileInfo] $PSCommandPath).BaseName } }
            Run = {
                $script:Redstone.Version = '2.3.4'
            }
        }
        'Action Change' = @{
            Publisher = 'MyPublisher'
            Product = 'MyProduct'
            Version = '1.2.3'
            Action = { 'testing' }
            Run = {
                $script:Redstone.Action = 'testing'
            }
        }
    }

    $instantiations = @{
        NoParamsPwd = @{
            BeforeEach = {
                $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
                . ('{0}\PSRedstone\Private\RedstoneClassAndEnums.ps1' -f $psProjectRoot.FullName)

                $script:publisher = 'MyPublisher'
                $script:product = 'MyProduct'
                $script:version = '1.2.3'
                $script:action = ([IO.FileInfo] $PSCommandPath).BaseName
                [IO.FileInfo] $json = [IO.Path]::Combine($PWD.Path, 'settings.json')
                $jsonData = @{
                    Publisher = $script:publisher
                    Product = $script:product
                    Version = $script:version
                }
                $jsonData | ConvertTo-Json | Out-File -Encoding 'ascii' -LiteralPath $json.FullName
                $json.Refresh()

                $script:Redstone = [Redstone]::new()
                Remove-Item -LiteralPath $json.FullName -Force
            }
        }
        NoParamsPSScriptRoot = @{
            BeforeEach = {
                $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
                . ('{0}\PSRedstone\Private\RedstoneClassAndEnums.ps1' -f $psProjectRoot.FullName)

                $script:publisher = 'MyPublisher'
                $script:product = 'MyProduct'
                $script:version = '1.2.3'
                $script:action = ([IO.FileInfo] $PSCommandPath).BaseName
                [IO.FileInfo] $json = [IO.Path]::Combine($PSScriptRoot, 'settings.json')
                $jsonData = @{
                    Publisher = $script:publisher
                    Product = $script:product
                    Version = $script:version
                }
                $jsonData | ConvertTo-Json | Out-File -Encoding 'ascii' -LiteralPath $json.FullName
                $json.Refresh()

                $script:Redstone = [Redstone]::new()
                Remove-Item -LiteralPath $json.FullName -Force
            }
        }
        FourParams = @{
            BeforeEach = {
                $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
                . ('{0}\PSRedstone\Private\RedstoneClassAndEnums.ps1' -f $psProjectRoot.FullName)

                $script:publisher = 'MyPublisher'
                $script:product = 'MyProduct'
                $script:version = '1.2.3'
                $script:action = 'test'
                $script:Redstone = [Redstone]::new($script:publisher, $script:product, $script:version, $script:action)
            }
        }
    }

    BeforeAll {
        $env:PSRedstoneRegistryKeyRoot = 'Registry::{0}' -f (Get-PSDrive 'TestRegistry').Root
    }

    foreach ($instantiation in $instantiations.GetEnumerator()) {
        Context ('Redstone Class {0}' -f $instantiation.Name) {
            BeforeEach $instantiation.Value.BeforeEach

            It '<Title>: Publisher: <Publisher>' -TestCases @(
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

            It '<Title>: Product: <Product>' -TestCases @(
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

            It '<Title>: Version: <Version>' -TestCases @(
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

            It '<Title>: Action: <Action>' -TestCases @(
                foreach ($context in $contexts.GetEnumerator()) {
                    @{
                        Title = $context.Name
                        Action = if ($context.Value.Action) { & $context.Value.Action } else { $script:action }
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
                $script:Redstone.Settings.Registry.KeyRoot | Should -Be ('Registry::{0}' -f (Get-PSDrive 'TestRegistry').Root)
            }

            It 'Log File' {
                if ($context.Value -and $context.Value.ToString()) {
                    $context.Value.ToString() | Invoke-Expression
                }
                $script:Redstone.Settings.Log.File.FullName | Should -BeLike "*\Logs\Redstone\${publisher} ${product} ${version} ${action}.log"
            }

            It 'Log FileF' {
                if ($context.Value -and $context.Value.ToString()) {
                    $context.Value.ToString() | Invoke-Expression
                }
                $script:Redstone.Settings.Log.FileF | Should -BeLike "*\Logs\Redstone\${publisher} ${product} ${version} ${action}.{0}.log"
            }

            It 'PSDefaultParameterValues Write-Log:FilePath' {
                if ($context.Value -and $context.Value.ToString()) {
                    $context.Value.ToString() | Invoke-Expression
                }
                $global:PSDefaultParameterValues.'Write-Log:FilePath' | Should -BeLike "*\Logs\Redstone\${publisher} ${product} ${version} ${action}.log"
            }

            It 'PSDefaultParameterValues *-*:LogFile' -Skip {
                if ($context.Value -and $context.Value.ToString()) {
                    $context.Value.ToString() | Invoke-Expression
                }
                $global:PSDefaultParameterValues.'*-*:LogFile' | Should -BeLike "*\Logs\Redstone\${publisher} ${product} ${version} ${action}.log"
            }

            It 'PSDefaultParameterValues *-*:LogFileF' -Skip {
                if ($context.Value -and $context.Value.ToString()) {
                    $context.Value.ToString() | Invoke-Expression
                }
                $global:PSDefaultParameterValues.'*-*:LogFileF' | Should -BeLike "*\Logs\Redstone\${publisher} ${product} ${version} ${action}.{0}.log"
            }
        }
    }

    Context ('No Settings File, No Params') {
        It 'No Settings Should Throw' {
            { $script:Redstone = [Redstone]::new() } | Should -Throw
        }
    }

    Context ('Redstone Class') {
        BeforeAll {
            $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
            . ('{0}\PSRedstone\Private\RedstoneClassAndEnums.ps1' -f $psProjectRoot.FullName)

            $script:publisher = 'MyPublisher'
            $script:product = 'MyProduct'
            $script:version = '1.2.3'
            $script:action = 'test'
            $script:Redstone = [Redstone]::new($script:publisher, $script:product, $script:version, $script:action)
        }

        It ('Redstone') {
            $script:Redstone | Should -Not -BeNullOrEmpty
        }

        It ('Redstone.IsElevated') {
            $script:Redstone.IsElevated | Should -Be (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
        }

        It ('Redstone.Publisher') {
            $script:Redstone.Publisher | Should -Be $script:publisher
        }

        It ('Redstone.Product') {
            $script:Redstone.Product | Should -Be $script:product
        }

        It ('Redstone.Version') {
            $script:Redstone.Version | Should -Be $script:version
        }

        It ('Redstone.Action') {
            $script:Redstone.Action | Should -Be $script:action
        }
    }

    Context ('GetCimInstance') {
        BeforeAll {
            $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
            . ('{0}\PSRedstone\Private\RedstoneClassAndEnums.ps1' -f $psProjectRoot.FullName)

            $script:publisher = 'MyPublisher'
            $script:product = 'MyProduct'
            $script:version = '1.2.3'
            $script:action = 'test'
            $script:Redstone = [Redstone]::new($script:publisher, $script:product, $script:version, $script:action)
        }

        It ('CimInstance Initially Empty') -Skip {
            Write-Host ($script:Redstone.CimInstance | Out-String)
            $script:Redstone.CimInstance | Should -BeNullOrEmpty
        }

        It ('CimInstance Query Works') {
            { $script:Redstone.CimInstance.Win32_Service } | Should -Not -Throw
        }

        It ('CimInstance NOT Empty') -Skip {
            $script:Redstone.CimInstance.Win32_Service
            ($script:Redstone.CimInstance | Measure-Object).Count | Should -Be 1
        }

        It ('GetCimInstance ReturnCimInstanceNotClass') -Skip {
            $ref = $Redstone.GetCimInstance('Win32_Service')
            $dif = $Redstone.CimInstance.Win32_Service
            # Ref & Dif should be the same, so no differences will be returned by Compare-Object
            Compare-Object -ReferenceObject $ref -DifferenceObject $dif | Should -BeNullOrEmpty
        }

        It ('GetCimInstance ReturnCimInstanceNotClass') -Skip {
            $ref = $Redstone.GetCimInstance('Win32_Service', $true).Win32_Service
            $dif = $Redstone.CimInstance.Win32_Service
            # Ref & Dif should be the same, so no differences will be returned by Compare-Object
            Compare-Object -ReferenceObject $ref -DifferenceObject $dif | Should -BeNullOrEmpty
        }

        It ('CimInstanceRefreshed') {
            $script:Redstone.CimInstanceRefreshed('Win32_Service') | Should -Not -BeNullOrEmpty
        }
    }

    Context ('Is64BitOperatingSystem') {
        BeforeAll {
            $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
            . ('{0}\PSRedstone\Private\RedstoneClassAndEnums.ps1' -f $psProjectRoot.FullName)

            $script:publisher = 'MyPublisher'
            $script:product = 'MyProduct'
            $script:version = '1.2.3'
            $script:action = 'test'
            $script:Redstone = [Redstone]::new($script:publisher, $script:product, $script:version, $script:action)
        }

        It ('Is64BitOperatingSystem') {
            $script:Redstone.Is64BitOperatingSystem() | Should -Be ([System.Environment]::Is64BitOperatingSystem)
        }

        It ('Is64BitOperatingSystem Type') {
            $script:Redstone.Is64BitOperatingSystem() | Should -BeOfType 'System.Boolean'
        }

        It ('Is64BitOperatingSystem Override True') {
            $script:Redstone.Is64BitOperatingSystem($true) | Should -BeOfType 'System.Collections.DictionaryEntry'
        }

        It ('Is64BitOperatingSystem Overridden True') {
            $script:Redstone.Is64BitOperatingSystem() | Should -Be $true
        }

        It ('Is64BitOperatingSystem Overridden True Type') {
            $script:Redstone.Is64BitOperatingSystem() | Should -BeOfType 'System.Boolean'
        }

        It ('Is64BitOperatingSystem Override False') {
            $script:Redstone.Is64BitOperatingSystem($false) | Should -BeOfType 'System.Collections.DictionaryEntry'
        }

        It ('Is64BitOperatingSystem Overridden False') {
            $script:Redstone.Is64BitOperatingSystem() | Should -Be $false
        }

        It ('Is64BitOperatingSystem Overridden False Type') {
            $script:Redstone.Is64BitOperatingSystem() | Should -BeOfType 'System.Boolean'
        }
    }

    Context ('Is64BitProcess') {
        BeforeAll {
            $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
            . ('{0}\PSRedstone\Private\RedstoneClassAndEnums.ps1' -f $psProjectRoot.FullName)

            $script:publisher = 'MyPublisher'
            $script:product = 'MyProduct'
            $script:version = '1.2.3'
            $script:action = 'test'
            $script:Redstone = [Redstone]::new($script:publisher, $script:product, $script:version, $script:action)
        }

        It ('Is64BitProcess') {
            $script:Redstone.Is64BitProcess() | Should -Be ([System.Environment]::Is64BitProcess)
        }

        It ('Is64BitProcess Type') {
            $script:Redstone.Is64BitProcess() | Should -BeOfType 'System.Boolean'
        }

        It ('Is64BitProcess Override True') {
            $script:Redstone.Is64BitProcess($true) | Should -BeOfType 'System.Collections.DictionaryEntry'
        }

        It ('Is64BitProcess Overridden True') {
            $script:Redstone.Is64BitProcess() | Should -Be $true
        }

        It ('Is64BitProcess Overridden True Type') {
            $script:Redstone.Is64BitProcess() | Should -BeOfType 'System.Boolean'
        }

        It ('Is64BitProcess Override False') {
            $script:Redstone.Is64BitProcess($false) | Should -BeOfType 'System.Collections.DictionaryEntry'
        }

        It ('Is64BitProcess Overridden False') {
            $script:Redstone.Is64BitProcess() | Should -Be $false
        }

        It ('Is64BitProcess Overridden False Type') {
            $script:Redstone.Is64BitProcess() | Should -BeOfType 'System.Boolean'
        }
    }

    Context ('Env') {
        BeforeAll {
            $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
            . ('{0}\PSRedstone\Private\RedstoneClassAndEnums.ps1' -f $psProjectRoot.FullName)

            $script:publisher = 'MyPublisher'
            $script:product = 'MyProduct'
            $script:version = '1.2.3'
            $script:action = 'test'
            $script:Redstone = [Redstone]::new($script:publisher, $script:product, $script:version, $script:action)
        }

        $script:arch64OsAndProc = @(
            @{
                OS = if ([System.Environment]::Is64BitOperatingSystem) { 64 } else { 32 }
                Proc = if ([System.Environment]::Is64BitProcess) { 64 } else { 32 }
                CommonProgramFiles = 'C:\Program Files\Common Files'
                'CommonProgramFiles(x86)' = 'C:\Program Files (x86)\Common Files'
                PROCESSOR_ARCHITECTURE = 'AMD64'
                ProgramFiles = 'C:\Program Files'
                'ProgramFiles(x86)' = 'C:\Program Files (x86)'
                System32 = 'C:\WINDOWS\System32'
                SysWOW64 = 'C:\WINDOWS\SysWOW64'
            },
            @{
                OS = 64
                Proc = 64
                CommonProgramFiles = 'C:\Program Files\Common Files'
                'CommonProgramFiles(x86)' = 'C:\Program Files (x86)\Common Files'
                PROCESSOR_ARCHITECTURE = 'AMD64'
                ProgramFiles = 'C:\Program Files'
                'ProgramFiles(x86)' = 'C:\Program Files (x86)'
                System32 = 'C:\WINDOWS\System32'
                SysWOW64 = 'C:\WINDOWS\SysWOW64'
            },
            @{
                OS = 64
                Proc = 32
                CommonProgramFiles = 'C:\Program Files\Common Files'
                'CommonProgramFiles(x86)' = 'C:\Program Files (x86)\Common Files'
                PROCESSOR_ARCHITECTURE = $null # Really: 'AMD64'
                ProgramFiles = 'C:\Program Files'
                'ProgramFiles(x86)' = 'C:\Program Files (x86)'
                System32 = 'C:\WINDOWS\SysNative'
                SysWOW64 = 'C:\WINDOWS\SysWOW64'
            },
            @{
                OS = 32
                Proc = 32
                CommonProgramFiles = 'C:\Program Files\Common Files'
                'CommonProgramFiles(x86)' = 'C:\Program Files\Common Files'
                PROCESSOR_ARCHITECTURE = 'AMD64' # Really: 'x86'
                ProgramFiles = 'C:\Program Files'
                'ProgramFiles(x86)' = 'C:\Program Files'
                System32 = 'C:\WINDOWS\System32'
                SysWOW64 = 'C:\WINDOWS\System32'
            }
        )

        It ('Real Environment: OperatingSystem 64') {
            # The rest of the tests expect us to be running in 64bit.
            [System.Environment]::Is64BitOperatingSystem | Should -Be $true
        }

        It ('Real Environment: Process 64') {
            # The rest of the tests expect us to be running in 64bit.
            [System.Environment]::Is64BitProcess | Should -Be $true
        }

        It ('Env') {
            $script:Redstone.Env | Should -Not -BeNullOrEmpty
        }

        It ('Env NOT Empty (OS<OS>, Proc<Proc>)') -TestCases $script:arch64OsAndProc {
            $script:Redstone.Is64BitOperatingSystem(($OS -eq 64)) | Out-String | Write-Verbose
            $script:Redstone.Is64BitProcess(($Proc -eq 64)) | Out-String | Write-Verbose
            $script:Redstone.SetUpEnv()
            $script:Redstone.Env | Should -Not -BeNullOrEmpty
        }

        It ('Env CommonProgramFiles (OS<OS>, Proc<Proc>)') -TestCases $script:arch64OsAndProc {
            $script:Redstone.Is64BitOperatingSystem(($OS -eq 64)) | Out-String | Write-Verbose
            $script:Redstone.Is64BitProcess(($Proc -eq 64)) | Out-String | Write-Verbose
            $script:Redstone.SetUpEnv()
            $script:Redstone.Env.CommonProgramFiles | Should -Be $CommonProgramFiles
        }

        It ('Env CommonProgramFiles(x86) (OS<OS>, Proc<Proc>)') -TestCases $script:arch64OsAndProc {
            $script:Redstone.Is64BitOperatingSystem(($OS -eq 64)) | Out-String | Write-Verbose
            $script:Redstone.Is64BitProcess(($Proc -eq 64)) | Out-String | Write-Verbose
            $script:Redstone.SetUpEnv()
            $script:Redstone.Env.'CommonProgramFiles(x86)' | Should -Be ${CommonProgramFiles(x86)}
        }

        It ('Env PROCESSOR_ARCHITECTURE (OS<OS>, Proc<Proc>)') -TestCases $script:arch64OsAndProc {
            $script:Redstone.Is64BitOperatingSystem(($OS -eq 64)) | Out-String | Write-Verbose
            $script:Redstone.Is64BitProcess(($Proc -eq 64)) | Out-String | Write-Verbose
            $script:Redstone.SetUpEnv()
            $script:Redstone.Env.PROCESSOR_ARCHITECTURE | Should -Be $PROCESSOR_ARCHITECTURE
        }

        It ('Env ProgramFiles (OS<OS>, Proc<Proc>)') -TestCases $script:arch64OsAndProc {
            $script:Redstone.Is64BitOperatingSystem(($OS -eq 64)) | Out-String | Write-Verbose
            $script:Redstone.Is64BitProcess(($Proc -eq 64)) | Out-String | Write-Verbose
            $script:Redstone.SetUpEnv()
            $script:Redstone.Env.ProgramFiles | Should -Be $ProgramFiles
        }

        It ('Env ProgramFiles(x86) (OS<OS>, Proc<Proc>)') -TestCases $script:arch64OsAndProc {
            $script:Redstone.Is64BitOperatingSystem(($OS -eq 64)) | Out-String | Write-Verbose
            $script:Redstone.Is64BitProcess(($Proc -eq 64)) | Out-String | Write-Verbose
            $script:Redstone.SetUpEnv()
            $script:Redstone.Env.'ProgramFiles(x86)' | Should -Be ${ProgramFiles(x86)}
        }

        It ('Env System32 (OS<OS>, Proc<Proc>)') -TestCases $script:arch64OsAndProc {
            $script:Redstone.Is64BitOperatingSystem(($OS -eq 64)) | Out-String | Write-Verbose
            $script:Redstone.Is64BitProcess(($Proc -eq 64)) | Out-String | Write-Verbose
            $script:Redstone.SetUpEnv()
            $script:Redstone.Env.System32 | Should -Be $System32
        }

        It ('Env SysWOW64 (OS<OS>, Proc<Proc>)') -TestCases $script:arch64OsAndProc {
            $script:Redstone.Is64BitOperatingSystem(($OS -eq 64)) | Out-String | Write-Verbose
            $script:Redstone.Is64BitProcess(($Proc -eq 64)) | Out-String | Write-Verbose
            $script:Redstone.SetUpEnv()
            $script:Redstone.Env.SysWOW64 | Should -Be $SysWOW64
        }
    }

    Context ('OS') {
        BeforeAll {
            $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
            . ('{0}\PSRedstone\Private\RedstoneClassAndEnums.ps1' -f $psProjectRoot.FullName)

            $script:publisher = 'MyPublisher'
            $script:product = 'MyProduct'
            $script:version = '1.2.3'
            $script:action = 'test'
            $script:Redstone = [Redstone]::new($script:publisher, $script:product, $script:version, $script:action)
        }

        It ('OS') {
            $script:Redstone.OS | Should -Not -BeNullOrEmpty
        }

        It ('OS IsServerOS Type') {
            $script:Redstone.OS.IsServerOS | Should -BeOfType 'System.Boolean'
        }
    }

    Context ('ProfileList') {
        BeforeAll {
            $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
            . ('{0}\PSRedstone\Private\RedstoneClassAndEnums.ps1' -f $psProjectRoot.FullName)

            $script:publisher = 'MyPublisher'
            $script:product = 'MyProduct'
            $script:version = '1.2.3'
            $script:action = 'test'
            $script:Redstone = [Redstone]::new($script:publisher, $script:product, $script:version, $script:action)
        }

        It ('ProfileList') {
            $script:Redstone.ProfileList | Should -Not -BeNullOrEmpty
        }

        It ('ProfileList ProfilesDirectory') {
            $script:Redstone.ProfileList.ProfilesDirectory | Should -BeOfType 'System.IO.DirectoryInfo'
        }

        It ('ProfileList ProgramData') {
            $script:Redstone.ProfileList.ProgramData | Should -BeOfType 'System.IO.DirectoryInfo'
        }

        It ('ProfileList Default') {
            $script:Redstone.ProfileList.Default | Should -BeOfType 'System.IO.DirectoryInfo'
        }

        It ('ProfileList Public') {
            $script:Redstone.ProfileList.Public | Should -BeOfType 'System.IO.DirectoryInfo'
        }

        It ('ProfileList Profiles SYSTEM Domain Type') {
            ($script:Redstone.ProfileList.Profiles | Where-Object { $_.Username -eq 'SYSTEM' }).Domain | Should -BeOfType 'System.String'
        }

        It ('ProfileList Profiles SYSTEM Domain') {
            ($script:Redstone.ProfileList.Profiles | Where-Object { $_.Username -eq 'SYSTEM' }).Domain | Should -Be 'NT AUTHORITY'
        }

        It ('ProfileList Profiles SYSTEM Username Type') {
            ($script:Redstone.ProfileList.Profiles | Where-Object { $_.Username -eq 'SYSTEM' }).Username | Should -BeOfType 'System.String'
        }

        It ('ProfileList Profiles SYSTEM Username') {
            ($script:Redstone.ProfileList.Profiles | Where-Object { $_.Username -eq 'SYSTEM' }).Username | Should -Be 'SYSTEM'
        }

        It ('ProfileList Profiles SYSTEM SID Type') {
            ($script:Redstone.ProfileList.Profiles | Where-Object { $_.Username -eq 'SYSTEM' }).SID | Should -BeOfType 'System.String'
        }

        It ('ProfileList Profiles SYSTEM SID') {
            ($script:Redstone.ProfileList.Profiles | Where-Object { $_.Username -eq 'SYSTEM' }).SID | Should -Be 'S-1-5-18'
        }

        It ('ProfileList Profiles SYSTEM Path') {
            ($script:Redstone.ProfileList.Profiles | Where-Object { $_.Username -eq 'SYSTEM' }).Path | Should -BeOfType 'System.IO.DirectoryInfo'
        }
    }

    Context ('GetSpecialFolders') {
        BeforeAll {
            $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
            . ('{0}\PSRedstone\Private\RedstoneClassAndEnums.ps1' -f $psProjectRoot.FullName)

            $script:publisher = 'MyPublisher'
            $script:product = 'MyProduct'
            $script:version = '1.2.3'
            $script:action = 'test'
            $script:Redstone = [Redstone]::new($script:publisher, $script:product, $script:version, $script:action)
        }

        It ('GetSpecialFolders') {
            $script:Redstone.GetSpecialFolders() | Should -Not -BeNullOrEmpty
        }

        It ('GetSpecialFolders Windows') {
            $script:Redstone.GetSpecialFolders().Windows | Should -Be $env:SystemRoot
        }

        It ('GetSpecialFolders Windows Type System.IO.DirectoryInfo') {
            $script:Redstone.GetSpecialFolders().Windows | Should -BeOfType 'System.IO.DirectoryInfo'
        }

        It ('GetSpecialFolders Windows Type System.IO.FileSystemInfo') {
            $script:Redstone.GetSpecialFolders().Windows | Should -BeOfType 'System.IO.FileSystemInfo' # DirectoryInfo base class is FileSystemInfo
        }

        It ('GetSpecialFolder Windows') {
            $script:Redstone.GetSpecialFolder('Windows') | Should -Be $env:SystemRoot
        }

        It ('GetSpecialFolder Windows Type System.IO.DirectoryInfo') {
            $script:Redstone.GetSpecialFolder('Windows') | Should -BeOfType 'System.IO.DirectoryInfo'
        }

        It ('GetSpecialFolder Windows Type System.IO.FileSystemInfo') {
            $script:Redstone.GetSpecialFolder('Windows') | Should -BeOfType 'System.IO.FileSystemInfo' # DirectoryInfo base class is FileSystemInfo
        }
    }

    Context ('Quit') {
        BeforeAll {
            $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
            . ('{0}\PSRedstone\Private\RedstoneClassAndEnums.ps1' -f $psProjectRoot.FullName)

            $script:publisher = 'MyPublisher'
            $script:product = 'MyProduct'
            $script:version = '1.2.3'
            $script:action = 'test'
            $script:Redstone = [Redstone]::new($script:publisher, $script:product, $script:version, $script:action)

            $script:Redstone.Debug.Quit = @{}
            $script:Redstone.Debug.Quit.DoNotExit = $true

            function _ScriptPrevLineNumber {
                return (($MyInvocation.ScriptLineNumber -as [int]) - 1)
            }
        }

        It ('Quit') {
            $script:Redstone.Quit()
            $script:Redstone.ExitCode | Should -Be 0
        }

        It ('Quit line_number') {
            $script:Redstone.Quit('line_number')
            $script:Redstone.ExitCode | Should -Be (_ScriptPrevLineNumber)
        }

        It ('Quit line_number ExitCodeAdd') {
            $script:Redstone.Quit('line_number', $true)
            $script:Redstone.ExitCode | Should -Be (55550000 + (_ScriptPrevLineNumber))
        }

        It ('Quit line_number ExitCodeAdd ExitCodeErrorBase') {
            $script:Redstone.Quit('line_number', $true, 12340000)
            $script:Redstone.ExitCode | Should -Be (12340000 + (_ScriptPrevLineNumber))
        }

        It ('Quit 1') {
            $script:Redstone.Quit(1)
            $script:Redstone.ExitCode | Should -Be 1
        }

        It ('Quit 1 ExitCodeAdd') {
            $script:Redstone.Quit(1, $true)
            $script:Redstone.ExitCode | Should -Be 55550001
        }

        It ('Quit 1 ExitCodeAdd ExitCodeErrorBase') {
            $script:Redstone.Quit(1, $true, 12340000)
            $script:Redstone.ExitCode | Should -Be 12340001
        }

        It ('Quit -1') {
            $script:Redstone.Quit(-1)
            $script:Redstone.ExitCode | Should -Be -1
        }

        It ('Quit -1 ExitCodeAdd') {
            $script:Redstone.Quit(-1, $true)
            $script:Redstone.ExitCode | Should -Be -55550001
        }

        It ('Quit -1 ExitCodeAdd ExitCodeErrorBase') {
            $script:Redstone.Quit(-1, $true, 12340000)
            $script:Redstone.ExitCode | Should -Be -12340001
        }

        It ('Quit 12345') {
            $script:Redstone.Quit(12345)
            $script:Redstone.ExitCode | Should -Be 12345
        }
    }
}
