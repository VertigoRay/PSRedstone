#Requires -RunAsAdministrator
<#
.SYNOPSIS

    Determine if a process is running. If so, take action.

.DESCRIPTION

    Determine if a process is running. If so, there are several customizable actions:

    1. Throw an error. This should be handled in the RunFile.
    2. Keep a Count of Failures, take customized action after set number of failures.
    3. Optionally create a pop-up message for the user.
        - Depending on user action, throw an error if process is cancelled.

    Nothing is returned. This function throws an error if there's an error. Otherwise, it returns nothing an you assume it's successful.

.PARAMETER Processes

    Required.

    Specifies one or more processes by process name. You can type multiple process names (separated by commas) and use wildcard characters.

.PARAMETER Product

    Optional. Default: $global:Winstall.Parameters.Product

    This is the name of the Product being installed. This is used in a few places by default:

    - In the `PopupText_f` parameter, to describe the Product being installed.
    - In the Popup Title parameter, to describe the Product being installed.
    - To automatically generate a [PrivateVar](https://git.cas.unt.edu/winstall/winstall/wikis/privatevars) name for completely disabling popup messages. All non-alphanumeric characters will be removed and `_ConflictingProcessPopupDisable` will be appended.
        - For Example: `Atom` will use the following PrivateVar: `Atom_ConflictingProcessPopupDisable`
        - For Example: `mozilla-firefox-esr` will use the following PrivateVar: `mozillafirefoxesr_ConflictingProcessPopupDisable`
        - For Example: `7-zip` will use the following PrivateVar: `7zip_ConflictingProcessPopupDisable`
    - To automatically generate a [PrivateVar](https://git.cas.unt.edu/winstall/winstall/wikis/privatevars) name for keeping track of the number of errors. This PrivateVar is used internally and **should not be set via GPO**. All non-alphanumeric characters will be removed and `_ConflictingProcessErrorCount` will be appended.
        - For Example: `Atom` will use the following PrivateVar: `Atom_ConflictingProcessErrorCount`
        - For Example: `mozilla-firefox-esr` will use the following PrivateVar: `mozillafirefoxesr_ConflictingProcessErrorCount`
        - For Example: `7-zip` will use the following PrivateVar: `7zip_ConflictingProcessErrorCount`

.PARAMETER PopupAfterNumErrors

    Optional. Default: $global:Winstall.Settings.AssertProcessRunning.PopupAfterNumErrors

    Default Value (Set in `Initialize-Winstall`): 0

    If set to `0` will always popup. Otherwise, will wait until number of failures reaches this threshold.

.PARAMETER PopupText

    Optional. Default: $global:Winstall.Settings.AssertProcessRunning.PopupText

    Default Value (Set in `Initialize-Winstall`) `[string[]]`:

    ```powershell
    @(
        "{0}'s install process requires the following {1} be closed before the install may continue. Please close {2} and click Retry.",
        "{3}",
        "You can monitor the status of this install under the Installation Status section of Software Center. This message box will automatically close after {4} minutes; cancelling the install process."
    )
    ```

    This array will have each item joined by a new line. Then, formatted (`-f`) with the `PopupText_f` parameter.

.PARAMETER PopupText_f

    Optional. Default: $global:Winstall.Settings.AssertProcessRunning.PopupText_f

    Default Value (Set in `Initialize-Winstall`) `[string]`:

    ```powershell
    @'
    @(
        $Product,
        $(if (($process | select -Unique | Measure-Object).Count -gt 1) {'applications'} else {'application'}),
        $(if (($process | select -Unique | Measure-Object).Count -gt 1) {'these applications'} else {'this application'}),
        $(($process | Select UserName,ProcessName -Unique | %{ "`n`t{0}`t(User: {1})" -f ($_.ProcessName).ToUpper(),$_.UserName })),
        $(if (($PopupSecondsToWait % 60) -eq 0) {"$([int]($PopupSecondsToWait / 60))"} else {"$([int]($PopupSecondsToWait/60)).$($PopupSecondsToWait%60)"})
    )
    '@
    ```

    This is the formatter (`-f`) used with the `PopupText` parameter.

.PARAMETER PopupSecondsToWait

    Optional. Default: $global:Winstall.Settings.AssertProcessRunning.PopupSecondsToWait

    Default Value (Set in `Initialize-Winstall`): 300

    Sets the `Invoke-Popup` *SecondsToWait* Parameter

.PARAMETER MaxLoop

    Optional. Default: $global:Winstall.Settings.AssertProcessRunning.MaxLoop

    Default Value (Set in `Initialize-Winstall`): 100

    Sets the `Invoke-Popup` *SecondsToWait* Parameter

.OUTPUTS

    Nothing is outputted. This function either throws an error or doesn't.

.EXAMPLE

    # Simple usage in a RunFile
    Write-Progress -CurrentOperation "Checking if $($settings.ConflictingProcesses) is/are currently running ..."

    try {
        Assert-ConflictingProcessRunning $settings.ConflictingProcesses
    } catch {
        Write-Error (Resolve-Error $_)
        &$global:Winstall.Exit (Resolve-RunFileReservedExitCode $_.Exception.Message)
    }

.EXAMPLE

    # Usage in a RunFile; More Parameters
    Write-Progress -CurrentOperation "Checking if $($settings.ConflictingProcesses) is/are currently running ..."

    $Assert_ConflictingProcessRunning = @{
        'Processes' = $settings.ConflictingProcesses;
        'Product' = 'PesterTest';
    }

    try {
        Assert-ConflictingProcessRunning @Assert_ConfictingProcessRunning
    } catch {
        Write-Error (Resolve-Error $_)
        &$global:Winstall.Exit (Resolve-RunFileReservedExitCode $_.Exception.Message)
    }

.EXAMPLE

    # Usage in a RunFile; Parameters with PrivateVar Overrides
    Write-Progress -CurrentOperation "Checking if $($settings.ConflictingProcesses) is/are currently running ..."

    $Assert_ConflictingProcessRunning = @{
        'Processes' = $settings.ConflictingProcesses;
        'Product' = 'PesterTest';
    }
    if ($global:Winstall.PrivateVars.PesterTestPopupAfterNumErrors) {
        $Assert_ConflictingProcessRunning.Add('PopupAfterNumErrors', $global:Winstall.PrivateVars.PesterTestPopupAfterNumErrors)
    }
    if ($global:Winstall.PrivateVars.PesterTestPopupSecondsToWait) {
        $Assert_ConflictingProcessRunning.Add('PopupSecondsToWait', $global:Winstall.PrivateVars.PesterTestPopupSecondsToWait)
    }

    try {
        Assert-ConflictingProcessRunning @Assert_ConflictingProcessRunning
    } catch {
        Write-Error (Resolve-Error $_)
        &$global:Winstall.Exit 'line_number'
    }

.NOTES

    There are a lot of ways that this can be made even more modular. However, we currently don't have a use for more modularity. We can always patch this as needed.

#>
function Assert-ConflictingProcessRunning {
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of process(es) to assert")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Processes
        ,
        [string]
        $Product = $global:Winstall.Parameters.Product
        ,
        [ValidateRange(0, [int]::MaxValue)]
        [int]
        $PopupAfterNumErrors = $global:Winstall.Settings.Functions.AssertProcessRunning.PopupAfterNumErrors
        ,
        [string[]]
        $PopupText = $global:Winstall.Settings.Functions.AssertProcessRunning.PopupText
        ,
        [string]
        $PopupText_f = $global:Winstall.Settings.Functions.AssertProcessRunning.PopupText_f
        ,
        [int]
        $PopupSecondsToWait = $global:Winstall.Settings.Functions.AssertProcessRunning.PopupSecondsToWait
        ,
        [int]
        $MaxLoop = $global:Winstall.Settings.Functions.AssertProcessRunning.MaxLoop
        ,
        [string]
        $PrivateVarsPath = $global:Winstall.PrivateVars.Paths.Product
    )

    Write-Information "> $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Debug "Function Invocation: $($MyInvocation | Out-String)"


    $ConflictingProcessPopupDisable = "$($Product -replace '[^A-Za-z0-9]', '')_ConflictingProcessPopupDisable" # Deprecated
    $ConflictingProcessErrorCount = "$($Product -replace '[^A-Za-z0-9]', '')_ConflictingProcessErrorCount" # Deprecated

    $intConflictingProcessPopupDisable = if ($global:Winstall.PrivateVars.ConflictingProcessPopupDisable) { $global:Winstall.PrivateVars.ConflictingProcessPopupDisable } else {$global:Winstall.PrivateVars.$ConflictingProcessPopupDisable}
    $intConflictingProcessErrorCount = if ($global:Winstall.PrivateVars.ConflictingProcessErrorCount) { $global:Winstall.PrivateVars.ConflictingProcessErrorCount } else {$global:Winstall.PrivateVars.$ConflictingProcessErrorCount}

    $i = 1
    while ($process = Get-Process $Processes -IncludeUserName -ErrorAction 'Ignore') {
          Write-Information "Conflicting process is running: $($process | Out-String)"
          Write-Warning "Conflicting process is running! To prevent loss of work, we will not install $($settings.Product) while one of these processes is running." -ErrorAction 'Continue'

          Write-Information "Determining how to proceed ..."

          Write-Information "Checking for PrivateVar ($ConflictingProcessPopupDisable) ..."
          if ($global:Winstall.PrivateVars.$ConflictingProcessPopupDisable -or $global:Winstall.PrivateVars.ConflictingProcessPopupDisable) {
              Throw [System.Exception] "PrivateVar ($ConflictingProcessPopupDisable) detected: $($global:Winstall.PrivateVars.$ConflictingProcessPopupDisable)"
          }
          Write-Information "PrivateVar ($ConflictingProcessPopupDisable) not detected."

          Write-Information "Checking if Conflicting Process Error Count ($intConflictingProcessErrorCount) has reached its threshold (${PopupAfterNumErrors})."
          if ($PopupAfterNumErrors -eq 0) {
              Write-Information "Threshold (${PopupAfterNumErrors}) is zero. Moving on ..."
          } elseif ($intConflictingProcessErrorCount -lt $PopupAfterNumErrors) {
              Set-ItemProperty -Path $global:Winstall.PrivateVars.Path -Name $ConflictingProcessErrorCount -Value ($global:Winstall.PrivateVars.$ConflictingProcessErrorCount + 1)
              Throw [System.Exception] "Conflicting Process Error Count (${intConflictingProcessErrorCount}) has not reached the limit (${PopupAfterNumErrors})."
          } else {
              Write-Information "Conflicting Process Error Count (${intConflictingProcessErrorCount}) has reached its threshold (${PopupAfterNumErrors})."
          }

          $Invoke_Popup = @{
              'Title' = "[Winstall] ${Product}: Conflicting Processes";
              'Text' = ($PopupText -join [Environment]::NewLine) -f (Invoke-Expression $PopupText_f);
              'ButtonType' = 'RetryCancel';
              'IconType' = 'Question';
              'SecondsToWait' = $PopupSecondsToWait;
              'SystemModal' = $true
          }
          $response = Invoke-Popup @Invoke_Popup
          if ($response -eq -1) {
              # Window TimeOut
              Throw [System.Exception] "Window TimeOut."
          } elseif ($response -eq 2) {
              # Cancel Button (or X) Clicked
              Throw [System.Exception] "Cancel Button (or X) Clicked."
          } elseif ($response -eq 4) {
              # Retry Button Clicked
          } else {
              Throw [System.Exception] "Unexpected Response: ${response}"
          }

          if ($i -gt $MaxLoop) {
              Throw [System.Exception] "Maximum Loop threshold exceeded."
          } else {
              $i++
              continue
          }
      }

      Remove-ItemProperty -Path $PrivateVarsPath -Name $ConflictingProcessErrorCount -ErrorAction 'Ignore'
      Write-Information "$($Processes -join ', ') is/are *not* currently running."
}
