$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
. "$here\$sut"

$global:WinstallStatic = @{}
$global:WinstallStatic.Log = @{}
$global:WinstallStatic.Log.PathF = 'C:\WINDOWS\Logs\Winstall\Rename-WinstallLogFile 2017 test{0}.log'
$global:WinstallStatic.Log.FileName = 'Rename-WinstallLogFile 2017 test.log'
$global:WinstallStatic.Log.Name = 'Rename-WinstallLogFile 2017 test'
$global:WinstallStatic.Log.Path = 'C:\WINDOWS\Logs\Winstall\Rename-WinstallLogFile 2017 test.log'
$global:WinstallStatic.Log.Folder = 'C:\WINDOWS\Logs\Winstall'


Describe $sut {
    $Mock = @{
        'CommandName' = 'Rename-Item';
        'MockWith' = { Write-Verbose "Not really doing anything ..." };
        'Verifiable' = $true;
        # 'ParameterFilter' = {
        #     # https://github.com/pester/Pester/issues/741
        #     ($Path -eq 'C:\WINDOWS\Logs\Winstall\Rename-WinstallLogFile 2017 test.log') `
        #     -and ($NewName -eq 'C:\WINDOWS\Logs\Winstall\Rename-WinstallLogFile 2017 test Foo.log')
        # };
    }
    Mock @Mock

    Context "Rename: ' Foo'" {

        $global:Winstall = @{}
        $global:Winstall.Log = $global:WinstallStatic.Log.Clone()

        Rename-WinstallLogFile -Formatter ' Foo'

        It 'Should Call Rename-Item' {
            Assert-MockCalled 'Rename-Item' -Exactly 1 -Scope 'Context'
        }

        It 'Winstall.Log.FileName' {
            $global:Winstall.Log.FileName | Should BeExactly 'Rename-WinstallLogFile 2017 test Foo.log'
        }

        It 'Winstall.Log.Folder' {
            $global:Winstall.Log.Folder | Should BeExactly $global:WinstallStatic.Log.Folder
        }

        It 'Winstall.Log.Name' {
            $global:Winstall.Log.Name | Should BeExactly 'Rename-WinstallLogFile 2017 test Foo'
        }

        It 'Winstall.Log.Path' {
            $global:Winstall.Log.Path | Should BeExactly 'C:\WINDOWS\Logs\Winstall\Rename-WinstallLogFile 2017 test Foo.log'
        }

        It 'Winstall.Log.PathF' {
            $global:Winstall.Log.PathF | Should BeExactly 'C:\WINDOWS\Logs\Winstall\Rename-WinstallLogFile 2017 test Foo{0}.log'
        }
    }
}