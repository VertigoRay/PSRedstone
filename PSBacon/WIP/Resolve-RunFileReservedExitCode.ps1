<#
.SYNOPSIS
Resolve an Exception Message to an Exit Code.
.DESCRIPTION
This function resolves an Exception Message to an Exit Code; as defined in the [*Reserved RunFile ExitCodes* table](https://git.cas.unt.edu/winstall/winstall/wikis/exit-codes#reserved-runfile-exit-codes).

If it cannot resolve the message, it will return: `[string]'line_number'`
.PARAMETER ExceptionMessage
Required.

The Exception Message; such as `$Error[0].Exception.Message`.
.OUTPUTS
[System.String]
[System.Integer]
.EXAMPLE
# Simple usage in a RunFile
Write-Progress -CurrentOperation "Checking if $($settings.ConflictingProcesses) is/are currently running ..."

try {
    Assert-ConflictingProcessRunning $settings.ConflictingProcesses
} catch {
    Write-Error (Resolve-Error $_)
    &$global:Winstall.Exit (Resolve-RunFileReservedExitCode $_.Exception.Message)
}
#>
function Global:Resolve-RunFileReservedExitCode {
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="The Exception Message")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ExceptionMessage
    )

    Write-Information "> $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Debug "Function Invocation: $($MyInvocation | Out-String)"

    if (($ExceptionMessage).StartsWith('Window TimeOut')) {
        return 9997
    } elseif (($ExceptionMessage).StartsWith('Cancel Button')) {
        return 9998
    } elseif (($ExceptionMessage).StartsWith('PrivateVar')) {
        return 9999
    } else {
        return 'line_number'
    }
}
