$script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
. ('{0}\PSRedstone\Public\Invoke-RedstoneElevateCurrentProcess.ps1' -f $psProjectRoot.FullName)

Describe 'Invoke-RedstoneElevateCurrentProcess' {
    BeforeAll {
        $script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
        . ('{0}\PSRedstone\Public\Invoke-RedstoneElevateCurrentProcess.ps1' -f $psProjectRoot.FullName)

        Mock Get-RedstoneTranslateErrorCode {
            param([int] $ErrorCode)
            return ([PSObject] @{
                ErrorCode = $ErrorCode
                Message = 'Pester Mock. (PESTERMOCK 0x{0:x})' -f $ErrorCode
            })
        }
    }

    Context 'Invoke-RedstoneElevateCurrentProcess Existant EXE' {


        BeforeAll {
            # Write-Host ('[Invoke-RedstoneElevateCurrentProcess Full Path][BeforeAll] Result: {0}' -f ($script:result | ConvertTo-Json)) -ForegroundColor Cyan
        }

        It '<File>: Returns IO.FileInfo' -TestCases $script:testCases {
            $Run | Should -BeOfType 'System.IO.FileInfo'
        }

        It '<File>: Exists' -TestCases $script:testCases {
            $Run.Exists | Should -Be $true
        }

        It '<File>: VersionInfo ProductVersion' -TestCases $script:testCases {
            $Run.VersionInfo.ProductVersion -as [version] | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Invoke-RedstoneElevateCurrentProcess Non-Existant EXE' {
        BeforeAll {
            $script:resultWarning = & {
                $script:result = Invoke-RedstoneElevateCurrentProcess ('fileDoesNotExist_{0}.exe' -f (New-Guid).Guid.Replace('-', '_'))
            } 3>&1
            # Write-Host ('[Invoke-RedstoneElevateCurrentProcess Full Path][BeforeAll] Result: {0}' -f ($script:result | ConvertTo-Json)) -ForegroundColor Cyan
        }

        It 'Returns IO.FileInfo' {
            $script:result | Should -BeOfType 'System.IO.FileInfo'
        }

        It 'Exists' {
            $script:result.Exists | Should -Be $false
        }

        It 'Warning' {
            $script:resultWarning | Should -BeOfType 'System.Management.Automation.WarningRecord'
        }
    }
}
