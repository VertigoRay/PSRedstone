<#
.SYNOPSIS
Block the execution of an application(s)
.DESCRIPTION
T
.PARAMETER ProcessNames
These are the executables names to be blocked.

- All ProcessNames are converted to lowercase.
- If the ProcessName does not end with `.exe`, `.exe` is appended.
.PARAMETER Silently
Block an Application Silently.

BE VERY CAREFUL USING THIS SETTING!!!
.PARAMETER PopupTextStandard
Default: `$global:Winstall.Settings.Functions.BlockAppExecution.PopupTextStandard`

This is the standard text used in the message. It should include 1 string replacement formatter (`{0}`) and the `%BlockedApp%` string. Not including these formatters will not break anything, but will make the popup message less customized.

- `{0}` will be replaced by the *PopupTextReason* parameter.
- `%BlockedApp%` will be replaced by the full path current executable being blocked; i.e.: *notepad.exe*.

An example (and the current default):

> {0} As such, {1} is currently blocked.
> 
> You can monitor the progress in Software Center under the Installation Status tab.
> 
> If you have any questions or concerns, please do not hesitate to contact your IT department.

In order to customize this parameter for your supported departments, set the associated setting via registry. Here's the message our department might use:

> {0} As such, {1} is currently blocked.
> 
> You can monitor the progress in Software Center under the Installation Status tab.
> 
> If you have any questions or concerns, please do not hesitate to contact Super Cool IT.
> 
> https://scit.example.com
> SCIT@example.com
> x7334

Ref `strText`: https://msdn.microsoft.com/en-us/library/x83z1d9f(v=vs.84).aspx
.PARAMETER PopupTextReason
Default: `$global:Winstall.Settings.Functions.BlockAppExecution.PopupTextReason`

This will be the injected into formatter zero (`{0}`) of the *PopupTextStandard* parameter. It should be customized for the running process, such as:

> Your IT department is currently upgrading Firefox ESR.
.PARAMETER PopupSecondsToWait
Default: `$global:Winstall.Settings.Functions.BlockAppExecution.PopupSecondsToWait`

Numeric value indicating the maximum number of seconds you want the pop-up message box displayed. If PopupSecondsToWait is zero, the pop-up message box remains visible until closed by the user.

Ref `nSecondsToWait`: https://msdn.microsoft.com/en-us/library/x83z1d9f(v=vs.84).aspx
.PARAMETER PopupTitle
Default: `$global:Winstall.Settings.Functions.BlockAppExecution.PopupTitle`

String value that contains the text you want to appear as the title of the pop-up message box.

Ref `strTitle`: https://msdn.microsoft.com/en-us/library/x83z1d9f(v=vs.84).aspx
.PARAMETER PopupType
Default: `$global:Winstall.Settings.Functions.BlockAppExecution.PopupType`

Numeric value indicating the type of buttons and icons you want in the pop-up message box. These determine how the message box is used.

Ref `nType`: https://msdn.microsoft.com/en-us/library/x83z1d9f(v=vs.84).aspx
.PARAMETER IFEOKey
Default: `$global:Winstall.Settings.Functions.UnblockAppExecution.IFEOKey`

Registry Key for 'Image File Execution Options'.
.EXAMPLE
Block-AppExecution -ProcessNames @('winword.exe','excel.exe')
.NOTES
This is a job within a job because:
- If the popup message doesn't occur within a sub-job, the pop-up message will halt the searching for moreblocked apps until the popup goes away; after the `PopSecondsToWait` param times out.
.LINK
#>
function Global:Block-AppExecution {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullorEmpty()]
        [string[]]
        $ProcessNames
        ,
        [Parameter(Mandatory=$false)]
        [switch]
        $Silently
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string]
        $PopupTextStandard = $global:Winstall.Settings.Functions.BlockAppExecution.PopupTextStandard
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string]
        $PopupTextReason = $global:Winstall.Settings.Functions.BlockAppExecution.PopupTextReason
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string]
        $PopupSecondsToWait = $global:Winstall.Settings.Functions.BlockAppExecution.PopupSecondsToWait
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string]
        $PopupTitle = $global:Winstall.Settings.Functions.BlockAppExecution.PopupTitle
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [int32]
        $PopupType = $global:Winstall.Settings.Functions.BlockAppExecution.PopupType
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string]
        $IFEOKey = $global:Winstall.Settings.Functions.UnblockAppExecution.IFEOKey
    )
    
    Write-Information "> $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Debug "Function Invocation: $($MyInvocation | Out-String)"


    $global:Winstall.Exiting.Add('Unblock-AppExecution') | Out-Null

    $debugger_command = 'cscript.exe //E:vbscript {0}'
    $blocked_app_vbs = @'
Dim wshShell: Set wshShell = WScript.CreateObject("WScript.Shell")
WshShell.Popup "{0}", {1}, "{2}", {3}
'@ -f @(
    ($PopupTextStandard.Replace([System.Environment]::NewLine, '"& vbCrLf &"') -f @($PopupTextReason.Replace([System.Environment]::NewLine, '"& vbCrLf &"'), '{0}')),
    $PopupSecondsToWait,
    $PopupTitle,
    $PopupType
)

    foreach ($ProcessName in $ProcessNames) {
        $ProcessName = $ProcessName.ToLower()

        Write-Information "Blocking: ${ProcessName}"
        if (-not $ProcessName.EndsWith('.exe')) {
            $ProcessName += '.exe'
            Write-Information "Blocking (corrected): ${ProcessName}"
        }

        [string] $vbs_file_path = "$($global:Winstall.Temp)\BlockAppExec-${ProcessName}-$(New-Guid).vbs"
        Write-Information "VBS File: ${vbs_file_path}"
        if ($Silently) {
            ' ' | Out-File -Encoding 'ascii' $vbs_file_path
        } else {
            ($blocked_app_vbs -f $ProcessName) | Out-File -Encoding 'ascii' $vbs_file_path
        }

        [string] $ProcessKey = Join-Path $IFEOKey $ProcessName -ErrorAction 'Stop'
        try {
            # The $ProcessKey key already exists
            [string] $ProcessKey = Resolve-Path $ProcessKey -ErrorAction 'Stop'
        } catch [System.Management.Automation.ItemNotFoundException] {
            # The $ProcessKey key does not exist
            New-Item -Type Directory $ProcessKey -ErrorAction 'Stop' | Out-Null
            [string] $ProcessKey = Resolve-Path $ProcessKey -ErrorAction 'Stop'
            New-ItemProperty -Path $ProcessKey -Name 'WinstallMadeMe' -Type 'DWORD' -Value $true | Out-Null
        }

        $debugger__existing = (Get-ItemProperty $ProcessKey).Debugger
        if (($debugger__existing | Measure-Object).Count) {
            # The 'Debugger' value already exists
            New-ItemProperty -Path $ProcessKey -Name 'Debugger_WinstallRenamedMe' -Value $debugger__existing -ErrorAction 'SilentlyContinue' | Out-Null
            Remove-ItemProperty -Path $ProcessKey -Name 'Debugger' | Out-Null
        }

        New-ItemProperty -Path $ProcessKey -Name 'Debugger' -Value ($debugger_command -f $vbs_file_path) | Out-Null
        New-ItemProperty -Path $ProcessKey -Name 'WinstallMadeDebugger' -Type 'DWORD' -Value $true | Out-Null
    }
}