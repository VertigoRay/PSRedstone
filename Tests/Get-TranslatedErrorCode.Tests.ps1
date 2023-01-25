Describe 'Get-TranslatedErrorCode' {
    BeforeAll {
        $script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
        . ('{0}\PSRedstone\Public\Get-TranslatedErrorCode.ps1' -f $psProjectRoot.FullName)
    }

    Context 'Get-TranslatedErrorCode' {
        [System.Collections.ArrayList] $script:testCases = for ($i = 0; $i -le 1000; $i = $i + 500) {
            Write-Output @{
                ErrorCode = $i
            }
        }
        $script:testCases.Add(@{
            ErrorCode = -1073741728
        }) | Out-Null

        BeforeAll {
            # Write-Host ('[Get-TranslatedErrorCode Full Path][BeforeAll] Result: {0}' -f ($script:result | ConvertTo-Json)) -ForegroundColor Cyan
        }

        It '<ErrorCode>: Type' -TestCases $script:testCases {
            $result = Get-TranslatedErrorCode -ErrorCode $ErrorCode
            $result | Should -BeOfType 'PSObject'
        }

        It '<ErrorCode>: NativeErrorCode Type' -TestCases $script:testCases {
            $result = Get-TranslatedErrorCode -ErrorCode $ErrorCode
            $result.NativeErrorCode | Should -BeOfType 'System.Int32'
        }

        It '<ErrorCode>: NativeErrorCode' -TestCases $script:testCases {
            $result = Get-TranslatedErrorCode -ErrorCode $ErrorCode
            $result.NativeErrorCode | Should -Be $ErrorCode
        }

        It '<ErrorCode>: Message Type' -TestCases $script:testCases {
            $result = Get-TranslatedErrorCode -ErrorCode $ErrorCode
            $result.Message | Should -BeOfType 'System.String'
        }

        It '<ErrorCode>: Message' -TestCases $script:testCases {
            $result = Get-TranslatedErrorCode -ErrorCode $ErrorCode
            $result.Message | Should -Not -BeNullOrEmpty
        }
    }
}