#Requires -RunAsAdministrator

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

$PSDefaultParameterValues.Set_Item('Assert-ConflictingProcessRunning:Product', 'PesterTest')
$PSDefaultParameterValues.Set_Item('Assert-ConflictingProcessRunning:PopupAfterNumErrors', 0)
$PSDefaultParameterValues.Set_Item('Assert-ConflictingProcessRunning:PopupText', @(
    "{0}'s install process requires the following {1} be closed before the install may continue. Please close {2} and click Retry.",
    "{3}",
    "You can monitor the status of this install under the Installation Status section of Software Center. This message box will automatically close after {4} minutes; cancelling the install process."
))
$PSDefaultParameterValues.Set_Item('Assert-ConflictingProcessRunning:PopupText_f', @'
@(
    $Product,
    $(if (($process | select -Unique | Measure-Object).Count -gt 1) {'applications'} else {'application'}),
    $(if (($process | select -Unique | Measure-Object).Count -gt 1) {'these applications'} else {'this application'}),
    $(($process | Select UserName,ProcessName -Unique | %{ "`n`t{0}`t(User: {1})" -f ($_.ProcessName).ToUpper(),$_.UserName })),
    $(if (($PopupSecondsToWait % 60) -eq 0) {"$([int]($PopupSecondsToWait / 60))"} else {"$([int]($PopupSecondsToWait/60)).$($PopupSecondsToWait%60)"})
)
'@)
$PSDefaultParameterValues.Set_Item('Assert-ConflictingProcessRunning:PopupSecondsToWait', 300)
$PSDefaultParameterValues.Set_Item('Assert-ConflictingProcessRunning:MaxLoop', 10)
$PSDefaultParameterValues.Set_Item('Assert-ConflictingProcessRunning:PrivateVarsPath', 'HKLM:\SOFTWARE\Winstall\PrivateVars')

function Invoke-Popup {
    param (
        [string]    $Title,
        [string]    $Text,
        [string]    $ButtonType,
        [string]    $IconType,
        [int]       $SecondsToWait,
        [boolean]   $SystemModal
    )

    return $true
}



Describe $sut {
    Mock Remove-ItemProperty {}
    Mock Set-ItemProperty {}


    Context 'Test `Invoke-Popup` with only retry.' {
        Mock Invoke-Popup { return 4 }

        It 'Should create popup maximum times; then throw' {
            { Assert-ConflictingProcessRunning 'PowerShell' } | Should Throw "Maximum Loop threshold exceeded."
        }

        It 'Confirm `Invoke-Popup` called maximum times' {
            Assert-MockCalled 'Invoke-Popup' -Exactly 11
        }
    }

    Context 'Test `Invoke-Popup` with only cancel.' {
        Mock Invoke-Popup { return 2 }

        It 'Should create popup; cancel button causes throw' {
            { Assert-ConflictingProcessRunning 'PowerShell' } | Should Throw "Cancel Button (or X) Clicked."
        }

        It 'Confirm `Invoke-Popup` called maximum times' {
            Assert-MockCalled 'Invoke-Popup' -Exactly 1
        }
    }

    Context 'Test `Invoke-Popup` with popup timeout.' {
        Mock Invoke-Popup { return -1 }

        It 'Should create popup; timeout button causes throw' {
            { Assert-ConflictingProcessRunning 'PowerShell' } | Should Throw "Window TimeOut."
        }

        It 'Confirm `Invoke-Popup` called maximum times' {
            Assert-MockCalled 'Invoke-Popup' -Exactly 1
        }
    }

    Context 'Test `Invoke-Popup` with process that doesn''t exist.' {
        Mock Invoke-Popup { return 4 }

        It 'Should not create popup; no popup' {
            { Assert-ConflictingProcessRunning "ProcessShouldNeverExist_$(New-Guid)" } | Should Not Throw
        }

        It 'Confirm `Invoke-Popup` called 0 times' {
            Assert-MockCalled 'Invoke-Popup' -Exactly 0
        }
    }
}
