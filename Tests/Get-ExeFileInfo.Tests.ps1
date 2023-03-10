Describe 'Get-ExeFileInfo' {
    BeforeAll {
        $script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
        . ('{0}\PSRedstone\Public\Get-ExeFileInfo.ps1' -f $psProjectRoot.FullName)
    }

    Context 'Get-ExeFileInfo Existant EXE' {
        $getRandomExe = {
            Get-ChildItem 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths' | Where-Object {
                -not (Get-Command $_.PSChildName -ErrorAction 'Ignore') -and ($_.PSChildName -as [IO.FileInfo])
            } | Select-Object -First 1 -ExpandProperty 'PSChildName'
        }
        $script:testCases = @(
            @{
                File = [IO.Path]::Combine($env:SystemRoot, 'notepad.exe')
                Run = { Get-ExeFileInfo ([IO.Path]::Combine($env:SystemRoot, 'notepad.exe')) }
            }
            @{
                File = 'notepad.exe'
                Run = { Get-ExeFileInfo 'notepad.exe' }
            }
            @{
                File = & $getRandomExe
                Run = [scriptblock]::Create(('$randomExe = {0}; {1}' -f @(
                    $getRandomExe.ToString()
                    ({ Get-ExeFileInfo $randomExe }).ToString()
                )))
            }
        )

        BeforeAll {
            # Write-Host ('[Get-ExeFileInfo Full Path][BeforeAll] Result: {0}' -f ($script:result | ConvertTo-Json)) -ForegroundColor Cyan
        }

        It 'Returns IO.FileInfo: <File>' -TestCases $script:testCases {
            $result = & $Run
            $result | Should -BeOfType 'System.IO.FileInfo'
        }

        It 'Exists: <File>' -TestCases $script:testCases {
            $result = & $Run
            $result.Exists | Should -Be $true
        }

        It 'VersionInfo ProductVersion: <File>' -TestCases $script:testCases {
            $result = & $Run
            $result.VersionInfo.ProductVersion -as [version] | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-ExeFileInfo Non-Existant EXE' {
        BeforeAll {
            $script:resultWarning = & {
                $script:result = Get-ExeFileInfo ('fileDoesNotExist_{0}.exe' -f (New-Guid).Guid.Replace('-', '_'))
            } 3>&1
            # Write-Host ('[Get-ExeFileInfo Full Path][BeforeAll] Result: {0}' -f ($script:result | ConvertTo-Json)) -ForegroundColor Cyan
        }

        It 'Returns IO.FileInfo' {
            $script:result | Should -BeOfType 'System.IO.FileInfo'
        }

        It 'Not Exists' {
            $script:result.Exists | Should -Be $false
        }

        It 'Warning' {
            $script:resultWarning | Should -BeOfType 'System.Management.Automation.WarningRecord'
        }
    }
}