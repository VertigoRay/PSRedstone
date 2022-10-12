$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"



$PSDefaultParameterValues.Set_Item('Invoke-Run:PassThru', $true)
$PSDefaultParameterValues.Set_Item('Invoke-Run:Wait', $true)
$PSDefaultParameterValues.Set_Item('Invoke-Run:WindowStyle', 'Hidden')

$invokes = @(
    @{
        'Title' = "Cmd: Odd Quotes";
        'Cmd' = """Setup.exe"" /INI=""setup.ini""";
        'FilePath' = 'Setup.exe';
        'ArgumentList' = @("/INI=""setup.ini""");
    },
    @{
        'Title' = "FilePath: ArgumentList as array";
        'FilePath' = 'Setup.exe';
        'ArgumentList' = @("/INI=""setup.ini""");
    }
)

$temp_dir = "${env:Temp}\$(New-Guid)"
$ParameterFilter_FilePath_ArgumentList = { ($FilePath -eq $invoke.FilePath) -and ($ArgumentList -eq $invoke.ArgumentList) }
$ParameterFilter_FilePath_ArgumentList_WorkingDir = { ($FilePath -eq $invoke.FilePath) -and ($ArgumentList -eq $invoke.ArgumentList) -and ($WorkingDirectory -eq $temp_dir)}
$ParameterFilter_FilePath_ArgumentList_WorkingDir_PassThru = { ($FilePath -eq $invoke.FilePath) -and ($ArgumentList -eq $invoke.ArgumentList) -and ($WorkingDirectory -eq $temp_dir) -and ($PassThru -eq $false)}
$ParameterFilter_FilePath_ArgumentList_WorkingDir_PassThru_Wait = { ($FilePath -eq $invoke.FilePath) -and ($ArgumentList -eq $invoke.ArgumentList) -and ($WorkingDirectory -eq $temp_dir) -and ($PassThru -eq $false) -and ($Wait -eq $false)}
$ParameterFilter_FilePath_ArgumentList_WorkingDir_PassThru_Wait_WindowStyle = { ($FilePath -eq $invoke.FilePath) -and ($ArgumentList -eq $invoke.ArgumentList) -and ($WorkingDirectory -eq $temp_dir) -and ($PassThru -eq $false) -and ($Wait -eq $false) -and ($WindowStyle -eq 'Minimized')}

$MockWiths = @{
    'Success' = { Write-Verbose "Not really doing anything"; return @{'ExitCode' = 0} };
    'Failure' = { Write-Verbose "Not really doing anything"; return @{'ExitCode' = 1} };
}

Describe $sut {
    foreach ($invoke in $invokes) {
        foreach ($MockWith in $MockWiths.GetEnumerator()) {
            $Mock = @{
                'CommandName' = 'Start-Process';
                'MockWith' = $MockWith.Value;
                'Verifiable' = $true;
            }
            Mock @Mock
            $Mock.Remove('ParameterFilter')
            Mock @Mock

            if ($invoke.Cmd) {
                $invoke_run = @{
                    'Cmd' = $invoke.Cmd;
                }
            } else {
                $invoke_run = @{
                    'FilePath' = $invoke.FilePath;
                    'ArgumentList' = $invoke.ArgumentList;
                }
            }

            if ($invoke.WorkingDirectory) {
                $invoke_run.Add('WorkingDirectory', $invoke.WorkingDirectory)
            }
            if ($invoke.PassThru) {
                $invoke_run.Add('PassThru', $invoke.PassThru)
            }
            if ($invoke.Wait) {
                $invoke_run.Add('Wait', $invoke.Wait)
            }
            if ($invoke.WindowStyle) {
                $invoke_run.Add('WindowStyle', $invoke.WindowStyle)
            }


            Context ('{0} : {1}' -f $invoke.Title, $MockWith.Name) {
                $result = Invoke-Run @invoke_run

                It "Test ExitCode" {
                    if ($MockWith.Name -eq 'Success') {
                        $result.Process.ExitCode | Should Be 0
                    } else {
                        $result.Process.ExitCode | Should Be 1
                    }
                }

                It "Start-Process validation" {
                    Assert-MockCalled 'Start-Process' -Exactly 1 -Scope 'Context' -ParameterFilter $ParameterFilter_FilePath_ArgumentList
                }


                $invoke_run.Set_Item('WorkingDirectory', $temp_dir)
                $result = Invoke-Run @invoke_run

                It "WorkingDirectory ExitCode" {
                    if ($MockWith.Name -eq 'Success') {
                        $result.Process.ExitCode | Should Be 0
                    } else {
                        $result.Process.ExitCode | Should Be 1
                    }
                }

                It "WorkingDirectory" {
                    Assert-MockCalled 'Start-Process' -Exactly 1 -Scope 'Context' -ParameterFilter $ParameterFilter_FilePath_ArgumentList_WorkingDir
                }


                $invoke_run.Set_Item('PassThru', $false)
                $result = Invoke-Run @invoke_run

                It "PassThru ExitCode" {
                    if ($MockWith.Name -eq 'Success') {
                        $result.Process.ExitCode | Should Be 0
                    } else {
                        $result.Process.ExitCode | Should Be 1
                    }
                }

                It "PassThru" {
                    Assert-MockCalled 'Start-Process' -Exactly 1 -Scope 'Context' -ParameterFilter $ParameterFilter_FilePath_ArgumentList_WorkingDir_PassThru
                }


                $invoke_run.Set_Item('Wait', $false)
                $result = Invoke-Run @invoke_run

                It "Wait ExitCode" {
                    if ($MockWith.Name -eq 'Success') {
                        $result.Process.ExitCode | Should Be 0
                    } else {
                        $result.Process.ExitCode | Should Be 1
                    }
                }

                It "Wait" {
                    Assert-MockCalled 'Start-Process' -Exactly 1 -Scope 'Context' -ParameterFilter $ParameterFilter_FilePath_ArgumentList_WorkingDir_PassThru_Wait
                }


                $invoke_run.Set_Item('WindowStyle', 'Minimized')
                $result = Invoke-Run @invoke_run

                It "WindowStyle ExitCode" {
                    if ($MockWith.Name -eq 'Success') {
                        $result.Process.ExitCode | Should Be 0
                    } else {
                        $result.Process.ExitCode | Should Be 1
                    }
                }

                It "WindowStyle" {
                    Assert-MockCalled 'Start-Process' -Exactly 1 -Scope 'Context' -ParameterFilter $ParameterFilter_FilePath_ArgumentList_WorkingDir_PassThru_Wait_WindowStyle
                }
            }
        }
    }
}
