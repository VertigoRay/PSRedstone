Describe 'Invoke-PesterDetect' {
    BeforeAll {
        $script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
        . ('{0}\PSRedstone\Public\Invoke-PesterDetect.ps1' -f $psProjectRoot.FullName)

        function Assert-Test {
            return (Get-Random @($true, $false))
        }
    }

    Context '<Name>' -ForEach @(
        @{
            Name = 'PrdMode'
            PPV = 'VertigoRay Assert-Test 1.2.3'
            SB  = {
                [CmdletBinding()]
                param(
                    [Parameter(Mandatory = $true)]
                    [string]
                    $FunctionName
                )

                Describe $FunctionName {
                    It 'Return Boolean' {
                        {
                            & $FunctionName | Should -BeOfType 'System.Boolean'
                        } | Should -Not -Throw
                    }
                }
            }
            Params = @{
                FunctionName = 'Assert-Test'
            }
            ParamsFail = @{
                FunctionName = 'Assert-TestDoesNotExist'
            }
        }
        @{
            Name = 'DevMode'
            PPV = 'VertigoRay Assert-Test 1.2.3'
            SB  = {
                [CmdletBinding()]
                param(
                    [Parameter(Mandatory = $true)]
                    [string]
                    $FunctionName
                )

                Describe $FunctionName {
                    It 'Return Boolean' {
                        {
                            & $FunctionName | Should -BeOfType 'System.Boolean'
                        } | Should -Not -Throw
                    }
                }
            }
            Params = @{
                FunctionName = 'Assert-Test'
            }
            ParamsFail = @{
                FunctionName = 'Assert-TestDoesNotExist'
            }
        }
    ) {
        It 'Should Pass' {
            $pesterDetect = @{
                PesterScriptBlock = $SB
                PesterScriptBlockParam = $Params
                PublisherProductVersion = $PPV
                DevMode = if ($Name = 'DevMode') { $true } else { $false }
            }

            {
                Invoke-PesterDetect @pesterDetect 3>$null 6>$null | Should -Be 'Detection SUCCESSFUL: VertigoRay Assert-Test 1.2.3'
            } | Should -Not -Throw
        }

        It 'Should Fail' {
            $pesterDetect = @{
                PesterScriptBlock = $SB
                PesterScriptBlockParam = $ParamsFail
                PublisherProductVersion = $PPV
                DevMode = if ($Name = 'DevMode') { $true } else { $false }
            }

            {
                Invoke-PesterDetect @pesterDetect 3>$null 6>$null | Should -BeNullOrEmpty
            } | Should -Not -Throw
        }
    }
}