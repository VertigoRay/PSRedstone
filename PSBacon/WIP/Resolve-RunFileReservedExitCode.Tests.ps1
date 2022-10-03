$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

Describe $sut {
    Context 'Conflicting Processes' {
        It 'A conflicting process is running. No prompt was issued to user.' {
            Resolve-RunFileReservedExitCode "PrivateVar (ThisIsJustATest_ConflictingProcessPopupDisable) detected: 1" | Should Be 9999
        }

        It 'A conflicting process is running. User was prompted and opted to cancel the install.' {
            Resolve-RunFileReservedExitCode "Cancel Button (or X) Clicked." | Should Be 9998
        }

        It 'A conflicting process is running. User was prompted but window timeout occurred.' {
            Resolve-RunFileReservedExitCode "Window TimeOut." | Should Be 9997
        }
    }

    Context 'Misc' {
        It 'Everything Else' {
            Resolve-RunFileReservedExitCode (New-Guid) | Should Be 'line_number'
        }
    }
}
