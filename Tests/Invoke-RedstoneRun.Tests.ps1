$script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
. ('{0}\PSRedstone\Public\Invoke-RedstoneRun.ps1' -f $psProjectRoot.FullName)

Describe 'Invoke-RedstoneRun' {
    BeforeAll {
        $script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
        . ('{0}\PSRedstone\Public\Invoke-RedstoneRun.ps1' -f $psProjectRoot.FullName)
    }

    Context 'Invoke-RedstoneRun File Does Not Exist' {
        It 'Should Throw' {
            $randomExe = 'fileDoesNotExist_{0}.exe' -f (New-Guid).Guid.Replace('-','_')
            { Invoke-RedstoneRun $randomExe } | Should -Throw
        }
    }

    Context 'Invoke-RedstoneRun Invalid Cmd' {
        It 'Should Throw' {
            { Invoke-RedstoneRun 'Invalid ' } | Should -Throw
        }
    }

    Context 'Invoke-RedstoneRun Simple Cmd StdOut' {
        BeforeAll {
            $script:result = Invoke-RedstoneRun 'hostname'
            # Write-Host ('[Invoke-RedstoneRun Simple Cmd StdOut][BeforeAll] Result: {0}' -f ($script:result | ConvertTo-Json)) -ForegroundColor Cyan
        }

        It 'Creates Result System.Collections.Hashtable' {
            $script:result | Should -BeOfType 'System.Collections.Hashtable'
        }

        It 'Creates Result.Process System.Diagnostics.Process' {
            $script:result.Process | Should -BeOfType 'System.Diagnostics.Process'
        }

        It 'Creates Result.Process.ExitCode System.Int32' {
            $script:result.Process.ExitCode | Should -BeOfType 'System.Int32'
        }

        It 'Creates Result.Process.ExitCode 0' {
            $script:result.Process.ExitCode | Should -Be 0
        }

        It 'Creates Result.StdOut System.String' {
            $script:result.StdOut | Should -BeOfType 'System.String'
        }

        It 'Creates Result.StdOut Hostname' {
            $script:result.StdOut | Should -Contain $(hostname)
        }

        It 'Creates Result.StdErr System.String' {
            $script:result.StdErr | Should -BeOfType 'System.String'
        }

        It 'Creates Result.StdErr Empty' {
            $script:result.StdErr | Should -BeNullOrEmpty
        }
    }

    Context 'Invoke-RedstoneRun Simple w Quotes Cmd StdOut' {
        BeforeAll {
            $script:result = Invoke-RedstoneRun '"hostname.exe"'
            # Write-Host ('[Invoke-RedstoneRun Simple Cmd StdOut][BeforeAll] Result: {0}' -f ($script:result | ConvertTo-Json)) -ForegroundColor Cyan
        }

        It 'Creates Result System.Collections.Hashtable' {
            $script:result | Should -BeOfType 'System.Collections.Hashtable'
        }

        It 'Creates Result.Process System.Diagnostics.Process' {
            $script:result.Process | Should -BeOfType 'System.Diagnostics.Process'
        }

        It 'Creates Result.Process.ExitCode System.Int32' {
            $script:result.Process.ExitCode | Should -BeOfType 'System.Int32'
        }

        It 'Creates Result.Process.ExitCode 0' {
            $script:result.Process.ExitCode | Should -Be 0
        }

        It 'Creates Result.StdOut System.String' {
            $script:result.StdOut | Should -BeOfType 'System.String'
        }

        It 'Creates Result.StdOut Hostname' {
            $script:result.StdOut | Should -Contain $(hostname)
        }

        It 'Creates Result.StdErr System.String' {
            $script:result.StdErr | Should -BeOfType 'System.String'
        }

        It 'Creates Result.StdErr Empty' {
            $script:result.StdErr | Should -BeNullOrEmpty
        }
    }

    Context 'Invoke-RedstoneRun Simple Cmd StdErr' {
        BeforeAll {
            $script:result = Invoke-RedstoneRun 'hostname /////'
            # Write-Host ('[Invoke-RedstoneRun Simple Cmd StdErr][BeforeAll] Result: {0}' -f ($script:result | ConvertTo-Json)) -ForegroundColor Cyan
        }

        It 'Creates Result System.Collections.Hashtable' {
            $script:result | Should -BeOfType 'System.Collections.Hashtable'
        }

        It 'Creates Result.Process System.Diagnostics.Process' {
            $script:result.Process | Should -BeOfType 'System.Diagnostics.Process'
        }

        It 'Creates Result.Process.ExitCode System.Int32' {
            $script:result.Process.ExitCode | Should -BeOfType 'System.Int32'
        }

        It 'Creates Result.Process.ExitCode 1' {
            $script:result.Process.ExitCode | Should -Be 1
        }

        It 'Creates Result.StdOut System.String' {
            $script:result.StdOut | Should -BeOfType 'System.String'
        }

        It 'Creates Result.StdOut Hostname' {
            $script:result.StdOut | Should -BeNullOrEmpty
        }

        It 'Creates Result.StdErr System.String' {
            $script:result.StdErr | Should -BeOfType 'System.String'
        }

        It 'Creates Result.StdErr Empty' {
            $script:result.StdErr | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Invoke-RedstoneRun Complex Cmd StdOut' {
        BeforeAll {
            $script:result = Invoke-RedstoneRun '"ipconfig" /all'
            # Write-Host ('[Invoke-RedstoneRun Simple Cmd StdOut][BeforeAll] Result: {0}' -f ($script:result | ConvertTo-Json)) -ForegroundColor Cyan
        }

        It 'Creates Result System.Collections.Hashtable' {
            $script:result | Should -BeOfType 'System.Collections.Hashtable'
        }

        It 'Creates Result.Process System.Diagnostics.Process' {
            $script:result.Process | Should -BeOfType 'System.Diagnostics.Process'
        }

        It 'Creates Result.Process.ExitCode System.Int32' {
            $script:result.Process.ExitCode | Should -BeOfType 'System.Int32'
        }

        It 'Creates Result.Process.ExitCode 0' {
            $script:result.Process.ExitCode | Should -Be 0
        }

        It 'Creates Result.StdOut System.String' {
            $script:result.StdOut | Should -BeOfType 'System.String'
        }

        It 'Creates Result.StdOut "Windows IP Configuration"' {
            $script:result.StdOut | Should -Contain 'Windows IP Configuration'
        }

        It 'Creates Result.StdErr System.String' {
            $script:result.StdErr | Should -BeOfType 'System.String'
        }

        It 'Creates Result.StdErr Empty' {
            $script:result.StdErr | Should -BeNullOrEmpty
        }
    }

    Context 'Invoke-RedstoneRun Simple Cmd StdErr' {
        BeforeAll {
            $script:result = Invoke-RedstoneRun '"ipconfig" /alllllllllll'
            # Write-Host ('[Invoke-RedstoneRun Simple Cmd StdErr][BeforeAll] Result: {0}' -f ($script:result | ConvertTo-Json)) -ForegroundColor Cyan
        }

        It 'Creates Result System.Collections.Hashtable' {
            $script:result | Should -BeOfType 'System.Collections.Hashtable'
        }

        It 'Creates Result.Process System.Diagnostics.Process' {
            $script:result.Process | Should -BeOfType 'System.Diagnostics.Process'
        }

        It 'Creates Result.Process.ExitCode System.Int32' {
            $script:result.Process.ExitCode | Should -BeOfType 'System.Int32'
        }

        It 'Creates Result.Process.ExitCode 1' {
            $script:result.Process.ExitCode | Should -Be 1
        }

        It 'Creates Result.StdOut System.String' {
            $script:result.StdOut | Should -BeOfType 'System.String'
        }

        It 'Creates Result.StdOut "Error: unrecognized or incomplete command line."' {
            $script:result.StdOut | Should -Contain 'Error: unrecognized or incomplete command line.'
        }

        It 'Creates Result.StdErr System.String' {
            $script:result.StdErr | Should -BeOfType 'System.String'
        }

        It 'Creates Result.StdErr Empty' {
            $script:result.StdErr | Should -BeNullOrEmpty
        }
    }

    Context 'Invoke-RedstoneRun Simple FilePath StdOut' {
        BeforeAll {
            $script:result = Invoke-RedstoneRun -FilePath 'hostname'
            # Write-Host ('[Invoke-RedstoneRun Simple Cmd StdOut][BeforeAll] Result: {0}' -f ($script:result | ConvertTo-Json)) -ForegroundColor Cyan
        }

        It 'Creates Result System.Collections.Hashtable' {
            $script:result | Should -BeOfType 'System.Collections.Hashtable'
        }

        It 'Creates Result.Process System.Diagnostics.Process' {
            $script:result.Process | Should -BeOfType 'System.Diagnostics.Process'
        }

        It 'Creates Result.Process.ExitCode System.Int32' {
            $script:result.Process.ExitCode | Should -BeOfType 'System.Int32'
        }

        It 'Creates Result.Process.ExitCode 0' {
            $script:result.Process.ExitCode | Should -Be 0
        }

        It 'Creates Result.StdOut System.String' {
            $script:result.StdOut | Should -BeOfType 'System.String'
        }

        It 'Creates Result.StdOut Hostname' {
            $script:result.StdOut | Should -Contain $(hostname)
        }

        It 'Creates Result.StdErr System.String' {
            $script:result.StdErr | Should -BeOfType 'System.String'
        }

        It 'Creates Result.StdErr Empty' {
            $script:result.StdErr | Should -BeNullOrEmpty
        }
    }

    Context 'Invoke-RedstoneRun Simple FilePath and Argument List' {
        BeforeAll {
            $script:result = Invoke-RedstoneRun -FilePath 'ipconfig' -ArgumentList '/all'
            # Write-Host ('[Invoke-RedstoneRun Simple Cmd StdOut][BeforeAll] Result: {0}' -f ($script:result | ConvertTo-Json)) -ForegroundColor Cyan
        }

        It 'Creates Result System.Collections.Hashtable' {
            $script:result | Should -BeOfType 'System.Collections.Hashtable'
        }

        It 'Creates Result.Process System.Diagnostics.Process' {
            $script:result.Process | Should -BeOfType 'System.Diagnostics.Process'
        }

        It 'Creates Result.Process.ExitCode System.Int32' {
            $script:result.Process.ExitCode | Should -BeOfType 'System.Int32'
        }

        It 'Creates Result.Process.ExitCode 0' {
            $script:result.Process.ExitCode | Should -Be 0
        }

        It 'Creates Result.StdOut System.String' {
            $script:result.StdOut | Should -BeOfType 'System.String'
        }

        It 'Creates Result.StdOut "Windows IP Configuration"' {
            $script:result.StdOut | Should -Contain 'Windows IP Configuration'
        }

        It 'Creates Result.StdErr System.String' {
            $script:result.StdErr | Should -BeOfType 'System.String'
        }

        It 'Creates Result.StdErr Empty' {
            $script:result.StdErr | Should -BeNullOrEmpty
        }
    }

    Context 'Simple WorkingDirectory' {
        BeforeAll {
            [IO.FileInfo] $script:randomExe = 'C:\Program Files\DoesNotExist\fileDoesNotExist_{0}.exe' -f (New-Guid).Guid.Replace('-','_')
        }

        BeforeEach {
            Mock Start-Process { param($FilePath, $WorkingDirectory) return $WorkingDirectory }
        }

        It 'Should Not Pass WorkingDirectory' {
            (Invoke-RedstoneRun -FilePath $script:randomExe.Name).Process | Should -BeNullOrEmpty
        }

        It 'Should Pass WorkingDirectory' {
            (Invoke-RedstoneRun -FilePath $script:randomExe.FullName -WorkingDirectory $script:randomExe.DirectoryName).Process | Should -Be 'C:\Program Files\DoesNotExist'
        }
    }
}